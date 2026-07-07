import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'widgets/service_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static List<ServiceTileData> get _services => [
    ServiceTileData(
      titleKey: 'dashboard',
      subtitleKey: 'home_dashboard_desc',
      icon: Icons.analytics_outlined,
      style: ServiceGradients.dashboard,
      route: '/dashboard',
    ),
    ServiceTileData(
      titleKey: 'orders',
      subtitleKey: 'home_orders_desc',
      icon: Icons.receipt_long_outlined,
      style: ServiceGradients.orders,
      route: '/orders',
    ),
    ServiceTileData(
      titleKey: 'refunds',
      subtitleKey: 'home_refunds_desc',
      icon: Icons.assignment_return_outlined,
      style: ServiceGradients.refunds,
      route: '/refunds',
    ),
    ServiceTileData(
      titleKey: 'conversations',
      subtitleKey: 'home_chat_desc',
      icon: Icons.chat_bubble_outline_rounded,
      style: ServiceGradients.chat,
      route: '/chat',
    ),
    ServiceTileData(
      titleKey: 'settings',
      subtitleKey: 'home_settings_desc',
      icon: Icons.settings_outlined,
      style: ServiceGradients.settings,
      route: '/settings',
    ),
  ];

  void _navigate(BuildContext context, String route) {
    context.go(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final padding = Responsive.pagePadding(context);
    final columns = Responsive.isTablet(context) ? 3 : 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                padding.left,
                MediaQuery.paddingOf(context).top + 24,
                padding.right,
                32,
              ),
              decoration: const BoxDecoration(
                gradient: AppColors.headerGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.grid_view_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'home'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'home_subtitle'.tr(),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                          child: Text(
                            _initials(user?.fullName ?? ''),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'welcome_back'.tr(),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.fullName ?? 'app_name'.tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: padding.copyWith(top: 24, bottom: 16),
            sliver: SliverToBoxAdapter(
              child: Text(
                'services'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
          ),
          SliverPadding(
            padding: padding.copyWith(top: 0),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: columns >= 3 ? 1.05 : 0.88,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final service = _services[index];
                  return ServiceTile(
                    title: service.titleKey.tr(),
                    subtitle: service.subtitleKey.tr(),
                    icon: service.icon,
                    style: service.style,
                    onTap: () => _navigate(context, service.route),
                  );
                },
                childCount: _services.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'A';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
