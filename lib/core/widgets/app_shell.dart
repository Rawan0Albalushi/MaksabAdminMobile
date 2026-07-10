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
    // Match the real path so screens like /dashboard (same branch as home)
    // do not keep the Home tab highlighted.
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _selectedNavIndex(navServices, location);

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

  /// Returns the bottom-nav index for [location], or `-1` when the route is
  /// not represented in the bar (e.g. dashboard, shops, refunds).
  int _selectedNavIndex(List<AppService> navItems, String location) {
    final path = Uri.parse(location).path;
    return navItems.indexWhere(
      (item) => path == item.route || path.startsWith('${item.route}/'),
    );
  }
}
