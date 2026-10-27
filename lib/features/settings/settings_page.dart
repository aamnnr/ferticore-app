import 'package:alburdat_dashboard/core/config/app_config.dart';
import 'package:alburdat_dashboard/core/theme/app_theme.dart';
import 'package:alburdat_dashboard/data/models/broker_config.dart';
import 'package:alburdat_dashboard/features/guide/guide_content.dart';
import 'package:alburdat_dashboard/features/guide/guide_page.dart';
import 'package:alburdat_dashboard/features/guide/onboarding_page.dart';
import 'package:alburdat_dashboard/features/settings/connection_settings_page.dart';
import 'package:alburdat_dashboard/features/settings/device_wifi_page.dart';
import 'package:alburdat_dashboard/services/mqtt/device_service.dart';
import 'package:alburdat_dashboard/widgets/app_bars.dart';
import 'package:alburdat_dashboard/widgets/app_card.dart';
import 'package:alburdat_dashboard/widgets/feedback.dart';
import 'package:alburdat_dashboard/widgets/link_status.dart';
import 'package:alburdat_dashboard/widgets/status_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _clearConnection(BuildContext context) async {
    final device = context.read<DeviceService>();
    final ok = await showConfirmSheet(
      context,
      title: 'Hapus data koneksi?',
      message: 'ID alat, pengaturan broker, dan password tersimpan akan dihapus dari ponsel ini. Alat tidak terpengaruh.',
      confirmLabel: 'Hapus',
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok || !context.mounted) return;
    await device.applyConfig(BrokerConfig.defaults, password: '');
    if (context.mounted) showAppSnack(context, 'Data koneksi dihapus', tone: Tone.success);
  }

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceService>();
    final link = LinkStatus.of(device);
    final t = Theme.of(context).textTheme;
    final cfg = device.config;
    final configured = device.state != LinkState.notConfigured;

    return TabPage(
      header: const PageHeader(title: 'Pengaturan'),
      children: [
        AppCard(
          color: AppColors.surfaceRaised,
          onTap: () => openConnectionSettings(context),
          child: Row(
            children: [
              const BrandLogo(size: 48),
              const SizedBox(width: Gap.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(configured ? cfg.deviceId : 'Belum ada alat', style: t.titleLarge),
                    const SizedBox(height: 2),
                    Text(link.detail, style: t.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              StatusPill(label: link.label, tone: link.tone),
            ],
          ),
        ),
        const SizedBox(height: Gap.lg),
        const _GroupLabel('Perangkat'),
        _Group(
          tiles: [
            _Tile(
              icon: Icons.settings_input_antenna_rounded,
              title: 'Koneksi alat',
              subtitle: configured ? '${cfg.host} · ${cfg.isSecure ? 'aman' : 'belum aman'}' : 'Atur ID alat & broker',
              trailing: configured && !cfg.isSecure ? const StatusDot(tone: Tone.warning) : null,
              onTap: () => openConnectionSettings(context),
            ),
            _Tile(
              icon: Icons.router_rounded,
              title: 'WiFi alat',
              subtitle: 'Ganti jaringan WiFi yang dipakai alat',
              onTap: () => _push(context, const DeviceWifiPage()),
            ),
          ],
        ),
        const SizedBox(height: Gap.lg),
        const _GroupLabel('Bantuan'),
        _Group(
          tiles: [
            _Tile(
              icon: Icons.menu_book_rounded,
              title: 'Panduan penggunaan',
              subtitle: 'Langkah demi langkah & pemecahan masalah',
              onTap: () => openGuide(context),
            ),
            _Tile(
              icon: Icons.shield_outlined,
              title: 'Tips keamanan',
              subtitle: 'Lindungi alat dari perintah orang lain',
              onTap: () => openGuide(context, GuideTopic.security),
            ),
            _Tile(
              icon: Icons.slideshow_rounded,
              title: 'Tampilkan pengenalan',
              subtitle: 'Ulangi layar sambutan',
              onTap: () => _push(
                context,
                Builder(
                  builder: (ctx) => OnboardingPage(
                    onDone: (setup) {
                      Navigator.of(ctx).pop();
                      if (setup) openConnectionSettings(context);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Gap.lg),
        const _GroupLabel('Data & privasi'),
        _Group(
          tiles: [
            _Tile(
              icon: Icons.delete_outline_rounded,
              title: 'Hapus data koneksi',
              subtitle: 'Hapus ID alat, broker & password dari ponsel ini',
              danger: true,
              onTap: configured ? () => _clearConnection(context) : null,
            ),
          ],
        ),
        const SizedBox(height: Gap.xl),
        Center(
          child: Column(
            children: [
              Text('${AppConfig.appName} v${AppConfig.appVersion}', style: t.labelMedium),
              const SizedBox(height: 2),
              Text('Protokol MQTT v2 · topik ${AppConfig.topicPrefix}/<ID>/…', style: t.labelSmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: Gap.xs, bottom: Gap.sm),
      child: Text(text.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 0.8)),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.tiles});
  final List<_Tile> tiles;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.surfaceRaised,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const Divider(indent: 64),
            tiles[i],
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final color = danger ? AppColors.danger : AppColors.ink;
    return ListTile(
      enabled: onTap != null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(Gap.sm),
        decoration: BoxDecoration(
          color: danger ? AppColors.dangerSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(title, style: t.titleMedium?.copyWith(color: color)),
      subtitle: Text(subtitle, style: t.bodySmall),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?trailing,
          const SizedBox(width: Gap.xs),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
        ],
      ),
    );
  }
}
