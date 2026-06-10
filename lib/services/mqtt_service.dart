import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/device_status.dart';

class MqttService extends ChangeNotifier {
  late MqttServerClient client;
  
  // --- KONFIGURASI KOMERSIAL ---
  static const String broker = String.fromEnvironment('MQTT_BROKER', defaultValue: 'nama-broker-emqx-kalian.emqxsl.com');
  static const String mqttUser = String.fromEnvironment('MQTT_USER', defaultValue: 'perangkat_ferticore');
  static const String mqttPass = String.fromEnvironment('MQTT_PASS', defaultValue: 'sandi_aman_123');
  
  // Port default untuk dua protokol
  static const int _tcpPort = 8883;      // MQTT over TLS (mobile/desktop)
  static const int _webSocketPort = 8084; // WSS (web)

  final String clientIdentifier = 'FERTICORE_${DateTime.now().millisecondsSinceEpoch}';

  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // --- MULTI-DEVICE STATE ---
  final Map<String, DeviceStatus> _deviceStatuses = {};
  final Map<String, DateTime> _lastStatusTimes = {};
  
  List<String> _activeDeviceIds = [];

  DeviceStatus? getDeviceStatus(String deviceId) => _deviceStatuses[deviceId];
  
  bool isEspOnline(String deviceId) {
    final lastTime = _lastStatusTimes[deviceId];
    if (lastTime == null) return false;
    return DateTime.now().difference(lastTime).inSeconds < 30;
  }

  // --- RECONNECTION LOGIC ---
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _reconnectInterval = Duration(seconds: 5);

  MqttService() {
    _initClient();
  }

  // 🔁 INILAH BAGIAN YANG DIUBAH UNTUK DUKUNGAN WEB
  void _initClient() {
    client = MqttServerClient(broker, clientIdentifier);
    
    // Penyesuaian otomatis berdasarkan platform
    if (kIsWeb) {
      // Web → gunakan WebSocket aman (WSS)
      client.port = _webSocketPort;       // 8084
      client.useWebSocket = true;
      client.secure = true;               // WSS
      // Jika broker-mu mengharuskan path tertentu, aktifkan ini:
      // client.websocketPath = '/mqtt';
    } else {
      // Mobile/Desktop → gunakan MQTT over TLS (TCP)
      client.port = _tcpPort;             // 8883
      client.useWebSocket = false;
      client.secure = true;               // TLS
    }
    
    client.setProtocolV311();

    final connMess = MqttConnectMessage()
        .authenticateAs(mqttUser, mqttPass)
        .withClientIdentifier(clientIdentifier)
        .startClean();
    client.connectionMessage = connMess;

    client.logging(on: false);
    client.keepAlivePeriod = 20;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;
    client.pongCallback = _pong;
  }

  // Memperbarui daftar alat dari database sebelum melakukan subscribe
  void updateActiveDevices(List<String> deviceIds) {
    _activeDeviceIds = deviceIds;
    if (_isConnected) {
      _subscribeToAllTopics();
    }
  }

  Future<void> connect() async {
    if (_isConnected || _isConnecting) return;
    _isConnecting = true;
    _reconnectAttempts = 0;
    notifyListeners();
    debugPrint('Connecting to secure MQTT broker...');
    
    try {
      await client.connect();
    } catch (e) {
      debugPrint('Connection Exception: $e');
      _isConnected = false;
      _isConnecting = false;
      notifyListeners();
      _scheduleReconnect();
      return;
    }
    
    _isConnecting = false;
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      debugPrint('Secure MQTT connected');
      _isConnected = true;
      _reconnectAttempts = 0;
      notifyListeners();
      _subscribeToAllTopics();
    } else {
      debugPrint('Connection failed - disconnecting');
      client.disconnect();
      _isConnected = false;
      notifyListeners();
      _scheduleReconnect();
    }
  }

  // Melakukan subscribe secara dinamis berdasarkan list device_id
  void _subscribeToAllTopics() {
    if (!_isConnected || _activeDeviceIds.isEmpty) return;
    
    for (String deviceId in _activeDeviceIds) {
      String topic = 'ferticore/$deviceId/status';
      client.subscribe(topic, MqttQos.atLeastOnce);
      debugPrint('Subscribed to $topic');
    }
  }

  void _onConnected() {
    debugPrint('Connected to broker');
    _isConnected = true;
    _reconnectAttempts = 0;
    _cancelReconnectTimer();
    notifyListeners();
  }

  void _onDisconnected() {
    debugPrint('Disconnected');
    _isConnected = false;
    _isConnecting = false;
    notifyListeners();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _cancelReconnectTimer();
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      debugPrint('Scheduling reconnect attempt $_reconnectAttempts/$_maxReconnectAttempts');
      _reconnectTimer = Timer(_reconnectInterval, () {
        if (!_isConnected && !_isConnecting) {
          connect();
        }
      });
    }
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _onSubscribed(String topic) {
    // Hanya pasang listener jika belum pernah dipasang (hindari duplikasi)
    if (!client.updates!.isBroadcast) {
       client.updates!.listen(_onMessage);
    }
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    final recMessage = messages[0].payload as MqttPublishMessage;
    final topic = messages[0].topic;
    final payload = MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);

    debugPrint('Received on $topic: $payload');

    // Filter pesan hanya yang berakhiran '/status'
    if (topic.endsWith('/status')) {
      try {
        final jsonData = jsonDecode(payload);
        
        // Ambil device_id dari payload JSON yang dikirim oleh ESP32
        final String deviceId = jsonData['device_id'] ?? '';
        
        if (deviceId.isNotEmpty) {
           final status = DeviceStatus.fromJson(jsonData);
           
           // Simpan ke state Map berdasarkan deviceId
           _deviceStatuses[deviceId] = status;
           _lastStatusTimes[deviceId] = DateTime.now();
           
           // Beritahu UI untuk me-render ulang
           notifyListeners();
        }
      } catch (e) {
        debugPrint('JSON parse error: $e');
      }
    }
  }

  void _pong() => debugPrint('Pong received');

  // --- PERINTAH KE DEVICE SPESIFIK ---
  void publishCommand(String deviceId, Map<String, dynamic> command) {
    if (!_isConnected) {
      debugPrint('Not connected');
      return;
    }
    
    // Topik tujuan spesifik alat
    final String topicCommand = 'ferticore/$deviceId/command';
    
    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(command));
    client.publishMessage(topicCommand, MqttQos.atLeastOnce, builder.payload!);
    debugPrint('Command sent to $topicCommand');
  }

  // Wajib sertakan deviceId saat memanggil fungsi dari UI
  void setDosis(String deviceId, double value) => publishCommand(deviceId, {'set_dosis': value});
  void resetStats(String deviceId) => publishCommand(deviceId, {'reset_stats': true});
  void resetWifi(String deviceId) => publishCommand(deviceId, {'reset_wifi': true});

  void disconnect() {
    _cancelReconnectTimer();
    client.disconnect();
  }
}