/// Membuat `MqttClient` sesuai platform: TCP/TLS untuk mobile & desktop,
/// WebSocket (WSS) untuk web — `MqttServerClient` tidak bisa jalan di web.
library;

export 'mqtt_client_factory_io.dart'
    if (dart.library.js_interop) 'mqtt_client_factory_web.dart';
