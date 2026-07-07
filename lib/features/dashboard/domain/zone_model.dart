class ZoneModel {
  const ZoneModel({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory ZoneModel.fromJson(Map<String, dynamic> json) {
    return ZoneModel(
      id: _parseId(json['id'] ?? json['zone_id']),
      name: _readName(json),
    );
  }

  static int _parseId(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  static String _readName(Map<String, dynamic> json) {
    final translations = json['translations'];
    if (translations is List) {
      for (final item in translations) {
        if (item is! Map) continue;
        final title = item['title']?.toString().trim();
        if (title != null && title.isNotEmpty) return title;
      }
    }
    if (translations is Map) {
      for (final item in translations.values) {
        if (item is! Map) continue;
        final title = item['title']?.toString().trim();
        if (title != null && title.isNotEmpty) return title;
      }
    }

    final translation = json['translation'];
    if (translation is Map && translation['title'] != null) {
      return translation['title'].toString();
    }

    for (final key in ['title', 'name']) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }

    final id = _parseId(json['id'] ?? json['zone_id']);
    return id > 0 ? '#$id' : '';
  }
}
