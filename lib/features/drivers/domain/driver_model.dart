class DriverSettingModel {
  const DriverSettingModel({
    this.id,
    this.typeOfTechnique,
    this.brand,
    this.model,
    this.number,
    this.color,
    this.online = false,
  });

  final int? id;
  final String? typeOfTechnique;
  final String? brand;
  final String? model;
  final String? number;
  final String? color;
  final bool online;

  factory DriverSettingModel.fromJson(Map<String, dynamic> json) {
    return DriverSettingModel(
      id: _parseNullableInt(json['id']),
      typeOfTechnique: json['type_of_technique']?.toString(),
      brand: json['brand']?.toString(),
      model: json['model']?.toString(),
      number: json['number']?.toString(),
      color: json['color']?.toString(),
      online: json['online'] == true ||
          json['online'] == 1 ||
          json['online'] == '1',
    );
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

/// Delivery request / order assigned to a deliveryman (`deliveryman_orders`).
class DriverOrderModel {
  const DriverOrderModel({
    required this.id,
    required this.status,
    this.totalPrice,
    this.username,
    this.address,
    this.deliveryFee,
    this.deliveryDate,
    this.deliveryTime,
    this.shopName,
    this.customerName,
    this.createdAt,
  });

  final int id;
  final String status;
  final num? totalPrice;
  final String? username;
  final dynamic address;
  final num? deliveryFee;
  final String? deliveryDate;
  final String? deliveryTime;
  final String? shopName;
  final String? customerName;
  final String? createdAt;

  String get formattedAddress {
    if (address == null) return '—';
    if (address is String) {
      final text = address.toString().trim();
      return text.isEmpty ? '—' : text;
    }
    if (address is Map) {
      final map = Map<String, dynamic>.from(address as Map);
      final text = map['address']?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return '—';
  }

  factory DriverOrderModel.fromJson(Map<String, dynamic> json) {
    String? shopName;
    final shop = json['shop'];
    if (shop is Map) {
      final translation = shop['translation'];
      if (translation is Map) {
        shopName = translation['title']?.toString();
      }
      shopName ??= shop['title']?.toString() ?? shop['name']?.toString();
    }

    String? customerName;
    final user = json['user'];
    if (user is Map) {
      final name =
          '${user['firstname'] ?? ''} ${user['lastname'] ?? ''}'.trim();
      if (name.isNotEmpty) customerName = name;
    }
    customerName ??= json['username']?.toString();

    return DriverOrderModel(
      id: _parseInt(json['id']),
      status: json['status']?.toString() ?? 'new',
      totalPrice: _parseNum(json['total_price']),
      username: json['username']?.toString(),
      address: json['address'] ?? json['location'],
      deliveryFee: _parseNum(json['delivery_fee']),
      deliveryDate: json['delivery_date']?.toString(),
      deliveryTime: json['delivery_time']?.toString(),
      shopName: shopName,
      customerName: customerName,
      createdAt: json['created_at']?.toString(),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static num? _parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    return num.tryParse(value.toString().trim());
  }
}

class DriverModel {
  const DriverModel({
    required this.id,
    required this.uuid,
    this.firstname,
    this.lastname,
    this.phone,
    this.email,
    this.img,
    this.active = false,
    this.createdAt,
    this.ratingAvg,
    this.ordersCount,
    this.setting,
    this.orders = const [],
  });

  final int id;
  final String uuid;
  final String? firstname;
  final String? lastname;
  final String? phone;
  final String? email;
  final String? img;
  final bool active;
  final String? createdAt;
  final num? ratingAvg;
  final int? ordersCount;
  final DriverSettingModel? setting;
  final List<DriverOrderModel> orders;

  String get fullName {
    final name = '${firstname ?? ''} ${lastname ?? ''}'.trim();
    if (name.isNotEmpty) return name;
    if (phone != null && phone!.isNotEmpty) return phone!;
    return '#$id';
  }

  DriverModel copyWith({
    int? id,
    String? uuid,
    String? firstname,
    String? lastname,
    String? phone,
    String? email,
    String? img,
    bool? active,
    String? createdAt,
    num? ratingAvg,
    int? ordersCount,
    DriverSettingModel? setting,
    List<DriverOrderModel>? orders,
  }) {
    return DriverModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      firstname: firstname ?? this.firstname,
      lastname: lastname ?? this.lastname,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      img: img ?? this.img,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      ordersCount: ordersCount ?? this.ordersCount,
      setting: setting ?? this.setting,
      orders: orders ?? this.orders,
    );
  }

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    DriverSettingModel? setting;
    final rawSetting = json['delivery_man_setting'];
    if (rawSetting is Map) {
      setting = DriverSettingModel.fromJson(
        Map<String, dynamic>.from(rawSetting),
      );
    }

    final rawOrders = json['deliveryman_orders'] ?? json['delivery_man_orders'];
    final orders = rawOrders is List
        ? rawOrders
            .whereType<Map>()
            .map((e) => DriverOrderModel.fromJson(Map<String, dynamic>.from(e)))
            .where((o) => o.id > 0)
            .toList()
        : const <DriverOrderModel>[];

    final ordersCount = _parseNullableInt(json['delivery_man_orders_count']) ??
        _parseNullableInt(json['orders_count']) ??
        (orders.isNotEmpty ? orders.length : null);

    return DriverModel(
      id: _parseInt(json['id']),
      uuid: json['uuid']?.toString() ?? '',
      firstname: json['firstname']?.toString(),
      lastname: json['lastname']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      img: json['img']?.toString(),
      active: json['active'] == true ||
          json['active'] == 1 ||
          json['active'] == '1',
      createdAt: json['created_at']?.toString() ??
          json['registered_at']?.toString(),
      ratingAvg: _parseNum(json['assign_reviews_avg_rating']) ??
          _parseNum(json['reviews_avg_rating']),
      ordersCount: ordersCount,
      setting: setting,
      orders: orders,
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
    return num.tryParse(value.toString().trim());
  }
}

class DriversPageResult {
  const DriversPageResult({
    required this.drivers,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<DriverModel> drivers;
  final int currentPage;
  final int lastPage;
  final int total;
}
