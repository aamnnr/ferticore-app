import 'package:alburdat_dashboard/core/config/app_config.dart';

/// Validator form yang dapat dipakai ulang. Setiap fungsi mengembalikan
/// pesan error (Bahasa Indonesia) atau `null` jika valid, sehingga bisa
/// langsung dipakai sebagai `validator:` pada `TextFormField`.
class Validators {
  Validators._();

  /// ID perangkat hanya boleh huruf, angka, `-` dan `_`. Karakter seperti
  /// `/`, `+`, dan `#` ditolak agar tidak bisa menyusupkan wildcard MQTT
  /// dan berlangganan topik perangkat lain.
  static final RegExp _deviceId = RegExp(r'^[A-Za-z0-9_-]{4,32}$');

  static final RegExp _host = RegExp(
    r'^(?=.{1,253}$)([A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)(\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*$',
  );

  static String? deviceId(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'ID perangkat wajib diisi';
    if (!_deviceId.hasMatch(v)) {
      return '4–32 karakter: huruf, angka, "-" atau "_"';
    }
    return null;
  }

  static String? host(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Alamat broker wajib diisi';
    if (!_host.hasMatch(v)) return 'Alamat broker tidak valid';
    return null;
  }

  static String? port(String? value) {
    final p = int.tryParse(value?.trim() ?? '');
    if (p == null || p < 1 || p > 65535) return 'Port 1–65535';
    return null;
  }

  static String? optionalText(String? value, {int max = 64}) {
    if ((value ?? '').length > max) return 'Maksimal $max karakter';
    return null;
  }

  /// Mengubah input angka bergaya Indonesia ("12,5") maupun internasional
  /// ("12.5") menjadi double.
  static double? parseDecimal(String? value) {
    final v = value?.trim().replaceAll(',', '.') ?? '';
    if (v.isEmpty) return null;
    final d = double.tryParse(v);
    if (d == null || d.isNaN || d.isInfinite) return null;
    return d;
  }

  static String? deviceDose(String? value) {
    final d = parseDecimal(value);
    if (d == null) return 'Masukkan angka, contoh 12,5';
    if (d < AppConfig.minDeviceDose || d > AppConfig.maxDeviceDose) {
      return 'Rentang alat ${AppConfig.minDeviceDose.toStringAsFixed(0)}–'
          '${AppConfig.maxDeviceDose.toStringAsFixed(0)} gram';
    }
    return null;
  }

  static String? landArea(String? value) {
    final d = parseDecimal(value);
    if (d == null) return 'Masukkan luas lahan';
    if (d <= 0) return 'Luas harus lebih dari 0';
    if (d > 10000000) return 'Maksimal 10.000.000 m² (1.000 ha)';
    return null;
  }

  static String? plantAge(String? value) {
    final d = parseDecimal(value);
    if (d == null) return 'Masukkan umur tanaman (HST)';
    if (d < 0) return 'HST tidak boleh negatif';
    if (d > 36500) return 'HST maksimal 36.500 hari';
    return null;
  }
}
