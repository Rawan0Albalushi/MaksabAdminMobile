import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/drivers_repository.dart';
import '../../domain/deliveryman_request_model.dart';

class DeliverymanRequestsState {
  const DeliverymanRequestsState({
    this.requests = const [],
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
  });

  final List<DeliverymanRequestModel> requests;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  DeliverymanRequestsState copyWith({
    List<DeliverymanRequestModel>? requests,
    bool? loading,
    bool? loadingMore,
    String? error,
    int? currentPage,
    int? lastPage,
    int? total,
  }) {
    return DeliverymanRequestsState(
      requests: requests ?? this.requests,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
    );
  }
}

class DeliverymanRequestsNotifier
    extends StateNotifier<DeliverymanRequestsState> {
  DeliverymanRequestsNotifier(this._repo)
      : super(const DeliverymanRequestsState());

  final DriversRepository _repo;
  int _requestId = 0;
  bool _loadedOnce = false;

  Future<void> load({bool refresh = false}) async {
    if (_loadedOnce && !refresh && state.requests.isNotEmpty && !state.loading) {
      return;
    }
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
      final result = await _repo.fetchDeliverymanRequests(page: 1);
      if (requestId != _requestId) return;
      _loadedOnce = true;
      state = state.copyWith(
        requests: result.requests,
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
      final result = await _repo.fetchDeliverymanRequests(
        page: state.currentPage + 1,
      );
      state = state.copyWith(
        requests: [...state.requests, ...result.requests],
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        loadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(loadingMore: false, error: e.toString());
    }
  }

  Future<void> changeStatus({
    required int id,
    required String status,
    String? statusNote,
  }) async {
    await _repo.changeDeliverymanRequestStatus(
      id: id,
      status: status,
      statusNote: statusNote,
    );
    final requestId = ++_requestId;
    state = state.copyWith(error: null);
    await _reload(requestId: requestId);
  }
}

final deliverymanRequestsProvider = StateNotifierProvider<
    DeliverymanRequestsNotifier, DeliverymanRequestsState>((ref) {
  return DeliverymanRequestsNotifier(ref.watch(driversRepositoryProvider));
});

/// Top-level tab on drivers screen: `list` | `requests`.
final driversTabProvider = StateProvider<String>((ref) => 'list');
