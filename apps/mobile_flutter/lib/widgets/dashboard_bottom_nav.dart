import 'package:flutter/material.dart';
import '../config/theme.dart';

enum DashboardTab {
  dashboard(0, 'Dashboard', Icons.home),
  wearables(1, 'Wearables', Icons.watch),
  detective(2, 'Detective', Icons.lightbulb),
  profile(3, 'Profile', Icons.person);

  final int tabIndex;
  final String label;
  final IconData icon;

  const DashboardTab(this.tabIndex, this.label, this.icon);
}

class DashboardBottomNav extends StatelessWidget {
  final DashboardTab currentTab;
  final ValueChanged<DashboardTab> onTabChanged;

  const DashboardBottomNav({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: DashboardTab.values.map((tab) {
              final isActive = currentTab == tab;
              return _buildNavItem(
                context,
                tab,
                isActive,
                () => onTabChanged(tab),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    DashboardTab tab,
    bool isActive,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const activeColor = AppColors.primaryBlue;
    final inactiveColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tab.icon,
            size: 24,
            color: isActive ? activeColor : inactiveColor,
          ),
          const SizedBox(height: 4),
          Text(
            tab.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isActive ? activeColor : inactiveColor,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
          ),
          if (isActive)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                ),
              ),
            )
        ],
      ),
    );
  }
}
