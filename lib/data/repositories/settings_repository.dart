import 'dart:convert';

import 'package:alburdat_dashboard/core/utils/logger.dart';
import 'package:alburdat_dashboard/data/models/broker_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Penyimpanan pengaturan lokal.
///
/// - Data non-rahasia (host, port, ID alat, flag onboarding) → SharedPreferences.
/// - Password broker → FlutterSecureStorage (Keystore/Keychain), tidak pernah
///   ditulis ke SharedPreferences maupun log.
class SettingsRepository {
  SettingsRepository({
    SharedPreferencesAsync? prefs,
    FlutterSecureStorage? secure,
  }) : _prefs = prefs ?? SharedPreferencesAsync(),
       _secure = secure ?? const FlutterSecureStorage();

  final SharedPreferencesAsync _prefs;
  final FlutterSecureStorage _secure;

  static const _kBroker = 'broker_config_v2';
  static const _kOnboarded = 'onboarding_done_v1';
  static const _kPassword = 'broker_password';

  Future<BrokerConfig> loadBrokerConfig() async {
    try {
      final raw = await _prefs.getString(_kBroker);
      if (raw == null) return BrokerConfig.defaults;
      final json = jsonDecode(raw);
      if (json is Map<String, Object?>) return BrokerConfig.fromJson(json);
    } catch (e) {
      appLog('settings', 'Gagal membaca konfigurasi: $e');
    }
    return BrokerConfig.defaults;
  }

  Future<void> saveBrokerConfig(BrokerConfig config, {String? password}) async {
    await _prefs.setString(_kBroker, jsonEncode(config.toJson()));
    if (password != null) {
      if (password.isEmpty) {
        await _secure.delete(key: _kPassword);
      } else {
        await _secure.write(key: _kPassword, value: password);
      }
    }
  }

  Future<String?> readPassword() async {
    try {
      return await _secure.read(key: _kPassword);
    } catch (e) {
      // Keystore bisa korup setelah restore/backup; anggap tidak ada.
      appLog('settings', 'Secure storage tidak dapat dibaca: $e');
      return null;
    }
  }

  Future<bool> hasPassword() async => (await readPassword())?.isNotEmpty ?? false;

  Future<bool> isOnboarded() async => await _prefs.getBool(_kOnboarded) ?? false;

  Future<void> setOnboarded(bool value) => _prefs.setBool(_kOnboarded, value);
}
