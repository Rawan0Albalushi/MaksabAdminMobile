class PaginateResponse {
  const PaginateResponse({
    required this.items,
    required this.statistic,
    required this.meta,
  });

  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> statistic;
  final Map<String, dynamic> meta;

  static List<Map<String, dynamic>> extractItems(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (raw is Map) {
      final nested = raw['data'];
      if (nested is List) {
        return nested
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    return const [];
  }

  static Map<String, dynamic> extractMap(dynamic raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return const {};
  }

  static int parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  factory PaginateResponse.fromData(Map<String, dynamic> data) {
    return PaginateResponse(
      items: extractItems(data['orders']),
      statistic: extractMap(data['statistic']),
      meta: extractMap(data['meta']),
    );
  }
}
