import 'package:intl/intl.dart';

/// Format angka & waktu yang konsisten di seluruh aplikasi (locale id_ID).
class Fmt {
  Fmt._();

  static const String _locale = 'id_ID';

  static String number(num value, {int decimals = 1}) {
    final f = NumberFormat.decimalPatternDigits(
      locale: _locale,
      decimalDigits: decimals,
    );
    return f.format(value);
  }

  /// Gram → tampil sebagai gram atau kilogram bila ≥ 1000 g.
  static String mass(double grams, {int decimals = 1}) {
    if (grams.abs() >= 1000) return '${number(grams / 1000, decimals: 2)} kg';
    return '${number(grams, decimals: decimals)} g';
  }

  static String time(DateTime t) => DateFormat.Hm(_locale).format(t);

  static String longDate(DateTime t) =>
      DateFormat('EEE, d MMMM yyyy', _locale).format(t);

  static String relative(DateTime? t, {DateTime? now}) {
    if (t == null) return 'belum ada data';
    final diff = (now ?? DateTime.now()).difference(t);
    if (diff.inSeconds < 10) return 'baru saja';
    if (diff.inMinutes < 1) return '${diff.inSeconds} detik lalu';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }
}
