import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../dashboard/presentation/widgets/zone_filter.dart';
import 'providers/deliveryman_requests_provider.dart';
import 'providers/drivers_provider.dart';
import 'widgets/deliveryman_request_card.dart';
import 'widgets/deliveryman_request_details_sheet.dart';
import 'widgets/deliveryman_request_status_sheet.dart';
import 'widgets/driver_card.dart';

class DriversScreen extends ConsumerStatefulWidget {
  const DriversScreen({super.key});

  @override
  ConsumerState<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends ConsumerState<DriversScreen> {
  final _searchController = TextEditingController();
  final _driversScrollController = ScrollController();
  final _requestsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(driversProvider.notifier).load());
    _driversScrollController.addListener(_onDriversScroll);
    _requestsScrollController.addListener(_onRequestsScroll);
  }

  void _onDriversScroll() {
    if (_driversScrollController.position.pixels >=
        _driversScrollController.position.maxScrollExtent - 200) {
      ref.read(driversProvider.notifier).loadMore();
    }
  }

  void _onRequestsScroll() {
    if (_requestsScrollController.position.pixels >=
        _requestsScrollController.position.maxScrollExtent - 200) {
      ref.read(deliverymanRequestsProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _driversScrollController.dispose();
    _requestsScrollController.dispose();
    super.dispose();
  }

  void _scrollDriversToTop() {
    if (!_driversScrollController.hasClients) return;
    _driversScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _onTabChanged(String tab) async {
    if (ref.read(driversTabProvider) == tab) return;
    ref.read(driversTabProvider.notifier).state = tab;
    if (tab == 'requests') {
      await ref.read(deliverymanRequestsProvider.notifier).load();
    }
  }

  Future<void> _onRefresh() async {
    final tab = ref.read(driversTabProvider);
    if (tab == 'requests') {
      await ref
          .read(deliverymanRequestsProvider.notifier)
          .load(refresh: true);
    } else {
      await ref.read(driversProvider.notifier).load(refresh: true);
    }
  }

  Future<void> _changeRequestStatus(int id, String currentStatus) async {
    await DeliverymanRequestStatusSheet.show(
      context,
      currentStatus: currentStatus,
      onSubmit: (status, note) async {
        await ref.read(deliverymanRequestsProvider.notifier).changeStatus(
              id: id,
              status: status,
              statusNote: note,
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('driver_request_updated'.tr())),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(driversTabProvider);
    final padding = Responsive.pagePadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('drivers'.tr()),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: padding.copyWith(top: 8, bottom: 0),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'list',
                  label: Text('drivers_tab_list'.tr()),
                ),
                ButtonSegment(
                  value: 'requests',
                  label: Text('drivers_tab_requests'.tr()),
                ),
              ],
              selected: {tab},
              onSelectionChanged: (s) => _onTabChanged(s.first),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppColors.primary,
              child: tab == 'requests'
                  ? _buildRequestsList(padding)
                  : _buildDriversList(padding),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriversList(EdgeInsets padding) {
    final state = ref.watch(driversProvider);

    return CustomScrollView(
      controller: _driversScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: padding.copyWith(bottom: 8, top: 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'search_drivers'.tr(),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                              ref.read(driversProvider.notifier).setSearch('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (v) =>
                      ref.read(driversProvider.notifier).setSearch(v.trim()),
                ),
                const SizedBox(height: 12),
                ZoneFilter(
                  selectedZoneId: state.zoneId,
                  onZoneChanged: (zoneId) {
                    _scrollDriversToTop();
                    ref.read(driversProvider.notifier).setZoneFilter(zoneId);
                  },
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
    );
  }

  Widget _buildRequestsList(EdgeInsets padding) {
    final state = ref.watch(deliverymanRequestsProvider);

    return CustomScrollView(
      controller: _requestsScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (state.loading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.error != null && state.requests.isEmpty)
          SliverFillRemaining(
            child: ErrorView(
              message: state.error!,
              onRetry: () =>
                  ref.read(deliverymanRequestsProvider.notifier).load(),
            ),
          )
        else if (state.requests.isEmpty)
          SliverFillRemaining(
            child: EmptyState(
              title: 'no_driver_requests'.tr(),
              subtitle: 'no_driver_requests_desc'.tr(),
              icon: Icons.assignment_outlined,
            ),
          )
        else
          SliverPadding(
            padding: padding.copyWith(top: 12),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= state.requests.length) {
                    return state.loadingMore
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : const SizedBox.shrink();
                  }
                  final request = state.requests[index];
                  return DeliverymanRequestCard(
                    request: request,
                    onViewDetails: () => DeliverymanRequestDetailsSheet.show(
                      context,
                      request: request,
                    ),
                    onChangeStatus: request.canChangeStatus
                        ? () => _changeRequestStatus(
                              request.id,
                              request.status,
                            )
                        : null,
                  );
                },
                childCount:
                    state.requests.length + (state.loadingMore ? 1 : 0),
              ),
            ),
          ),
      ],
    );
  }
}
