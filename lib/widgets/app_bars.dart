import 'package:alburdat_dashboard/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Logo bulat hijau dengan daun (seperti referensi).
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
      child: Icon(Icons.eco_rounded, color: Colors.white, size: size * 0.5),
    );
  }
}

/// Tombol ikon persegi membulat berlatar terang (lonceng/menu pada referensi).
class SquareIconButton extends StatelessWidget {
  const SquareIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.badgeColor,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  /// Titik kecil di pojok (mis. merah = ada masalah).
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          side: const BorderSide(color: AppColors.border, width: 0.6),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.sm),
          onTap: onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 20, color: AppColors.ink),
                if (badgeColor != null)
                  Positioned(
                    top: 9,
                    right: 10,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Header halaman tab: judul di tengah + aksi kanan (referensi "Analytic").
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.leading, this.actions = const []});

  final String title;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          if (leading != null) Align(alignment: Alignment.centerLeft, child: leading),
          if (actions.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: Gap.sm),
                    actions[i],
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Kerangka halaman tab yang konsisten: safe area, padding, ruang navigasi.
class TabPage extends StatelessWidget {
  const TabPage({super.key, required this.header, required this.children, this.onRefresh});

  final Widget header;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.navClearance),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [header, const SizedBox(height: Gap.md), ...children],
    );
    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: onRefresh == null
              ? list
              : RefreshIndicator(color: AppColors.primary, onRefresh: onRefresh!, child: list),
        ),
      ),
    );
  }
}
