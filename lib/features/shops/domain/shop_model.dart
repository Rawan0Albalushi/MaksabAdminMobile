class ShopModel {
  const ShopModel({
    required this.id,
    required this.uuid,
    required this.status,
    this.name,
    this.description,
    this.address,
    this.phone,
    this.logoImg,
    this.backgroundImg,
    this.open = false,
    this.verify = false,
    this.tax,
    this.sellerName,
    this.sellerPhone,
    this.sellerEmail,
    this.locales = const [],
    this.createdAt,
    this.deletedAt,
    this.statusNote,
    this.ratingAvg,
    this.reviewsCount,
    this.ordersCount,
    this.deliveryTimeFrom,
    this.deliveryTimeTo,
    this.deliveryTimeType,
    this.minAmount,
    this.latitude,
    this.longitude,
  });

  final int id;
  final String uuid;
  final String status;
  final String? name;
  final String? description;
  final String? address;
  final String? phone;
  final String? logoImg;
  final String? backgroundImg;
  final bool open;
  final bool verify;
  final num? tax;
  final String? sellerName;
  final String? sellerPhone;
  final String? sellerEmail;
  final List<String> locales;
  final String? createdAt;
  final String? deletedAt;
  final String? statusNote;
  final num? ratingAvg;
  final int? reviewsCount;
  final int? ordersCount;
  final num? deliveryTimeFrom;
  final num? deliveryTimeTo;
  final String? deliveryTimeType;
  final num? minAmount;
  final double? latitude;
  final double? longitude;

  bool get isDeleted => deletedAt != null && deletedAt!.isNotEmpty;

  ShopModel copyWith({
    int? id,
    String? uuid,
    String? status,
    String? name,
    String? description,
    String? address,
    String? phone,
    String? logoImg,
    String? backgroundImg,
    bool? open,
    bool? verify,
    num? tax,
    String? sellerName,
    String? sellerPhone,
    String? sellerEmail,
    List<String>? locales,
    String? createdAt,
    String? deletedAt,
    String? statusNote,
    num? ratingAvg,
    int? reviewsCount,
    int? ordersCount,
    num? deliveryTimeFrom,
    num? deliveryTimeTo,
    String? deliveryTimeType,
    num? minAmount,
    double? latitude,
    double? longitude,
  }) {
    return ShopModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      status: status ?? this.status,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      logoImg: logoImg ?? this.logoImg,
      backgroundImg: backgroundImg ?? this.backgroundImg,
      open: open ?? this.open,
      verify: verify ?? this.verify,
      tax: tax ?? this.tax,
      sellerName: sellerName ?? this.sellerName,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      sellerEmail: sellerEmail ?? this.sellerEmail,
      locales: locales ?? this.locales,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      statusNote: statusNote ?? this.statusNote,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      ordersCount: ordersCount ?? this.ordersCount,
      deliveryTimeFrom: deliveryTimeFrom ?? this.deliveryTimeFrom,
      deliveryTimeTo: deliveryTimeTo ?? this.deliveryTimeTo,
      deliveryTimeType: deliveryTimeType ?? this.deliveryTimeType,
      minAmount: minAmount ?? this.minAmount,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    double? lat;
    double? lng;
    if (location is Map) {
      final rawLat = location['latitude'];
      final rawLng = location['longitude'];
      if (rawLat != null) lat = double.tryParse(rawLat.toString());
      if (rawLng != null) lng = double.tryParse(rawLng.toString());
    }

    final deliveryTime = json['delivery_time'];
    num? from;
    num? to;
    String? type;
    if (deliveryTime is Map) {
      from = _parseNum(deliveryTime['from']);
      to = _parseNum(deliveryTime['to']);
      type = deliveryTime['type']?.toString();
    }

    return ShopModel(
      id: _parseInt(json['id']),
      uuid: json['uuid']?.toString() ?? '',
      status: json['status']?.toString() ?? 'new',
      name: _title(json),
      description: _description(json),
      address: _address(json),
      phone: json['phone']?.toString(),
      logoImg: json['logo_img']?.toString(),
      backgroundImg: json['background_img']?.toString(),
      open: json['open'] == true || json['open'] == 1 || json['open'] == '1',
      verify:
          json['verify'] == true || json['verify'] == 1 || json['verify'] == '1',
      tax: _parseNum(json['tax']),
      sellerName: _sellerName(json),
      sellerPhone: _sellerField(json, 'phone'),
      sellerEmail: _sellerField(json, 'email'),
      locales: _locales(json),
      createdAt: json['created_at']?.toString(),
      deletedAt: json['deleted_at']?.toString(),
      statusNote: json['status_note']?.toString(),
      ratingAvg: _parseNum(json['rating_avg']) ?? _parseNum(json['avg_rate']),
      reviewsCount: _parseNullableInt(json['reviews_count']),
      ordersCount: _parseNullableInt(json['orders_count']),
      deliveryTimeFrom: from,
      deliveryTimeTo: to,
      deliveryTimeType: type,
      minAmount: _parseNum(json['min_amount']),
      latitude: lat,
      longitude: lng,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static num? _parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    final parsed = num.tryParse(value.toString().trim());
    return parsed;
  }

  static String? _title(Map<String, dynamic> json) {
    final translation = json['translation'];
    if (translation is Map) {
      final title = translation['title']?.toString().trim();
      if (title != null && title.isNotEmpty) return title;
    }

    final translations = json['translations'];
    if (translations is List) {
      for (final item in translations) {
        if (item is Map) {
          final title = item['title']?.toString().trim();
          if (title != null && title.isNotEmpty) return title;
        }
      }
    }

    return null;
  }

  static String? _description(Map<String, dynamic> json) {
    final translation = json['translation'];
    if (translation is Map) {
      final text = translation['description']?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }

  static String? _address(Map<String, dynamic> json) {
    final translation = json['translation'];
    if (translation is Map) {
      final text = translation['address']?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }

  static String? _sellerName(Map<String, dynamic> json) {
    final seller = json['seller'];
    if (seller is! Map) return null;

    final first = seller['firstname']?.toString() ?? '';
    final last = seller['lastname']?.toString() ?? '';
    final name = '$first $last'.trim();
    return name.isEmpty ? null : name;
  }

  static String? _sellerField(Map<String, dynamic> json, String field) {
    final seller = json['seller'];
    if (seller is! Map) return null;
    final value = seller[field]?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  static List<String> _locales(Map<String, dynamic> json) {
    final raw = json['locales'];
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }
}

class ShopsPageResult {
  const ShopsPageResult({
    required this.shops,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<ShopModel> shops;
  final int currentPage;
  final int lastPage;
  final int total;
}
