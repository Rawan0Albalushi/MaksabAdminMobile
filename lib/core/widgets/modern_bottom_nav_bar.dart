import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';

class BottomNavItem {
  const BottomNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class ModernBottomNavBar extends StatelessWidget {
  const ModernBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  static const barHeight = 72.0;
  static const outerBottomPadding = 12.0;

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavItem> items;

  static double contentBottomInset(BuildContext context) {
    return barHeight.h + outerBottomPadding.h + MediaQuery.paddingOf(context).bottom;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, outerBottomPadding.h + bottomInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28.r),
          child: SizedBox(
            height: barHeight.h,
            child: Row(
              children: List.generate(items.length, (index) {
                final item = items[index];
                final selected = currentIndex == index;

                return Expanded(
                  child: _NavBarTile(
                    item: item,
                    selected: selected,
                    onTap: () {
                      // Allow re-tapping the selected tab so nested routes
                      // in the same branch (e.g. /dashboard) can reset to root.
                      HapticFeedback.lightImpact();
                      onTap(index);
                    },
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarTile extends StatelessWidget {
  const _NavBarTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final BottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.04),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            gradient: selected ? AppColors.headerGradient : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: selected ? 1.06 : 1,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Icon(
                      selected ? item.selectedIcon : item.icon,
                      key: ValueKey(selected),
                      size: selected ? 22 : 20,
                      color: selected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  style: TextStyle(
                    fontSize: selected ? 11 : 10,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? Colors.white : AppColors.textSecondary,
                    height: 1,
                  ),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}
