import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../dashboard/presentation/widgets/zone_filter.dart';
import 'providers/drivers_provider.dart';
import 'widgets/driver_card.dart';

class DriversScreen extends ConsumerStatefulWidget {
  const DriversScreen({super.key});

  @override
  ConsumerState<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends ConsumerState<DriversScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  static const _activeFilters = ['all', 'active', 'inactive'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(driversProvider.notifier).load());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(driversProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _filterLabel(String filter) {
    switch (filter) {
      case 'active':
        return 'driver_approved'.tr();
      case 'inactive':
        return 'driver_pending'.tr();
      default:
        return 'all'.tr();
    }
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(driversProvider);
    final padding = Responsive.pagePadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('drivers'.tr()),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(driversProvider.notifier).load(refresh: true),
        color: AppColors.primary,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: padding.copyWith(bottom: 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'search_drivers'.tr(),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                  ref
                                      .read(driversProvider.notifier)
                                      .setSearch('');
                                },
                              )
                            : null,
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (v) =>
                          ref.read(driversProvider.notifier).setSearch(v),
                    ),
                    const SizedBox(height: 12),
                    ZoneFilter(
                      selectedZoneId: state.zoneId,
                      onZoneChanged: (zoneId) {
                        _scrollToTop();
                        ref
                            .read(driversProvider.notifier)
                            .setZoneFilter(zoneId);
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _activeFilters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final filter = _activeFilters[index];
                          final selected = state.activeFilter == filter;
                          return FilterChip(
                            label: Text(_filterLabel(filter)),
                            selected: selected,
                            onSelected: (_) {
                              _scrollToTop();
                              ref
                                  .read(driversProvider.notifier)
                                  .setActiveFilter(filter);
                            },
                            selectedColor:
                                AppColors.primary.withValues(alpha: 0.15),
                            checkmarkColor: AppColors.primary,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (state.loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.error != null && state.drivers.isEmpty)
              SliverFillRemaining(
                child: ErrorView(
                  message: state.error!,
                  onRetry: () => ref.read(driversProvider.notifier).load(),
                ),
              )
            else if (state.drivers.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  title: 'no_drivers'.tr(),
                  subtitle: 'no_drivers_desc'.tr(),
                  icon: Icons.delivery_dining_outlined,
                ),
              )
            else
              SliverPadding(
                padding: padding,
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= state.drivers.length) {
                        return state.loadingMore
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : const SizedBox.shrink();
                      }
                      final driver = state.drivers[index];
                      return DriverCard(
                        driver: driver,
                        onTap: () {
                          final target = driver.uuid.trim();
                          if (target.isEmpty) return;
                          context.push('/drivers/$target');
                        },
                      );
                    },
                    childCount:
                        state.drivers.length + (state.loadingMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
