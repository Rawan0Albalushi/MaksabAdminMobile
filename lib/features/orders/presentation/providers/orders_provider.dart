import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/orders_repository.dart';
import '../../domain/order_model.dart';

class OrdersState {
  const OrdersState({
    this.orders = const [],
    this.statistic = const {},
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.statusFilter = 'all',
    this.search = '',
  });

  final List<OrderModel> orders;
  final Map<String, dynamic> statistic;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final int currentPage;
  final int lastPage;
  final int total;
  final String statusFilter;
  final String search;

  bool get hasMore => currentPage < lastPage;

  OrdersState copyWith({
    List<OrderModel>? orders,
    Map<String, dynamic>? statistic,
    bool? loading,
    bool? loadingMore,
    String? error,
    int? currentPage,
    int? lastPage,
    int? total,
    String? statusFilter,
    String? search,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      statistic: statistic ?? this.statistic,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      statusFilter: statusFilter ?? this.statusFilter,
      search: search ?? this.search,
    );
  }
}

class OrdersNotifier extends StateNotifier<OrdersState> {
  OrdersNotifier(this._repo) : super(const OrdersState());

  final OrdersRepository _repo;

  Future<void> load({bool refresh = false}) async {
    if (state.loading) return;
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _repo.fetchOrders(
        page: 1,
        status: state.statusFilter,
        search: state.search,
      );
      state = state.copyWith(
        orders: result.orders,
        statistic: result.statistic,
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        total: result.total,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) return;
    state = state.copyWith(loadingMore: true);
    try {
      final result = await _repo.fetchOrders(
        page: state.currentPage + 1,
        status: state.statusFilter,
        search: state.search,
      );
      state = state.copyWith(
        orders: [...state.orders, ...result.orders],
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        loadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(loadingMore: false, error: e.toString());
    }
  }

  Future<void> setStatusFilter(String status) async {
    state = state.copyWith(statusFilter: status);
    await load(refresh: true);
  }

  Future<void> setSearch(String query) async {
    state = state.copyWith(search: query);
    await load(refresh: true);
  }
}

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  return OrdersNotifier(ref.watch(ordersRepositoryProvider));
});

final orderDetailProvider =
    FutureProvider.family<OrderModel, int>((ref, id) async {
  return ref.watch(ordersRepositoryProvider).fetchOrder(id);
});
