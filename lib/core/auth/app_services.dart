import 'package:flutter/material.dart';

import '../../features/home/presentation/widgets/service_tile.dart';
import '../config/app_config.dart';
import '../../features/auth/domain/admin_user.dart';

/// A navigable admin service (home tile and/or bottom nav entry).
class AppService {
  const AppService({
    required this.id,
    required this.route,
    required this.titleKey,
    required this.subtitleKey,
    required this.icon,
    required this.selectedIcon,
    required this.style,
    required this.allowedRoles,
    this.requiredPermissions = const [],
    this.showInBottomNav = false,
    this.navBranchIndex,
  });

  final String id;
  final String route;
  final String titleKey;
  final String subtitleKey;
  final IconData icon;
  final IconData selectedIcon;
  final ServiceStyle style;
  final List<String> allowedRoles;
  final List<String> requiredPermissions;
  final bool showInBottomNav;
  final int? navBranchIndex;

  bool isAllowedFor(AdminUser user) {
    if (user.isFullAdmin) return true;

    final roleAllowed = user.canAccessRoles(allowedRoles);
    if (requiredPermissions.isEmpty || user.permissions.isEmpty) {
      return roleAllowed;
    }

    return user.hasAnyPermission(requiredPermissions);
  }

  ServiceTileData toTileData() {
    return ServiceTileData(
      titleKey: titleKey,
      subtitleKey: subtitleKey,
      icon: icon,
      style: style,
      route: route,
    );
  }
}

/// Central registry of admin services and their role requirements.
abstract class AppServices {
  AppServices._();

  static const home = AppService(
    id: 'home',
    route: '/home',
    titleKey: 'home',
    subtitleKey: 'home_subtitle',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    style: ServiceGradients.settings,
    allowedRoles: AppConfig.portalRoles,
    requiredPermissions: [AppConfig.portalAccessPermission],
    showInBottomNav: true,
    navBranchIndex: 0,
  );

  static const dashboard = AppService(
    id: 'dashboard',
    route: '/dashboard',
    titleKey: 'dashboard',
    subtitleKey: 'home_dashboard_desc',
    icon: Icons.analytics_outlined,
    selectedIcon: Icons.analytics_outlined,
    style: ServiceGradients.dashboard,
    allowedRoles: [
      AppConfig.roleAdmin,
      AppConfig.roleZoneAdmin,
      AppConfig.roleZoneManager,
      AppConfig.roleAccountant,
    ],
    requiredPermissions: ['admin.orders.view'],
  );

  static const shops = AppService(
    id: 'shops',
    route: '/shops',
    titleKey: 'shops',
    subtitleKey: 'home_shops_desc',
    icon: Icons.store_outlined,
    selectedIcon: Icons.store_rounded,
    style: ServiceGradients.shops,
    allowedRoles: [
      AppConfig.roleAdmin,
      AppConfig.roleZoneAdmin,
      AppConfig.roleZoneManager,
    ],
    requiredPermissions: ['admin.shops.manage'],
  );

  static const orders = AppService(
    id: 'orders',
    route: '/orders',
    titleKey: 'orders',
    subtitleKey: 'home_orders_desc',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long_rounded,
    style: ServiceGradients.orders,
    allowedRoles: [
      AppConfig.roleAdmin,
      AppConfig.roleZoneAdmin,
      AppConfig.roleZoneManager,
      AppConfig.roleSupport,
    ],
    requiredPermissions: ['admin.orders.view'],
    showInBottomNav: true,
    navBranchIndex: 1,
  );

  static const refunds = AppService(
    id: 'refunds',
    route: '/refunds',
    titleKey: 'refunds',
    subtitleKey: 'home_refunds_desc',
    icon: Icons.assignment_return_outlined,
    selectedIcon: Icons.assignment_return_rounded,
    style: ServiceGradients.refunds,
    allowedRoles: [
      AppConfig.roleAdmin,
      AppConfig.roleAccountant,
    ],
    requiredPermissions: ['admin.orders.refund'],
  );

  static const chat = AppService(
    id: 'chat',
    route: '/chat',
    titleKey: 'conversations',
    subtitleKey: 'home_chat_desc',
    icon: Icons.chat_bubble_outline_rounded,
    selectedIcon: Icons.chat_bubble_rounded,
    style: ServiceGradients.chat,
    allowedRoles: [
      AppConfig.roleAdmin,
      AppConfig.roleZoneAdmin,
      AppConfig.roleZoneManager,
      AppConfig.roleSupport,
    ],
    requiredPermissions: ['admin.chat.view', 'admin.support.chat'],
    showInBottomNav: true,
    navBranchIndex: 3,
  );

  static const settings = AppService(
    id: 'settings',
    route: '/settings',
    titleKey: 'settings',
    subtitleKey: 'home_settings_desc',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
    style: ServiceGradients.settings,
    allowedRoles: AppConfig.portalRoles,
    requiredPermissions: [AppConfig.portalAccessPermission],
    showInBottomNav: true,
    navBranchIndex: 4,
  );

  static const List<AppService> all = [
    dashboard,
    shops,
    orders,
    refunds,
    chat,
    settings,
  ];

  static List<AppService> homeTilesFor(AdminUser user) {
    return all.where((service) => service.isAllowedFor(user)).toList();
  }

  static List<AppService> bottomNavFor(AdminUser user) {
    final items = <AppService>[home];
    items.addAll(
      all.where((service) => service.showInBottomNav && service.isAllowedFor(user)),
    );
    return items;
  }

  static AppService? forRoute(String location) {
    final path = Uri.parse(location).path;
    for (final service in [home, ...all]) {
      if (path == service.route || path.startsWith('${service.route}/')) {
        return service;
      }
    }
    return null;
  }

  static bool canAccessRoute(AdminUser? user, String location) {
    if (user == null) return false;
    final service = forRoute(location);
    if (service == null) return true;
    return service.isAllowedFor(user);
  }
}
