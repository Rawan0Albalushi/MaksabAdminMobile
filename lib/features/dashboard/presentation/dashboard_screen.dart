import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/providers/auth_provider.dart';
import '../../orders/presentation/providers/orders_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../data/statistics_repository.dart';
import '../presentation/providers/dashboard_date_filter_provider.dart';
import 'widgets/dashboard_date_filter.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_loadStats);
  }

  Future<void> _loadStats() async {
    final filter = ref.read(dashboardDateFilterProvider);
    if (filter.isActive) {
      ref.invalidate(filteredDashboardStatsProvider);
      return;
    }
    await ref.read(ordersProvider.notifier).load(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final auth = ref.watch(authProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final padding = Responsive.pagePadding(context);
    final columns = Responsive.gridColumns(context);
    final statsLoading = auth.loading ||
        !auth.isAuthenticated ||
        statsAsync.isLoading ||
        statsAsync.isRefreshing;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  padding.left,
                  MediaQuery.paddingOf(context).top + 20,
                  padding.right,
                  28,
                ),
                decoration: const BoxDecoration(
                  gradient: AppColors.headerGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.go('/home'),
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: Colors.white,
                          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                        ),
                        Expanded(
                          child: Text(
                            'dashboard'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'welcome_back'.tr(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.fullName ?? 'app_name'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (statsLoading)
                      const SizedBox(
                        height: 80,
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      )
                    else
                      statsAsync.when(
                        loading: () => const SizedBox(
                          height: 80,
                          child: Center(
                            child:
                                CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                        error: (_, __) => Text(
                          'something_wrong'.tr(),
                          style: const TextStyle(color: Colors.white70),
                        ),
                        data: (stats) {
                          if (!stats.hasCounts) {
                            return Text(
                              'no_orders'.tr(),
                              style: const TextStyle(color: Colors.white70),
                            );
                          }
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.receipt_long,
                                    color: Colors.white, size: 36),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      Formatters.number(stats.total),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      'total_orders'.tr(),
                                      style:
                                          const TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: padding,
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const DashboardDateFilterBar(),
                    const SizedBox(height: 16),
                    Text(
                      'overview'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (statsLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      statsAsync.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (error, _) => ErrorView(
                          message: error.toString(),
                          onRetry: _loadStats,
                        ),
                        data: (stats) {
                          if (!stats.hasCounts) {
                            return EmptyState(
                              title: 'no_orders'.tr(),
                              subtitle: 'no_orders_desc'.tr(),
                              icon: Icons.bar_chart_outlined,
                            );
                          }
                          return GridView.count(
                            crossAxisCount: columns,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: columns >= 3 ? 1.4 : 1.2,
                            children: [
                              StatCard(
                                label: 'new_orders'.tr(),
                                value: Formatters.number(stats.newCount),
                                color: AppColors.statusNew,
                                icon: Icons.fiber_new,
                                onTap: () => context.go('/orders'),
                              ),
                              StatCard(
                                label: 'accepted'.tr(),
                                value: Formatters.number(stats.accepted),
                                color: AppColors.statusAccepted,
                                icon: Icons.thumb_up_alt_outlined,
                                onTap: () => context.go('/orders'),
                              ),
                              StatCard(
                                label: 'cooking'.tr(),
                                value: Formatters.number(stats.cooking),
                                color: AppColors.statusCooking,
                                icon: Icons.restaurant,
                                onTap: () => context.go('/orders'),
                              ),
                              StatCard(
                                label: 'ready'.tr(),
                                value: Formatters.number(stats.ready),
                                color: AppColors.statusReady,
                                icon: Icons.check_circle_outline,
                                onTap: () => context.go('/orders'),
                              ),
                              StatCard(
                                label: 'on_the_way'.tr(),
                                value: Formatters.number(stats.onTheWay),
                                color: AppColors.statusOnWay,
                                icon: Icons.delivery_dining,
                                onTap: () => context.go('/orders'),
                              ),
                              StatCard(
                                label: 'delivered'.tr(),
                                value: Formatters.number(stats.delivered),
                                color: AppColors.statusDelivered,
                                icon: Icons.done_all,
                                onTap: () => context.go('/orders'),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
