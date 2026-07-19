import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../drivers/data/drivers_repository.dart';
import '../../../drivers/domain/driver_model.dart';
import '../../../drivers/presentation/widgets/driver_status_chip.dart';

class SelectDeliveryManSheet extends ConsumerStatefulWidget {
  const SelectDeliveryManSheet({
    super.key,
    this.currentDriverId,
    required this.onSelected,
  });

  final int? currentDriverId;
  final Future<void> Function(DriverModel driver) onSelected;

  static Future<void> show(
    BuildContext context, {
    int? currentDriverId,
    required Future<void> Function(DriverModel driver) onSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SelectDeliveryManSheet(
        currentDriverId: currentDriverId,
        onSelected: onSelected,
      ),
    );
  }

  @override
  ConsumerState<SelectDeliveryManSheet> createState() =>
      _SelectDeliveryManSheetState();
}

class _SelectDeliveryManSheetState
    extends ConsumerState<SelectDeliveryManSheet> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  List<DriverModel> _drivers = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _lastPage = 1;
  String _search = '';
  int? _assigningId;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load({bool refresh = false}) async {
    final requestId = ++_requestId;
    setState(() {
      if (refresh) {
        _error = null;
      } else {
        _loading = true;
        _error = null;
      }
    });

    try {
      final result = await ref.read(driversRepositoryProvider).fetchDrivers(
            page: 1,
            search: _search,
            active: true,
          );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _drivers = result.drivers;
        _page = result.currentPage;
        _lastPage = result.lastPage;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page >= _lastPage) return;
    setState(() => _loadingMore = true);
    final requestId = _requestId;
    try {
      final result = await ref.read(driversRepositoryProvider).fetchDrivers(
            page: _page + 1,
            search: _search,
            active: true,
          );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _drivers = [..._drivers, ...result.drivers];
        _page = result.currentPage;
        _lastPage = result.lastPage;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() => _loadingMore = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final next = value.trim();
      if (next == _search) return;
      _search = next;
      _load();
    });
  }

  Future<void> _select(DriverModel driver) async {
    if (_assigningId != null) return;
    if (widget.currentDriverId != null &&
        widget.currentDriverId == driver.id) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _assigningId = driver.id);
    try {
      await widget.onSelected(driver);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _assigningId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final height = MediaQuery.sizeOf(context).height * 0.85;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'select_delivery_man'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'search_drivers'.tr(),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ErrorView(
        message: _error!,
        onRetry: () => _load(),
      );
    }

    if (_drivers.isEmpty) {
      return EmptyState(
        icon: Icons.delivery_dining_outlined,
        title: 'no_drivers'.tr(),
        subtitle: 'no_drivers_desc'.tr(),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _drivers.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _drivers.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final driver = _drivers[index];
        final isCurrent = widget.currentDriverId == driver.id;
        final isAssigning = _assigningId == driver.id;

        return _DriverPickTile(
          driver: driver,
          isCurrent: isCurrent,
          loading: isAssigning,
          enabled: _assigningId == null,
          onTap: () => _select(driver),
        );
      },
    );
  }
}

class _DriverPickTile extends StatelessWidget {
  const _DriverPickTile({
    required this.driver,
    required this.isCurrent,
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  final DriverModel driver;
  final bool isCurrent;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              AppNetworkAvatar(
                radius: 24,
                imageUrl: MediaUrl.resolve(driver.img),
                fallbackText: driver.fullName,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            driver.fullName,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrent)
                          Container(
                            margin: const EdgeInsetsDirectional.only(start: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'delivery_man_current'.tr(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        else
                          DriverStatusChip(active: driver.active),
                      ],
                    ),
                    if (driver.phone != null && driver.phone!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        driver.phone!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (loading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  isCurrent ? Icons.check_circle : Icons.chevron_right,
                  color: isCurrent ? AppColors.primary : AppColors.textHint,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
