/// Konstanta global aplikasi. Semua "angka ajaib" dikumpulkan di sini agar
/// mudah diubah tanpa menyentuh logika maupun UI.
class AppConfig {
  AppConfig._();

  static const String appName = 'FERTICORE AI';
  static const String appVersion = '2.0.0';

  /// Batas dosis yang dapat dieksekusi alat (gram per titik/tanaman).
  /// Sesuai spesifikasi firmware ESP32.
  static const double minDeviceDose = 5.0;
  static const double maxDeviceDose = 50.0;

  /// Status dianggap kedaluwarsa (alat offline) bila tidak ada pesan baru
  /// selama durasi ini.
  static const Duration deviceStaleAfter = Duration(seconds: 30);

  /// Batas waktu menunggu konfirmasi (acknowledgement) dari alat.
  static const Duration commandAckTimeout = Duration(seconds: 8);

  /// Backoff reconnect MQTT (eksponensial, dibatasi).
  static const Duration reconnectBase = Duration(seconds: 2);
  static const Duration reconnectMax = Duration(seconds: 60);

  /// Payload MQTT lebih besar dari ini diabaikan (proteksi memori/spam).
  static const int maxPayloadBytes = 2048;

  /// Jumlah titik riwayat status yang disimpan di memori untuk grafik.
  static const int historyCapacity = 120;

  /// Prefix topik MQTT. Topik lengkap: `<prefix>/<deviceId>/<kanal>`.
  static const String topicPrefix = 'ferticore';
}
