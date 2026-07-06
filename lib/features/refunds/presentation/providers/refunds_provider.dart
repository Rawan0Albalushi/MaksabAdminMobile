import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/refunds_repository.dart';
import '../../domain/refund_model.dart';

class RefundsState {
  const RefundsState({
    this.refunds = const [],
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.statusFilter = 'all',
    this.search = '',
  });

  final List<RefundModel> refunds;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final int currentPage;
  final int lastPage;
  final int total;
  final String statusFilter;
  final String search;

  bool get hasMore => currentPage < lastPage;

  RefundsState copyWith({
    List<RefundModel>? refunds,
    bool? loading,
    bool? loadingMore,
    String? error,
    int? currentPage,
    int? lastPage,
    int? total,
    String? statusFilter,
    String? search,
  }) {
    return RefundsState(
      refunds: refunds ?? this.refunds,
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

class RefundsNotifier extends StateNotifier<RefundsState> {
  RefundsNotifier(this._repo) : super(const RefundsState());

  final RefundsRepository _repo;

  Future<void> load({bool refresh = false}) async {
    if (state.loading) return;
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _repo.fetchRefunds(
        page: 1,
        status: state.statusFilter,
        search: state.search,
      );
      state = state.copyWith(
        refunds: result.refunds,
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
      final result = await _repo.fetchRefunds(
        page: state.currentPage + 1,
        status: state.statusFilter,
        search: state.search,
      );
      state = state.copyWith(
        refunds: [...state.refunds, ...result.refunds],
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

final refundsProvider =
    StateNotifierProvider<RefundsNotifier, RefundsState>((ref) {
  return RefundsNotifier(ref.watch(refundsRepositoryProvider));
});

final refundDetailProvider =
    FutureProvider.family<RefundModel, int>((ref, id) async {
  return ref.watch(refundsRepositoryProvider).fetchRefund(id);
});

final pendingRefundsCountProvider = FutureProvider<int>((ref) async {
  final result = await ref.watch(refundsRepositoryProvider).fetchRefunds(
        page: 1,
        perPage: 1,
        status: 'pending',
      );
  return result.total;
});
