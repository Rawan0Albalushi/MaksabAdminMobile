import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardDateFilter {
  const DashboardDateFilter({this.dateFrom, this.dateTo});

  final DateTime? dateFrom;
  final DateTime? dateTo;

  bool get isActive => dateFrom != null && dateTo != null;

  DashboardDateFilter copyWith({
    DateTime? dateFrom,
    DateTime? dateTo,
    bool clearFrom = false,
    bool clearTo = false,
  }) {
    return DashboardDateFilter(
      dateFrom: clearFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearTo ? null : (dateTo ?? this.dateTo),
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
