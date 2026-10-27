import 'package:alburdat_dashboard/core/theme/app_theme.dart';
import 'package:alburdat_dashboard/core/utils/formatters.dart';
import 'package:alburdat_dashboard/data/models/device_status.dart';
import 'package:alburdat_dashboard/features/guide/guide_content.dart';
import 'package:alburdat_dashboard/features/guide/guide_page.dart';
import 'package:alburdat_dashboard/services/mqtt/device_service.dart';
import 'package:alburdat_dashboard/widgets/app_bars.dart';
import 'package:alburdat_dashboard/widgets/app_card.dart';
import 'package:alburdat_dashboard/widgets/feedback.dart';
import 'package:alburdat_dashboard/widgets/metric_tile.dart';
import 'package:alburdat_dashboard/widgets/sparkline.dart';
import 'package:alburdat_dashboard/widgets/status_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum _Series { volume, dose, sessions }

extension on _Series {
  String get label => switch (this) {
    _Series.volume => 'Volume',
    _Series.dose => 'Dosis',
    _Series.sessions => 'Sesi',
  };

  double of(DeviceStatus s) => switch (this) {
    _Series.volume => s.totalVolume,
    _Series.dose => s.dose,
    _Series.sessions => s.totalSessions.toDouble(),
  };
}

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  _Series _series = _Series.volume;

  Future<void> _reset(DeviceService device) async {
    final ok = await showConfirmSheet(
      context,
      title: 'Reset statistik alat?',
      message: 'Total volume, rata-rata, dan jumlah sesi di alat akan dihapus permanen. Tindakan ini tidak dapat dibatalkan.',
      confirmLabel: 'Reset',
      destructive: true,
      icon: Icons.restart_alt_rounded,
      rows: [
        SummaryRow('Perangkat', device.config.deviceId),
        SummaryRow('Total volume', Fmt.mass(device.status?.totalVolume ?? 0)),
        SummaryRow('Total sesi', '${device.status?.totalSessions ?? 0}'),
      ],
    );
    if (!ok || !mounted) return;
    final result = await device.resetStats();
    if (!mounted) return;
    showCommandResult(context, result, successMessage: 'Statistik alat telah direset');
  }

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceService>();
    final s = device.status;
    final t = Theme.of(context).textTheme;
    final values = device.history.map(_series.of).toList();

    return TabPage(
      header: const PageHeader(
        title: 'Statistik',
        actions: [HelpButton(topic: GuideTopic.stats)],
      ),
      children: [
        AppCard(
          color: AppColors.surfaceRaised,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total volume tertabur', style: t.labelMedium),
              const SizedBox(height: Gap.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    s == null ? '–' : Fmt.mass(s.totalVolume),
                    style: t.displayMedium,
                  ),
                  const SizedBox(width: Gap.md),
                  if (s != null)
                    StatusPill(
                      label: s.isMotorRunning ? 'Menabur' : 'Siaga',
                      tone: s.isMotorRunning ? Tone.success : Tone.neutral,
                    ),
                ],
              ),
              const SizedBox(height: Gap.xs),
              Text(
                s == null ? 'Belum ada data dari alat' : 'Diperbarui ${Fmt.relative(s.receivedAt)}',
                style: t.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.md),
        AppCard(
          color: AppColors.surfaceRaised,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<_Series>(
                showSelectedIcon: false,
                segments: [
                  for (final v in _Series.values) ButtonSegment(value: v, label: Text(v.label)),
                ],
                selected: {_series},
                onSelectionChanged: (sel) => setState(() => _series = sel.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.navActive,
                  selectedForegroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.border, width: 0.6),
                ),
              ),
              const SizedBox(height: Gap.lg),
              if (values.length < 2)
                const EmptyState(
                  icon: Icons.show_chart_rounded,
                  title: 'Grafik belum tersedia',
                  message: 'Grafik muncul setelah alat mengirim beberapa pembaruan status.',
                )
              else ...[
                Sparkline(values: values),
                const SizedBox(height: Gap.sm),
                Row(
                  children: [
                    Text(Fmt.time(device.history.first.receivedAt), style: t.labelSmall),
                    const Spacer(),
                    Text('${values.length} titik data', style: t.labelSmall),
                    const Spacer(),
                    Text(Fmt.time(device.history.last.receivedAt), style: t.labelSmall),
                  ],
                ),
              ],
              const SizedBox(height: Gap.sm),
              Text(
                'Riwayat grafik hanya mencakup selama aplikasi terbuka.',
                style: t.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.md),
        Row(
          children: [
            Expanded(
              child: MetricTile(
                icon: Icons.trending_up_rounded,
                label: 'Rata-rata',
                value: s == null ? '–' : Fmt.number(s.average),
                unit: 'g',
              ),
            ),
            const SizedBox(width: Gap.sm),
            Expanded(
              child: MetricTile(
                icon: Icons.repeat_rounded,
                label: 'Total sesi',
                value: s == null ? '–' : '${s.totalSessions}',
              ),
            ),
            const SizedBox(width: Gap.sm),
            Expanded(
              child: MetricTile(
                icon: Icons.scale_rounded,
                label: 'Dosis aktif',
                value: s == null ? '–' : Fmt.number(s.dose),
                unit: 'g',
              ),
            ),
          ],
        ),
        const SizedBox(height: Gap.md),
        AppCard(
          color: AppColors.surfaceRaised,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(
                title: 'Reset statistik',
                subtitle: 'Gunakan saat memulai musim tanam baru',
              ),
              const SizedBox(height: Gap.md),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.dangerSoft, width: 1.2),
                ),
                onPressed: device.canSendCommands ? () => _reset(device) : null,
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Reset statistik alat'),
              ),
              if (!device.isDeviceOnline) ...[
                const SizedBox(height: Gap.sm),
                Text('Tersedia saat alat online.', style: t.bodySmall, textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
        const SizedBox(height: Gap.md),
        Center(
          child: TextButton.icon(
            onPressed: () => openGuide(context, GuideTopic.stats),
            icon: const Icon(Icons.menu_book_outlined, size: 18),
            label: const Text('Arti setiap angka'),
          ),
        ),
      ],
    );
  }
}
