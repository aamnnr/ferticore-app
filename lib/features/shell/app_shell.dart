import 'package:alburdat_dashboard/features/control/control_page.dart';
import 'package:alburdat_dashboard/features/home/home_page.dart';
import 'package:alburdat_dashboard/features/recommendation/recommendation_page.dart';
import 'package:alburdat_dashboard/features/settings/connection_settings_page.dart';
import 'package:alburdat_dashboard/features/settings/settings_page.dart';
import 'package:alburdat_dashboard/features/stats/stats_page.dart';
import 'package:alburdat_dashboard/services/mqtt/device_service.dart';
import 'package:alburdat_dashboard/widgets/floating_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum AppTab { home, recommendation, control, stats, settings }

/// Kerangka utama: 5 tab dalam `IndexedStack` (state tiap tab terjaga)
/// dengan navigasi bawah mengambang.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.openConnectionSetup = false});

  /// Buka halaman koneksi segera (setelah onboarding).
  final bool openConnectionSetup;

  /// Pindah tab dari halaman mana pun di bawah shell.
  static void goTo(BuildContext context, AppTab tab) =>
      context.findAncestorStateOfType<_AppShellState>()?._select(tab.index);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _index = 0;

  static const _destinations = [
    NavDestination(icon: Icons.home_rounded, label: 'Beranda'),
    NavDestination(icon: Icons.auto_awesome_rounded, label: 'Rekomendasi'),
    NavDestination(icon: Icons.tune_rounded, label: 'Kontrol'),
    NavDestination(icon: Icons.insights_rounded, label: 'Statistik'),
    NavDestination(icon: Icons.settings_rounded, label: 'Pengaturan'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.openConnectionSetup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) openConnectionSettings(context);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<DeviceService>().reconnectNow();
    }
  }

  void _select(int i) {
    if (i == _index) return;
    FocusScope.of(context).unfocus();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: const [HomePage(), RecommendationPage(), ControlPage(), StatsPage(), SettingsPage()],
      ),
      bottomNavigationBar: FloatingNavBar(
        destinations: _destinations,
        selectedIndex: _index,
        onSelected: _select,
      ),
    );
  }
}
