import 'package:alburdat_dashboard/core/theme/app_theme.dart';
import 'package:alburdat_dashboard/widgets/app_card.dart';
import 'package:alburdat_dashboard/widgets/status_widgets.dart';
import 'package:flutter/material.dart';

/// Ubin metrik seperti "Plant Health / Wind / Temperature" pada referensi:
/// ikon kiri atas, panah kanan atas, label, lalu nilai besar + satuan kecil.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
    this.highlighted = false,
    this.badge,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? unit;

  /// Ubin hijau penuh (metrik utama).
  final bool highlighted;
  final StatusPill? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final fg = highlighted ? Colors.white : AppColors.ink;
    final muted = highlighted ? Colors.white.withValues(alpha: 0.85) : AppColors.inkMuted;

    return AppCard(
      color: highlighted ? AppColors.primary : AppColors.surfaceRaised,
      padding: const EdgeInsets.all(Gap.md),
      onTap: onTap,
      child: SizedBox(
        height: 96,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: muted),
                const Spacer(),
                if (onTap != null)
                  CornerArrow(
                    onTap: onTap,
                    color: fg,
                    background: highlighted ? Colors.white.withValues(alpha: 0.18) : null,
                  ),
              ],
            ),
            const SizedBox(height: Gap.xs),
            Text(label, style: t.labelMedium?.copyWith(color: muted), maxLines: 1, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      value,
                      style: t.displaySmall?.copyWith(color: fg, fontSize: 28),
                    ),
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 2),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(unit!, style: t.labelSmall?.copyWith(color: muted)),
                  ),
                ],
                if (badge != null) ...[const SizedBox(width: Gap.sm), badge!],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
