import 'package:alburdat_dashboard/data/models/broker_config.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

MqttClient createMqttClient(BrokerConfig config, String clientId) {
  final scheme = config.useTls ? 'wss' : 'ws';
  final path = config.wsPath.startsWith('/') ? config.wsPath : '/${config.wsPath}';
  return MqttBrowserClient.withPort(
    '$scheme://${config.host}$path',
    clientId,
    config.wsPort,
  );
}
