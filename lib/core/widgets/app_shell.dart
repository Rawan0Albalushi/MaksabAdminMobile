import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/app_services.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'modern_bottom_nav_bar.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final navServices = user == null ? <AppService>[] : AppServices.bottomNavFor(user);
    final currentBranch = navigationShell.currentIndex;
    final selectedIndex = _visibleIndexForBranch(navServices, currentBranch);

    return Scaffold(
      extendBody: true,
      body: Padding(
        padding: EdgeInsets.only(
          bottom: ModernBottomNavBar.contentBottomInset(context),
        ),
        child: navigationShell,
      ),
      bottomNavigationBar: navServices.isEmpty
          ? null
          : ModernBottomNavBar(
              currentIndex: selectedIndex,
              onTap: (index) {
                final service = navServices[index];
                final branchIndex = service.navBranchIndex;
                if (branchIndex == null || branchIndex == 0) {
                  context.go('/home');
                  return;
                }
                navigationShell.goBranch(
                  branchIndex,
                  initialLocation: branchIndex == navigationShell.currentIndex,
                );
              },
              items: navServices
                  .map(
                    (service) => BottomNavItem(
                      icon: service.icon,
                      selectedIcon: service.selectedIcon,
                      label: service.titleKey.tr(),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  int _visibleIndexForBranch(List<AppService> navItems, int branchIndex) {
    final index = navItems.indexWhere((item) => item.navBranchIndex == branchIndex);
    return index >= 0 ? index : 0;
  }
}
