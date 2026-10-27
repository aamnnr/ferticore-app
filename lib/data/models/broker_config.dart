import 'package:alburdat_dashboard/core/config/app_config.dart';
import 'package:alburdat_dashboard/core/utils/validators.dart';

/// Konfigurasi koneksi broker MQTT + identitas alat.
///
/// Password TIDAK disimpan di sini; ia disimpan terpisah di secure storage
/// dan hanya dibawa saat koneksi dibuat (lihat [SettingsRepository]).
class BrokerConfig {
  final String deviceId;
  final String host;

  /// Port TCP (Android/iOS/desktop). 8883 = MQTT over TLS.
  final int tcpPort;

  /// Port WebSocket (khusus web). 8084 = WSS.
  final int wsPort;
  final String wsPath;
  final bool useTls;
  final String username;

  const BrokerConfig({
    required this.deviceId,
    required this.host,
    required this.tcpPort,
    required this.wsPort,
    required this.wsPath,
    required this.useTls,
    required this.username,
  });

  static const BrokerConfig defaults = BrokerConfig(
    deviceId: '',
    host: 'broker.emqx.io',
    tcpPort: 8883,
    wsPort: 8084,
    wsPath: '/mqtt',
    useTls: true,
    username: '',
  );

  bool get isComplete =>
      Validators.deviceId(deviceId) == null && Validators.host(host) == null;

  /// Koneksi dianggap aman bila terenkripsi DAN terautentikasi.
  bool get isSecure => useTls && username.isNotEmpty;

  String get statusTopic => '${AppConfig.topicPrefix}/$deviceId/status';
  String get commandTopic => '${AppConfig.topicPrefix}/$deviceId/command';

  BrokerConfig copyWith({
    String? deviceId,
    String? host,
    int? tcpPort,
    int? wsPort,
    String? wsPath,
    bool? useTls,
    String? username,
  }) {
    return BrokerConfig(
      deviceId: deviceId ?? this.deviceId,
      host: host ?? this.host,
      tcpPort: tcpPort ?? this.tcpPort,
      wsPort: wsPort ?? this.wsPort,
      wsPath: wsPath ?? this.wsPath,
      useTls: useTls ?? this.useTls,
      username: username ?? this.username,
    );
  }

  Map<String, Object> toJson() => {
    'deviceId': deviceId,
    'host': host,
    'tcpPort': tcpPort,
    'wsPort': wsPort,
    'wsPath': wsPath,
    'useTls': useTls,
    'username': username,
  };

  factory BrokerConfig.fromJson(Map<String, Object?> json) {
    final d = defaults;
    return BrokerConfig(
      deviceId: json['deviceId'] as String? ?? d.deviceId,
      host: json['host'] as String? ?? d.host,
      tcpPort: json['tcpPort'] as int? ?? d.tcpPort,
      wsPort: json['wsPort'] as int? ?? d.wsPort,
      wsPath: json['wsPath'] as String? ?? d.wsPath,
      useTls: json['useTls'] as bool? ?? d.useTls,
      username: json['username'] as String? ?? d.username,
    );
  }
}
