import 'dart:io';

import 'package:alburdat_dashboard/data/models/broker_config.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

MqttClient createMqttClient(BrokerConfig config, String clientId) {
  final client = MqttServerClient.withPort(config.host, clientId, config.tcpPort);
  if (config.useTls) {
    client.secure = true;
    // Gunakan CA sistem; sertifikat tidak valid DITOLAK (tidak ada
    // onBadCertificate yang menerima semua).
    client.securityContext = SecurityContext.defaultContext;
  }
  return client;
}
