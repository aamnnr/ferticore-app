import 'package:alburdat_dashboard/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Label kecil berwarna (mis. "Baik", "Online").
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, this.tone = Tone.success, this.inverted = false, this.icon});

  final String label;
  final Tone tone;

  /// Untuk dipakai di atas latar hijau (teks hijau, latar putih).
  final bool inverted;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = inverted ? tone.foreground : Colors.white;
    final bg = inverted ? Colors.white : tone.foreground;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: fg), const SizedBox(width: 4)],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Titik status (●) berwarna.
class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.tone, this.size = 8});

  final Tone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: tone.foreground, shape: BoxShape.circle),
    );
  }
}

/// Baris informasi/peringatan (mis. "⚠ Sinyal hilang sejak 09:02").
class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.message, this.tone = Tone.info, this.icon, this.action});

  final String message;
  final Tone tone;
  final IconData? icon;
  final Widget? action;

  IconData get _defaultIcon => switch (tone) {
    Tone.warning => Icons.warning_amber_rounded,
    Tone.danger => Icons.error_outline_rounded,
    Tone.success => Icons.check_circle_outline_rounded,
    _ => Icons.info_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: 10),
      decoration: BoxDecoration(color: tone.background, borderRadius: BorderRadius.circular(Radii.sm)),
      child: Row(
        children: [
          Icon(icon ?? _defaultIcon, size: 16, color: tone.foreground),
          const SizedBox(width: Gap.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tone.foreground),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Bar progres tipis seperti kartu "Task" pada referensi.
class ThinProgress extends StatelessWidget {
  const ThinProgress({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: 4,
        backgroundColor: AppColors.border,
        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
      ),
    );
  }
}

/// Tampilan kosong/placeholder yang konsisten.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.action});

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.xl),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(Gap.lg),
            decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: Gap.md),
          Text(title, style: t.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: Gap.xs),
          Text(message, style: t.bodySmall, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: Gap.lg), action!],
        ],
      ),
    );
  }
}
