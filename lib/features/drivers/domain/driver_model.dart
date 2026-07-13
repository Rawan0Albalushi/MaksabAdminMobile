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
      ordersCount: _parseNullableInt(json['delivery_man_orders_count']) ??
          _parseNullableInt(json['orders_count']),
      setting: setting,
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
