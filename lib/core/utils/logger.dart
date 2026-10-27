import 'package:flutter/foundation.dart';

/// Logger tipis yang hanya aktif di mode debug, sehingga isi payload atau
/// detail koneksi tidak bocor ke log perangkat pada build rilis.
void appLog(String tag, String message) {
  if (kDebugMode) debugPrint('[$tag] $message');
}
