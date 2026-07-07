import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardDateFilter {
  const DashboardDateFilter({
    this.dateFrom,
    this.dateTo,
    this.zoneId,
  });

  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int? zoneId;

  bool get hasDateFilter => dateFrom != null && dateTo != null;

  bool get hasZoneFilter => zoneId != null;

  bool get isActive => hasDateFilter || hasZoneFilter;

  DashboardDateFilter copyWith({
    DateTime? dateFrom,
    DateTime? dateTo,
    int? zoneId,
    bool clearFrom = false,
    bool clearTo = false,
    bool clearZone = false,
  }) {
    return DashboardDateFilter(
      dateFrom: clearFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearTo ? null : (dateTo ?? this.dateTo),
      zoneId: clearZone ? null : (zoneId ?? this.zoneId),
    );
  }
}

class DashboardDateFilterNotifier extends StateNotifier<DashboardDateFilter> {
  DashboardDateFilterNotifier() : super(const DashboardDateFilter());

  void setDateFrom(DateTime date) {
    final normalized = _dateOnly(date);
    var next = state.copyWith(dateFrom: normalized);
    if (next.dateTo != null && normalized.isAfter(next.dateTo!)) {
      next = next.copyWith(dateTo: normalized);
    }
    state = next;
  }

  void setDateTo(DateTime date) {
    final normalized = _dateOnly(date);
    var next = state.copyWith(dateTo: normalized);
    if (next.dateFrom != null && normalized.isBefore(next.dateFrom!)) {
      next = next.copyWith(dateFrom: normalized);
    }
    state = next;
  }

  void setZoneId(int? zoneId) {
    if (zoneId == state.zoneId) return;
    state = state.copyWith(zoneId: zoneId, clearZone: zoneId == null);
  }

  void clear() {
    state = const DashboardDateFilter();
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

final dashboardDateFilterProvider =
    StateNotifierProvider<DashboardDateFilterNotifier, DashboardDateFilter>(
  (ref) => DashboardDateFilterNotifier(),
);
