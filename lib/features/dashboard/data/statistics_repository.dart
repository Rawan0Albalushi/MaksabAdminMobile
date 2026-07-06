import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../core/utils/api_date.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../orders/data/orders_repository.dart';
import '../../orders/presentation/providers/orders_provider.dart';
import '../presentation/providers/dashboard_date_filter_provider.dart';

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return StatisticsRepository(
    ref.watch(ordersRepositoryProvider),
    ref.watch(dioProvider),
  );
});

class DashboardStats {
  const DashboardStats({
    this.total = 0,
    this.newCount = 0,
    this.accepted = 0,
    this.cooking = 0,
    this.ready = 0,
    this.onTheWay = 0,
    this.delivered = 0,
    this.canceled = 0,
  });

  final int total;
  final int newCount;
  final int accepted;
  final int cooking;
  final int ready;
  final int onTheWay;
  final int delivered;
  final int canceled;

  static int toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  static Map<String, dynamic> normalizeMap(dynamic raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return const {};
  }

  factory DashboardStats.fromStatistic(Map<String, dynamic> stat) {
    if (stat.isEmpty) {
      return const DashboardStats();
    }

    final byStatus = stat['by_status'];
    if (byStatus is List && byStatus.isNotEmpty) {
      return DashboardStats.fromByStatus(
        byStatus,
        total: toInt(stat['orders_count'] ?? stat['total'] ?? stat['count']),
      );
    }

    int read(String primary, [String? fallback]) {
      final value = stat[primary] ?? (fallback != null ? stat[fallback] : null);
      return toInt(value);
    }

    return DashboardStats(
      total: read('total', 'orders_count') > 0
          ? read('total', 'orders_count')
          : read('count'),
      newCount: read('new_orders_count', 'new'),
      accepted: read('accepted_orders_count', 'accepted'),
      cooking: read('cooking_orders_count', 'cooking'),
      ready: read('ready_orders_count', 'ready'),
      onTheWay: read('on_a_way_orders_count', 'on_a_way'),
      delivered: read('delivered_orders_count', 'delivered'),
      canceled: read('cancel_orders_count', 'canceled'),
    );
  }

  factory DashboardStats.fromByStatus(List<dynamic> byStatus, {int? total}) {
    final counts = <String, int>{};
    for (final item in byStatus) {
      if (item is! Map) continue;
      final status = item['status']?.toString();
      if (status == null || status.isEmpty) continue;
      counts[status] = toInt(item['count']);
    }

    return DashboardStats(
      total: total ?? counts.values.fold<int>(0, (sum, value) => sum + value),
      newCount: counts['new'] ?? 0,
      accepted: counts['accepted'] ?? 0,
      cooking: counts['cooking'] ?? 0,
      ready: counts['ready'] ?? 0,
      onTheWay: counts['on_a_way'] ?? 0,
      delivered: counts['delivered'] ?? 0,
      canceled: counts['canceled'] ?? 0,
    );
  }

  bool get hasCounts =>
      total > 0 ||
      newCount > 0 ||
      accepted > 0 ||
      cooking > 0 ||
      ready > 0 ||
      onTheWay > 0 ||
      delivered > 0 ||
      canceled > 0;

  DashboardStats mergeWith(DashboardStats other) {
    int pick(int current, int fallback) => current > 0 ? current : fallback;

    return DashboardStats(
      total: pick(total, other.total),
      newCount: pick(newCount, other.newCount),
      accepted: pick(accepted, other.accepted),
      cooking: pick(cooking, other.cooking),
      ready: pick(ready, other.ready),
      onTheWay: pick(onTheWay, other.onTheWay),
      delivered: pick(delivered, other.delivered),
      canceled: pick(canceled, other.canceled),
    );
  }
}

DashboardStats statsFromOrdersState(OrdersState orders) {
  final stats = DashboardStats.fromStatistic(orders.statistic);
  if (stats.hasCounts) {
    return stats;
  }
  if (orders.total > 0) {
    return DashboardStats(total: orders.total).mergeWith(stats);
  }
  return stats;
}

class StatisticsRepository {
  StatisticsRepository(this._ordersRepository, this._dio);

  final OrdersRepository _ordersRepository;
  final Dio _dio;

  Future<DashboardStats> fetchFiltered({
    required DateTime dateFrom,
    required DateTime dateTo,
  }) async {
    try {
      return await _fetchFromOverview(dateFrom, dateTo);
    } on DioException {
      return _fetchFromPaginate(dateFrom, dateTo);
    }
  }

  Future<DashboardStats> _fetchFromOverview(
    DateTime dateFrom,
    DateTime dateTo,
  ) async {
    final json = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.adminOrdersOverview,
      queryParameters: {
        'date_from': ApiDate.format(dateFrom),
        'date_to': ApiDate.format(dateTo),
      },
    );

    final response = ApiResponse<Map<String, dynamic>>.fromJson(
      json.data ?? {},
      (raw) => DashboardStats.normalizeMap(raw),
    );

    if (!response.status || response.data == null) {
      throw Exception(response.message ?? 'Failed to load statistics');
    }

    final data = response.data!;
    final summary = DashboardStats.normalizeMap(data['summary']);
    final byStatus = data['by_status'] as List<dynamic>? ?? const [];

    return DashboardStats.fromByStatus(
      byStatus,
      total: DashboardStats.toInt(summary['orders_count']),
    );
  }

  Future<DashboardStats> _fetchFromPaginate(
    DateTime dateFrom,
    DateTime dateTo,
  ) async {
    final ordersResult = await _ordersRepository.fetchOrders(
      page: 1,
      perPage: 15,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );

    final stats = DashboardStats.fromStatistic(ordersResult.statistic);
    if (stats.hasCounts) {
      return stats;
    }

    if (ordersResult.total > 0) {
      return DashboardStats(total: ordersResult.total).mergeWith(stats);
    }

    return stats;
  }
}

final filteredDashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final filter = ref.watch(dashboardDateFilterProvider);
  if (!filter.isActive) {
    return const DashboardStats();
  }

  return ref.read(statisticsRepositoryProvider).fetchFiltered(
        dateFrom: filter.dateFrom!,
        dateTo: filter.dateTo!,
      );
});

final dashboardStatsProvider = Provider<AsyncValue<DashboardStats>>((ref) {
  final auth = ref.watch(authProvider);
  if (auth.loading || !auth.isAuthenticated) {
    return const AsyncValue.loading();
  }

  final filter = ref.watch(dashboardDateFilterProvider);

  if (filter.isActive) {
    return ref.watch(filteredDashboardStatsProvider);
  }

  final orders = ref.watch(ordersProvider);
  if (orders.loading) {
    return const AsyncValue.loading();
  }
  if (orders.error != null) {
    return AsyncValue.error(orders.error!, StackTrace.current);
  }

  return AsyncValue.data(statsFromOrdersState(orders));
});
