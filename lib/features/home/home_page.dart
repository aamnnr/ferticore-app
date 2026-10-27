import 'dart:async';

import 'package:alburdat_dashboard/core/config/app_config.dart';
import 'package:alburdat_dashboard/core/theme/app_theme.dart';
import 'package:alburdat_dashboard/core/utils/formatters.dart';
import 'package:alburdat_dashboard/features/guide/guide_content.dart';
import 'package:alburdat_dashboard/features/guide/guide_page.dart';
import 'package:alburdat_dashboard/features/recommendation/recommendation_controller.dart';
import 'package:alburdat_dashboard/features/settings/connection_settings_page.dart';
import 'package:alburdat_dashboard/features/shell/app_shell.dart';
import 'package:alburdat_dashboard/services/mqtt/device_service.dart';
import 'package:alburdat_dashboard/widgets/app_bars.dart';
import 'package:alburdat_dashboard/widgets/app_card.dart';
import 'package:alburdat_dashboard/widgets/link_status.dart';
import 'package:alburdat_dashboard/widgets/metric_tile.dart';
import 'package:alburdat_dashboard/widgets/status_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceService>();
    final link = LinkStatus.of(device);

    return TabPage(
      onRefresh: () async {
        device.reconnectNow();
        await Future<void>.delayed(const Duration(milliseconds: 600));
      },
      header: Row(
        children: [
          const BrandLogo(),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Text(AppConfig.appName, style: Theme.of(context).textTheme.titleLarge),
          ),
          SquareIconButton(
            icon: link.icon,
            tooltip: '${link.label} — ${link.detail}',
            badgeColor: link.tone == Tone.success ? null : link.tone.foreground,
            onPressed: () => openConnectionSettings(context),
          ),
          const SizedBox(width: Gap.sm),
          const HelpButton(topic: GuideTopic.home),
        ],
      ),
      children: [
        if (device.state == LinkState.notConfigured)
          const _SetupCard()
        else
          _HeroCard(device: device, link: link),
        const SizedBox(height: Gap.md),
        _MetricGrid(device: device),
        const SizedBox(height: Gap.md),
        _DeviceCard(device: device, link: link),
        const SizedBox(height: Gap.md),
        _WorkflowCard(device: device),
      ],
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.surfaceRaised,
      child: EmptyState(
        icon: Icons.settings_input_antenna_rounded,
        title: 'Hubungkan alat Anda',
        message: 'Masukkan ID alat dan broker MQTT agar aplikasi dapat membaca status dan mengirim dosis.',
        action: FilledButton.icon(
          onPressed: () => openConnectionSettings(context),
          icon: const Icon(Icons.link_rounded),
          label: const Text('Atur koneksi'),
        ),
      ),
    );
  }
}

/// Kartu utama bergaya kartu cuaca pada referensi.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.device, required this.link});

  final DeviceService device;
  final LinkStatus link;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final status = device.status;
    final running = status?.isMotorRunning ?? false;

    return AppCard(
      color: AppColors.surfaceRaised,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, Gap.md),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18, color: AppColors.inkMuted),
                    const SizedBox(width: Gap.xs),
                    Expanded(
                      child: Text('Alat ${device.config.deviceId}', style: t.bodyMedium, overflow: TextOverflow.ellipsis),
                    ),
                    const _Clock(),
                  ],
                ),
                const SizedBox(height: Gap.xl),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            running ? Icons.motion_photos_on_rounded : Icons.motion_photos_paused_rounded,
                            color: running ? AppColors.primary : AppColors.inkMuted,
                            size: 28,
                          ),
                          const SizedBox(height: Gap.sm),
                          Text(running ? 'Motor berjalan' : 'Motor diam', style: t.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            'Min ${Fmt.number(AppConfig.minDeviceDose, decimals: 0)} g · '
                            'Maks ${Fmt.number(AppConfig.maxDeviceDose, decimals: 0)} g',
                            style: t.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Dosis aktif', style: t.labelMedium),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status == null ? '–' : Fmt.number(status.dose),
                              style: t.displayLarge,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 2),
                              child: Text('g', style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w300)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          InkWell(
            onTap: () => AppShell.goTo(context, AppTab.control),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: 14),
              child: Row(
                children: [
                  StatusDot(tone: link.tone),
                  const SizedBox(width: Gap.sm),
                  Expanded(child: Text(link.label, style: t.titleSmall)),
                  Text('Atur dosis', style: t.labelMedium),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Jam kecil yang diperbarui tiap 30 detik.
class _Clock extends StatefulWidget {
  const _Clock();

  @override
  State<_Clock> createState() => _ClockState();
}

class _ClockState extends State<_Clock> {
  late final Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(Fmt.longDate(_now), style: t.bodySmall?.copyWith(color: AppColors.ink)),
        Text(Fmt.time(_now), style: t.bodySmall),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.device});

  final DeviceService device;

  @override
  Widget build(BuildContext context) {
    final s = device.status;
    final online = device.isDeviceOnline;
    void toStats() => AppShell.goTo(context, AppTab.stats);
    void toControl() => AppShell.goTo(context, AppTab.control);

    final tiles = <Widget>[
      MetricTile(
        icon: Icons.sensors_rounded,
        label: 'Status alat',
        value: online ? 'Online' : 'Offline',
        highlighted: true,
        badge: online ? const StatusPill(label: 'Baik', inverted: true) : null,
        onTap: () => openConnectionSettings(context),
      ),
      MetricTile(
        icon: Icons.scale_rounded,
        label: 'Dosis aktif',
        value: s == null ? '–' : Fmt.number(s.dose),
        unit: 'g',
        onTap: toControl,
      ),
      MetricTile(
        icon: Icons.inventory_2_outlined,
        label: 'Total volume',
        value: s == null ? '–' : Fmt.number(s.totalVolume >= 1000 ? s.totalVolume / 1000 : s.totalVolume),
        unit: s != null && s.totalVolume >= 1000 ? 'kg' : 'g',
        onTap: toStats,
      ),
      MetricTile(
        icon: Icons.trending_up_rounded,
        label: 'Rata-rata',
        value: s == null ? '–' : Fmt.number(s.average),
        unit: 'g',
        onTap: toStats,
      ),
      MetricTile(
        icon: Icons.repeat_rounded,
        label: 'Total sesi',
        value: s == null ? '–' : '${s.totalSessions}',
        onTap: toStats,
      ),
      MetricTile(
        icon: Icons.settings_suggest_outlined,
        label: 'Motor',
        value: s == null ? '–' : (s.isMotorRunning ? 'Jalan' : 'Diam'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        const gap = Gap.sm;
        final cols = c.maxWidth < 300 ? 2 : 3;
        final w = ((c.maxWidth - gap * (cols - 1)) / cols).floorToDouble();
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final tile in tiles) SizedBox(width: w, child: tile)],
        );
      },
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device, required this.link});

  final DeviceService device;
  final LinkStatus link;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cfg = device.config;
    final configured = device.state != LinkState.notConfigured;

    return AppCard(
      color: AppColors.surfaceRaised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Perangkat', onMore: () => openConnectionSettings(context)),
          const SizedBox(height: Gap.md),
          Row(
            children: [
              Expanded(child: _Counter(label: 'Broker', value: configured ? cfg.host : '–')),
              Expanded(
                child: _Counter(
                  label: 'Keamanan',
                  value: cfg.isSecure ? 'TLS + login' : (cfg.useTls ? 'TLS saja' : 'Tidak aman'),
                  tone: cfg.isSecure ? Tone.success : Tone.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          Container(
            padding: const EdgeInsets.all(Gap.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusDot(tone: link.tone),
                    const SizedBox(width: Gap.sm),
                    Expanded(
                      child: Text(
                        configured ? '${cfg.deviceId}: Alat tabur pupuk' : 'Belum ada alat',
                        style: t.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: Gap.lg),
                  child: Text(!configured
                        ? 'ID belum diatur'
                        : '#${cfg.deviceId}${link.tone == Tone.success ? ' · ${link.detail}' : ''}', style: t.bodySmall),
                ),
                if (link.tone != Tone.success) ...[
                  const SizedBox(height: Gap.sm),
                  InfoBanner(message: link.detail, tone: link.tone),
                ],
                if (configured && !cfg.isSecure) ...[
                  const SizedBox(height: Gap.sm),
                  InfoBanner(
                    tone: Tone.warning,
                    icon: Icons.shield_outlined,
                    message: 'Koneksi belum aman. Aktifkan TLS dan login broker.',
                    action: TextButton(
                      onPressed: () => openGuide(context, GuideTopic.security),
                      child: const Text('Pelajari'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.label, required this.value, this.tone});

  final String label;
  final String value;
  final Tone? tone;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: t.labelMedium),
        const SizedBox(height: 2),
        Text(
          value,
          style: t.titleMedium?.copyWith(color: tone?.foreground),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Kartu "Langkah pemupukan" (setara kartu Task pada referensi).
/// Status tiap langkah diturunkan dari kondisi nyata, bukan centang manual.
class _WorkflowCard extends StatelessWidget {
  const _WorkflowCard({required this.device});

  final DeviceService device;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final reco = context.watch<RecommendationController>();
    final steps = [
      (
        'Hubungkan alat',
        'Alat online dan siap menerima perintah',
        device.isDeviceOnline,
        () => openConnectionSettings(context),
      ),
      (
        'Hitung rekomendasi',
        reco.result == null
            ? 'Tentukan dosis dari komoditas & umur tanaman'
            : '${reco.result!.input.commodity.name}: ${Fmt.number(reco.result!.dosePerPlant, decimals: 2)} g/tanaman',
        reco.result != null,
        () => AppShell.goTo(context, AppTab.recommendation),
      ),
      (
        'Terapkan dosis',
        device.lastConfirmedDose == null
            ? 'Kirim dosis ke alat dan tunggu konfirmasi'
            : 'Dosis ${Fmt.number(device.lastConfirmedDose!)} g dikonfirmasi alat',
        device.lastConfirmedDose != null,
        () => AppShell.goTo(context, AppTab.control),
      ),
      (
        'Mulai menabur',
        'Tekan tombol mulai pada alat; motor akan berputar',
        device.history.any((s) => s.isMotorRunning),
        () => openGuide(context, GuideTopic.quickStart),
      ),
    ];
    final done = steps.where((s) => s.$3).length;

    return AppCard(
      color: AppColors.surfaceRaised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Langkah pemupukan', onMore: () => openGuide(context, GuideTopic.quickStart)),
          const SizedBox(height: Gap.md),
          ThinProgress(value: done / steps.length),
          const SizedBox(height: Gap.xs),
          Row(
            children: [
              Text('${(done / steps.length * 100).round()}%', style: t.labelSmall),
              const Spacer(),
              Text('$done/${steps.length} selesai', style: t.labelSmall),
            ],
          ),
          const SizedBox(height: Gap.sm),
          for (final s in steps)
            InkWell(
              borderRadius: BorderRadius.circular(Radii.sm),
              onTap: s.$4,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Gap.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.$1, style: t.titleSmall),
                          const SizedBox(height: 2),
                          Text(s.$2, style: t.bodySmall),
                        ],
                      ),
                    ),
                    const SizedBox(width: Gap.md),
                    Icon(
                      s.$3 ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: s.$3 ? AppColors.primary : AppColors.inkFaint,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
