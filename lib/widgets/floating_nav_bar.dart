import 'package:alburdat_dashboard/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class NavDestination {
  const NavDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Navigasi bawah mengambang: kapsul terang dengan ikon, item aktif berupa
/// kotak gelap berikon putih (sesuai referensi).
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: Gap.md),
      child: Center(
        heightFactor: 1,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: Gap.lg),
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(color: AppColors.border, width: 0.6),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _NavItem(
                    destination: destinations[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.destination, required this.selected, required this.onTap});

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      child: Tooltip(
        message: destination.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 52,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? AppColors.navActive : Colors.transparent,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Icon(
                destination.icon,
                size: 22,
                color: selected ? Colors.white : AppColors.inkMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
