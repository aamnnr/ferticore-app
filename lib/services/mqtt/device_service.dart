import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:alburdat_dashboard/core/config/app_config.dart';
import 'package:alburdat_dashboard/core/utils/logger.dart';
import 'package:alburdat_dashboard/data/models/broker_config.dart';
import 'package:alburdat_dashboard/data/models/device_command.dart';
import 'package:alburdat_dashboard/data/models/device_status.dart';
import 'package:alburdat_dashboard/data/repositories/settings_repository.dart';
import 'package:alburdat_dashboard/services/mqtt/mqtt_client_factory.dart';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';

enum LinkState { notConfigured, disconnected, connecting, connected }

/// Satu-satunya pintu komunikasi dengan alat: koneksi broker, status alat,
/// riwayat, dan pengiriman perintah ber-acknowledgement.
class DeviceService extends ChangeNotifier {
  DeviceService(this._settings, {Duration staleCheckEvery = const Duration(seconds: 5)}) {
    _staleTimer = Timer.periodic(staleCheckEvery, (_) => _checkStale());
  }

  final SettingsRepository _settings;
  final Random _rng = Random.secure();

  MqttClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _updatesSub;
  Timer? _reconnectTimer;
  late final Timer _staleTimer;
  int _reconnectAttempt = 0;

  /// Naik setiap kali klien baru dibuat; callback dari klien lama diabaikan.
  int _generation = 0;
  bool _disposed = false;

  BrokerConfig _config = BrokerConfig.defaults;
  BrokerConfig get config => _config;

  LinkState _state = LinkState.notConfigured;
  LinkState get state => _state;
  bool get isConnected => _state == LinkState.connected;
  bool get isConnecting => _state == LinkState.connecting;

  String? _lastError;
  String? get lastError => _lastError;

  DateTime? _nextRetryAt;
  DateTime? get nextRetryAt => _nextRetryAt;

  DeviceStatus? _status;
  DeviceStatus? get status => _status;

  final List<DeviceStatus> _history = [];
  List<DeviceStatus> get history => List.unmodifiable(_history);

  bool _deviceOnline = false;
  bool get isDeviceOnline => _deviceOnline;

  final _statusController = StreamController<DeviceStatus>.broadcast();
  Stream<DeviceStatus> get statusStream => _statusController.stream;

  bool _commandInFlight = false;
  bool get isCommandInFlight => _commandInFlight;
  DateTime? _lastCommandAt;

  /// Dosis terakhir yang dikonfirmasi alat dikirim dari aplikasi ini.
  double? _lastConfirmedDose;
  double? get lastConfirmedDose => _lastConfirmedDose;

  bool get canSendCommands => isConnected && isDeviceOnline && !_commandInFlight;

  // ---------------------------------------------------------------------------
  // Siklus hidup koneksi
  // ---------------------------------------------------------------------------

  /// Memuat konfigurasi tersimpan lalu menghubungkan bila lengkap.
  Future<void> init() async {
    _config = await _settings.loadBrokerConfig();
    if (_config.isComplete) {
      await connect();
    } else {
      _setState(LinkState.notConfigured);
    }
  }

  /// Menyimpan konfigurasi baru dan menyambung ulang.
  /// [password] `null` = tidak diubah, `''` = dihapus.
  Future<void> applyConfig(BrokerConfig config, {String? password}) async {
    await _settings.saveBrokerConfig(config, password: password);
    _config = config;
    _status = null;
    _history.clear();
    _deviceOnline = false;
    await disconnect();
    if (config.isComplete) {
      await connect();
    } else {
      _setState(LinkState.notConfigured);
    }
  }

  Future<void> connect() async {
    if (_disposed || isConnecting || isConnected) return;
    if (!_config.isComplete) {
      _setState(LinkState.notConfigured);
      return;
    }
    _cancelReconnect();
    final gen = ++_generation;
    _lastError = null;
    _setState(LinkState.connecting);

    final clientId = 'ferticore-app-${_randomHex(6)}';
    final client = createMqttClient(_config, clientId)
      ..logging(on: false)
      ..keepAlivePeriod = 20
      ..setProtocolV311()
      ..autoReconnect = false
      ..connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean();
    client.onDisconnected = () => _handleDisconnected(gen);
    _client = client;

    final password = await _settings.readPassword();
    if (gen != _generation) {
      _abandon(client);
      return;
    }
    final username = _config.username.isEmpty ? null : _config.username;

    try {
      await client
          .connect(username, username == null ? null : password)
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      appLog('mqtt', 'Gagal terhubung: $e');
    if (gen != _generation) {
      _abandon(client);
      return;
    }
      _failConnection(_describeError(e, client.connectionStatus));
      return;
    }

    if (gen != _generation) {
      _abandon(client);
      return;
    }
    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      _failConnection(_describeError(null, client.connectionStatus));
      return;
    }

    _reconnectAttempt = 0;
    _nextRetryAt = null;
    _updatesSub = client.updates?.listen(_onMessages);
    client.subscribe(_config.statusTopic, MqttQos.atLeastOnce);
    appLog('mqtt', 'Terhubung, subscribe ${_config.statusTopic}');
    _setState(LinkState.connected);
  }

  /// Menutup klien dari percobaan koneksi yang sudah usang (config diganti
  /// atau service di-dispose di tengah `await`) agar socket tidak bocor.
  void _abandon(MqttClient client) {
    client.onDisconnected = null;
    try {
      client.disconnect();
    } catch (_) {}
  }

  Future<void> disconnect() async {
    _generation++;
    _cancelReconnect();
    await _teardownClient();
    if (_state != LinkState.notConfigured) _setState(LinkState.disconnected);
  }

  /// Sambung ulang segera (tombol manual, tarik-segarkan, aplikasi aktif
  /// kembali) dan reset jeda backoff.
  void reconnectNow() {
    if (!isConnected && !isConnecting && _config.isComplete) {
      _reconnectAttempt = 0;
      connect();
    }
  }

  void _failConnection(String message) {
    _lastError = message;
    _teardownClient();
    _setState(LinkState.disconnected);
    _scheduleReconnect();
  }

  void _handleDisconnected(int gen) {
    if (gen != _generation || _disposed || _state != LinkState.connected) return;
    appLog('mqtt', 'Terputus dari broker');
    _updatesSub?.cancel();
    _updatesSub = null;
    _client = null;
    _deviceOnline = false;
    _setState(LinkState.disconnected);
    _scheduleReconnect();
  }

  /// Backoff eksponensial dengan jitter, tanpa batas jumlah percobaan
  /// (dulu berhenti total setelah 10x).
  void _scheduleReconnect() {
    if (_disposed || !_config.isComplete) return;
    _cancelReconnect();
    final base = AppConfig.reconnectBase.inMilliseconds;
    final capped = min(
      AppConfig.reconnectMax.inMilliseconds,
      base * pow(2, min(_reconnectAttempt, 10)).toInt(),
    );
    final delay = Duration(milliseconds: capped ~/ 2 + _rng.nextInt(capped ~/ 2 + 1));
    _reconnectAttempt++;
    _nextRetryAt = DateTime.now().add(delay);
    _reconnectTimer = Timer(delay, () {
      _nextRetryAt = null;
      connect();
    });
    notifyListeners();
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  Future<void> _teardownClient() async {
    await _updatesSub?.cancel();
    _updatesSub = null;
    final client = _client;
    _client = null;
    if (client != null) {
      client.onDisconnected = null;
      try {
        client.disconnect();
      } catch (_) {}
    }
    _deviceOnline = false;
  }

  String _describeError(Object? error, MqttClientConnectionStatus? status) {
    switch (status?.returnCode) {
      case MqttConnectReturnCode.badUsernameOrPassword:
      case MqttConnectReturnCode.notAuthorized:
        return 'Username/password broker ditolak';
      case MqttConnectReturnCode.identifierRejected:
        return 'Client ID ditolak broker';
      case MqttConnectReturnCode.brokerUnavailable:
        return 'Broker sedang tidak tersedia';
      default:
        break;
    }
    if (error is TimeoutException) return 'Waktu koneksi habis';
    final text = error?.toString() ?? '';
    if (text.contains('Handshake') || text.contains('CERTIFICATE')) {
      return 'Sertifikat TLS broker tidak valid';
    }
    return 'Tidak dapat terhubung ke broker';
  }

  // ---------------------------------------------------------------------------
  // Pesan masuk
  // ---------------------------------------------------------------------------

  void _onMessages(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final m in messages) {
      if (m.topic != _config.statusTopic) continue;
      final publish = m.payload;
      if (publish is! MqttPublishMessage) continue;
      final bytes = publish.payload.message;
      if (bytes.length > AppConfig.maxPayloadBytes) {
        appLog('mqtt', 'Payload terlalu besar (${bytes.length} B), diabaikan');
        continue;
      }
      try {
        final text = utf8.decode(bytes, allowMalformed: true);
        _ingestStatus(DeviceStatus.fromJson(jsonDecode(text)));
      } catch (e) {
        appLog('mqtt', 'Status tidak valid: $e');
      }
    }
  }

  void _ingestStatus(DeviceStatus status) {
    _status = status;
    _history.add(status);
    if (_history.length > AppConfig.historyCapacity) _history.removeAt(0);
    _deviceOnline = true;
    _statusController.add(status);
    notifyListeners();
  }

  void _checkStale() {
    final last = _status?.receivedAt;
    final online = isConnected &&
        last != null &&
        DateTime.now().difference(last) < AppConfig.deviceStaleAfter;
    if (online != _deviceOnline) {
      _deviceOnline = online;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Perintah
  // ---------------------------------------------------------------------------

  Future<CommandResult> setDose(double grams) {
    if (grams.isNaN ||
        grams < AppConfig.minDeviceDose ||
        grams > AppConfig.maxDeviceDose) {
      return Future.value(const CommandResult(
        CommandOutcome.rejected,
        'Dosis di luar rentang alat',
      ));
    }
    return send(DeviceCommand.setDose(grams));
  }

  Future<CommandResult> resetStats() => send(DeviceCommand.resetStats());
  Future<CommandResult> resetWifi() => send(DeviceCommand.resetWifi());

  Future<CommandResult> send(DeviceCommand command) async {
    final client = _client;
    if (!isConnected || client == null) {
      return const CommandResult(CommandOutcome.rejected, 'Belum terhubung ke broker');
    }
    if (!isDeviceOnline) {
      return const CommandResult(CommandOutcome.rejected, 'Alat sedang offline');
    }
    if (_commandInFlight) {
      return const CommandResult(CommandOutcome.rejected, 'Masih menunggu perintah sebelumnya');
    }
    final last = _lastCommandAt;
    if (last != null && DateTime.now().difference(last) < const Duration(seconds: 1)) {
      return const CommandResult(CommandOutcome.rejected, 'Terlalu cepat, coba lagi');
    }

    _commandInFlight = true;
    _lastCommandAt = DateTime.now();
    notifyListeners();

    final ackCompleter = Completer<void>();
    StreamSubscription<DeviceStatus>? ackSub;
    try {
      // Daftarkan penunggu ack SEBELUM publish agar balasan cepat tidak terlewat.
      if (command.expectsAck) {
        ackSub = statusStream.listen((s) {
          if (!ackCompleter.isCompleted && command.isConfirmedBy(s)) ackCompleter.complete();
        });
      }

      final builder = MqttClientPayloadBuilder()
        ..addUTF8String(jsonEncode(command.toJson()));
      client.publishMessage(_config.commandTopic, MqttQos.atLeastOnce, builder.payload!);

      if (ackSub == null) {
        return const CommandResult(CommandOutcome.sent, 'Perintah terkirim');
      }
      try {
        await ackCompleter.future.timeout(AppConfig.commandAckTimeout);
      } on TimeoutException {
        return const CommandResult(
          CommandOutcome.timeout,
          'Terkirim, tetapi alat belum mengonfirmasi',
        );
      }
      if (command.type == CommandType.setDose) _lastConfirmedDose = command.value;
      return const CommandResult(CommandOutcome.confirmed, 'Dikonfirmasi oleh alat');
    } catch (e) {
      appLog('mqtt', 'Publish gagal: $e');
      return const CommandResult(CommandOutcome.rejected, 'Gagal mengirim perintah');
    } finally {
      await ackSub?.cancel();
      _commandInFlight = false;
      if (!_disposed) notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------

  void _setState(LinkState s) {
    if (_disposed) return;
    _state = s;
    _checkStale();
    notifyListeners();
  }

  String _randomHex(int bytes) =>
      List.generate(bytes, (_) => _rng.nextInt(256).toRadixString(16).padLeft(2, '0'))
          .join();

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _staleTimer.cancel();
    _cancelReconnect();
    _teardownClient();
    _statusController.close();
    super.dispose();
  }
}
