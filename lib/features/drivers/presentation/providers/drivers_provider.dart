import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/domain/zone_model.dart';
import '../../data/drivers_repository.dart';
import '../../domain/driver_model.dart';

class DriversState {
  const DriversState({
    this.drivers = const [],
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.activeFilter = 'all',
    this.search = '',
    this.zoneId,
  });

  final List<DriverModel> drivers;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final int currentPage;
  final int lastPage;
  final int total;
  /// `all` | `active` | `inactive`
  final String activeFilter;
  final String search;
  final int? zoneId;

  bool get hasMore => currentPage < lastPage;

  bool? get activeParam {
    switch (activeFilter) {
      case 'active':
        return true;
      case 'inactive':
        return false;
      default:
        return null;
    }
  }

  DriversState copyWith({
    List<DriverModel>? drivers,
    bool? loading,
    bool? loadingMore,
    String? error,
    int? currentPage,
    int? lastPage,
    int? total,
    String? activeFilter,
    String? search,
    int? zoneId,
    bool clearZone = false,
  }) {
    return DriversState(
      drivers: drivers ?? this.drivers,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      activeFilter: activeFilter ?? this.activeFilter,
      search: search ?? this.search,
      zoneId: clearZone ? null : (zoneId ?? this.zoneId),
    );
  }
}

class DriversNotifier extends StateNotifier<DriversState> {
  DriversNotifier(this._repo) : super(const DriversState());

  final DriversRepository _repo;
  int _requestId = 0;

  Future<void> load({bool refresh = false}) async {
    final requestId = ++_requestId;
    if (refresh) {
      state = state.copyWith(error: null);
    } else {
      state = state.copyWith(loading: true, error: null);
    }
    await _reload(requestId: requestId);
  }

  Future<void> _reload({required int requestId}) async {
    try {
      final result = await _repo.fetchDrivers(
        page: 1,
        search: state.search,
        zoneId: state.zoneId,
        active: state.activeParam,
      );
      if (requestId != _requestId) return;
      state = state.copyWith(
        drivers: result.drivers,
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        total: result.total,
        loading: false,
      );
    } catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) return;
    state = state.copyWith(loadingMore: true);
    try {
      final result = await _repo.fetchDrivers(
        page: state.currentPage + 1,
        search: state.search,
        zoneId: state.zoneId,
        active: state.activeParam,
      );
      state = state.copyWith(
        drivers: [...state.drivers, ...result.drivers],
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        loadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(loadingMore: false, error: e.toString());
    }
  }

  Future<void> setActiveFilter(String filter) async {
    if (state.activeFilter == filter) return;
    final requestId = ++_requestId;
    state = state.copyWith(
      activeFilter: filter,
      drivers: const [],
      loading: true,
      error: null,
      currentPage: 1,
    );
    await _reload(requestId: requestId);
  }

  Future<void> setSearch(String query) async {
    if (state.search == query) return;
    final requestId = ++_requestId;
    state = state.copyWith(
      search: query,
      drivers: const [],
      loading: true,
      error: null,
      currentPage: 1,
    );
    await _reload(requestId: requestId);
  }

  Future<void> setZoneFilter(int? zoneId) async {
    if (state.zoneId == zoneId) return;
    final requestId = ++_requestId;
    state = state.copyWith(
      zoneId: zoneId,
      clearZone: zoneId == null,
      drivers: const [],
      loading: true,
      error: null,
      currentPage: 1,
    );
    await _reload(requestId: requestId);
  }
}

final driversProvider =
    StateNotifierProvider<DriversNotifier, DriversState>((ref) {
  return DriversNotifier(ref.watch(driversRepositoryProvider));
});

final driverDetailProvider =
    FutureProvider.family<DriverModel, String>((ref, uuid) async {
  return ref.watch(driversRepositoryProvider).fetchDriver(uuid);
});

final driverAssignedZonesProvider =
    FutureProvider.family<List<ZoneModel>, String>((ref, uuid) async {
  return ref.watch(driversRepositoryProvider).fetchAssignedZones(uuid);
});
