import 'package:alburdat_dashboard/core/config/app_config.dart';
import 'package:alburdat_dashboard/core/theme/app_theme.dart';
import 'package:alburdat_dashboard/data/repositories/settings_repository.dart';
import 'package:alburdat_dashboard/features/guide/onboarding_page.dart';
import 'package:alburdat_dashboard/features/recommendation/recommendation_controller.dart';
import 'package:alburdat_dashboard/features/shell/app_shell.dart';
import 'package:alburdat_dashboard/services/mqtt/device_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FerticoreApp extends StatelessWidget {
  const FerticoreApp({super.key, required this.settings, required this.onboarded});

  final SettingsRepository settings;
  final bool onboarded;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SettingsRepository>.value(value: settings),
        ChangeNotifierProvider(lazy: false, create: (_) => DeviceService(settings)..init()),
        ChangeNotifierProvider(create: (_) => RecommendationController()),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: _RootGate(onboarded: onboarded),
      ),
    );
  }
}

/// Menampilkan onboarding sekali, lalu masuk ke aplikasi utama.
class _RootGate extends StatefulWidget {
  const _RootGate({required this.onboarded});

  final bool onboarded;

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  late bool _onboarded = widget.onboarded;
  bool _openSetup = false;

  Future<void> _finish(bool setupConnection) async {
    await context.read<SettingsRepository>().setOnboarded(true);
    if (!mounted) return;
    setState(() {
      _onboarded = true;
      _openSetup = setupConnection;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _onboarded
          ? AppShell(key: const ValueKey('shell'), openConnectionSetup: _openSetup)
          : OnboardingPage(key: const ValueKey('onboarding'), onDone: _finish),
    );
  }
}
