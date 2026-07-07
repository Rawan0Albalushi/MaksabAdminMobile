import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'modern_bottom_nav_bar.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Padding(
        padding: EdgeInsets.only(
          bottom: ModernBottomNavBar.contentBottomInset(context),
        ),
        child: navigationShell,
      ),
      bottomNavigationBar: ModernBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          if (index == 0) {
            context.go('/home');
            return;
          }
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        items: [
          BottomNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: 'home'.tr(),
          ),
          BottomNavItem(
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long_rounded,
            label: 'orders'.tr(),
          ),
          BottomNavItem(
            icon: Icons.assignment_return_outlined,
            selectedIcon: Icons.assignment_return_rounded,
            label: 'refunds'.tr(),
          ),
          BottomNavItem(
            icon: Icons.chat_bubble_outline_rounded,
            selectedIcon: Icons.chat_bubble_rounded,
            label: 'chat'.tr(),
          ),
          BottomNavItem(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings_rounded,
            label: 'settings'.tr(),
          ),
        ],
      ),
    );
  }
}

