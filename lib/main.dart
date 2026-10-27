import 'package:alburdat_dashboard/app.dart';
import 'package:alburdat_dashboard/data/repositories/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  final settings = SettingsRepository();
  final onboarded = await settings.isOnboarded();

  runApp(FerticoreApp(settings: settings, onboarded: onboarded));
}
