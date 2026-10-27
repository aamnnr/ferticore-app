import 'package:alburdat_dashboard/core/theme/app_theme.dart';
import 'package:alburdat_dashboard/core/utils/formatters.dart';
import 'package:alburdat_dashboard/services/mqtt/device_service.dart';
import 'package:flutter/material.dart';

/// Ringkasan status koneksi broker + alat untuk ditampilkan di UI.
/// Satu sumber kebenaran (dulu logika ini disalin di 3 halaman).
class LinkStatus {
  const LinkStatus({required this.label, required this.detail, required this.tone, required this.icon});

  final String label;
  final String detail;
  final Tone tone;
  final IconData icon;

  factory LinkStatus.of(DeviceService s) {
    switch (s.state) {
      case LinkState.notConfigured:
        return const LinkStatus(
          label: 'Belum diatur',
          detail: 'Atur ID alat & broker di Pengaturan',
          tone: Tone.warning,
          icon: Icons.settings_input_antenna_rounded,
        );
      case LinkState.connecting:
        return const LinkStatus(
          label: 'Menghubungkan',
          detail: 'Menyambung ke broker…',
          tone: Tone.info,
          icon: Icons.sync_rounded,
        );
      case LinkState.disconnected:
        final retry = s.nextRetryAt;
        final secs = retry == null ? null : retry.difference(DateTime.now()).inSeconds.clamp(0, 999);
        return LinkStatus(
          label: 'Terputus',
          detail: [
            s.lastError ?? 'Tidak terhubung ke broker',
            if (secs != null) 'coba lagi ±$secs dtk',
          ].join(' · '),
          tone: Tone.danger,
          icon: Icons.cloud_off_rounded,
        );
      case LinkState.connected:
        if (s.isDeviceOnline) {
          return LinkStatus(
            label: 'Alat online',
            detail: 'Update ${Fmt.relative(s.status?.receivedAt)}',
            tone: Tone.success,
            icon: Icons.wifi_rounded,
          );
        }
        final last = s.status?.receivedAt;
        return LinkStatus(
          label: 'Alat offline',
          detail: last == null
              ? 'Broker OK, menunggu data dari alat'
              : 'Sinyal hilang sejak ${Fmt.time(last)}',
          tone: Tone.warning,
          icon: Icons.portable_wifi_off_rounded,
        );
    }
  }
}
