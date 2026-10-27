import 'package:alburdat_dashboard/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Kartu dasar: permukaan terang, sudut besar, tanpa bayangan.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Gap.lg),
    this.color = AppColors.surface,
    this.onTap,
    this.radius = Radii.lg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: const BorderSide(color: AppColors.border, width: 0.6),
    );
    return Material(
      color: color,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Judul bagian dengan tombol panah opsional di kanan (↗) seperti referensi.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.subtitle, this.onMore, this.trailing});

  final String title;
  final String? subtitle;
  final VoidCallback? onMore;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: t.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: t.bodySmall),
              ],
            ],
          ),
        ),
        ?trailing,
        if (onMore != null) CornerArrow(onTap: onMore),
      ],
    );
  }
}

/// Tombol panah kecil di pojok kartu.
class CornerArrow extends StatelessWidget {
  const CornerArrow({super.key, this.onTap, this.color = AppColors.ink, this.background});

  final VoidCallback? onTap;
  final Color color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background ?? Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(Icons.north_east_rounded, size: 16, color: color),
        ),
      ),
    );
  }
}
