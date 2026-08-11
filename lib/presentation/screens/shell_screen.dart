import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    _TabItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    _TabItem(icon: Icons.search_outlined, activeIcon: Icons.search_rounded, label: 'Search'),
    _TabItem(icon: Icons.qr_code_scanner_rounded, activeIcon: Icons.qr_code_scanner_rounded, label: 'Scan'),
    _TabItem(icon: Icons.compare_arrows_outlined, activeIcon: Icons.compare_arrows_rounded, label: 'Compare'),
    _TabItem(icon: Icons.favorite_border_rounded, activeIcon: Icons.favorite_rounded, label: 'Saved'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryLight,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: _tabs
            .map(
              (t) => NavigationDestination(
                icon: Icon(t.icon, color: AppColors.textTertiary),
                selectedIcon: Icon(t.activeIcon, color: AppColors.primary),
                label: t.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
