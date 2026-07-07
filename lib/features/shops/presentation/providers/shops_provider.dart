import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/shops_repository.dart';
import '../../domain/shop_model.dart';

class ShopsState {
  const ShopsState({
    this.shops = const [],
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.statusFilter = 'all',
    this.search = '',
    this.zoneId,
  });

  final List<ShopModel> shops;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final int currentPage;
  final int lastPage;
  final int total;
  final String statusFilter;
  final String search;
  final int? zoneId;

  bool get hasMore => currentPage < lastPage;

  ShopsState copyWith({
    List<ShopModel>? shops,
    bool? loading,
    bool? loadingMore,
    String? error,
    int? currentPage,
    int? lastPage,
    int? total,
    String? statusFilter,
    String? search,
    int? zoneId,
    bool clearZone = false,
  }) {
    return ShopsState(
      shops: shops ?? this.shops,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      statusFilter: statusFilter ?? this.statusFilter,
      search: search ?? this.search,
      zoneId: clearZone ? null : (zoneId ?? this.zoneId),
    );
  }
}

class ShopsNotifier extends StateNotifier<ShopsState> {
  ShopsNotifier(this._repo) : super(const ShopsState());

  final ShopsRepository _repo;
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
      final result = await _repo.fetchShops(
        page: 1,
        status: state.statusFilter,
        search: state.search,
        zoneId: state.zoneId,
      );
      if (requestId != _requestId) return;
      state = state.copyWith(
        shops: result.shops,
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
      final result = await _repo.fetchShops(
        page: state.currentPage + 1,
        status: state.statusFilter,
        search: state.search,
        zoneId: state.zoneId,
      );
      state = state.copyWith(
        shops: [...state.shops, ...result.shops],
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        loadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(loadingMore: false, error: e.toString());
    }
  }

  Future<void> setStatusFilter(String status) async {
    if (state.statusFilter == status) return;
    final requestId = ++_requestId;
    state = state.copyWith(
      statusFilter: status,
      shops: const [],
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
      shops: const [],
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
      shops: const [],
      loading: true,
      error: null,
      currentPage: 1,
    );
    await _reload(requestId: requestId);
  }
}

final shopsProvider = StateNotifierProvider<ShopsNotifier, ShopsState>((ref) {
  return ShopsNotifier(ref.watch(shopsRepositoryProvider));
});

final shopDetailProvider =
    FutureProvider.family<ShopModel, String>((ref, uuid) async {
  return ref.watch(shopsRepositoryProvider).fetchShop(uuid);
});
