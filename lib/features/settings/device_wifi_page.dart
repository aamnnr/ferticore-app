import 'package:alburdat_dashboard/core/theme/app_theme.dart';
import 'package:alburdat_dashboard/features/guide/guide_content.dart';
import 'package:alburdat_dashboard/features/guide/guide_page.dart';
import 'package:alburdat_dashboard/services/mqtt/device_service.dart';
import 'package:alburdat_dashboard/widgets/app_card.dart';
import 'package:alburdat_dashboard/widgets/feedback.dart';
import 'package:alburdat_dashboard/widgets/link_status.dart';
import 'package:alburdat_dashboard/widgets/status_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Reset WiFi alat. Langkah diambil dari konten panduan supaya tidak ada
/// dua versi instruksi yang bisa berbeda.
class DeviceWifiPage extends StatelessWidget {
  const DeviceWifiPage({super.key});

  Future<void> _reset(BuildContext context, DeviceService device) async {
    final ok = await showConfirmSheet(
      context,
      title: 'Reset WiFi alat?',
      message: 'Alat akan menghapus WiFi tersimpan, restart, dan offline sampai dikonfigurasi ulang lewat jaringan "FERTICORE_CONFIG".',
      confirmLabel: 'Reset WiFi',
      destructive: true,
      icon: Icons.router_rounded,
      rows: [SummaryRow('Perangkat', device.config.deviceId)],
    );
    if (!ok || !context.mounted) return;
    final result = await device.resetWifi();
    if (!context.mounted) return;
    showCommandResult(context, result, successMessage: 'Perintah terkirim. Ikuti langkah konfigurasi di alat.');
  }

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceService>();
    final link = LinkStatus.of(device);
    final t = Theme.of(context).textTheme;
    final section = guideSections.firstWhere((s) => s.topic == GuideTopic.deviceWifi);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WiFi alat'),
        actions: [
          IconButton(
            tooltip: 'Panduan',
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => openGuide(context, GuideTopic.deviceWifi),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.xxl),
            children: [
              AppCard(
                color: AppColors.surfaceRaised,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(title: 'Langkah konfigurasi ulang', subtitle: section.summary),
                    const SizedBox(height: Gap.lg),
                    for (var i = 0; i < section.steps.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Gap.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.navActive,
                              child: Text('${i + 1}', style: t.labelSmall?.copyWith(color: Colors.white)),
                            ),
                            const SizedBox(width: Gap.md),
                            Expanded(child: Text(section.steps[i], style: t.bodyMedium)),
                          ],
                        ),
                      ),
                    if (section.warning != null) InfoBanner(message: section.warning!, tone: Tone.warning),
                  ],
                ),
              ),
              const SizedBox(height: Gap.md),
              if (!device.isDeviceOnline) ...[
                InfoBanner(message: '${link.label}: ${link.detail}', tone: link.tone),
                const SizedBox(height: Gap.md),
              ],
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                onPressed: device.canSendCommands ? () => _reset(context, device) : null,
                icon: const Icon(Icons.router_rounded),
                label: const Text('Reset WiFi alat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
