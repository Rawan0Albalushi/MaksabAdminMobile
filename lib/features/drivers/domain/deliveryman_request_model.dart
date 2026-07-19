class DeliverymanRequestData {
  const DeliverymanRequestData({
    this.brand,
    this.model,
    this.number,
    this.color,
    this.height,
    this.width,
    this.online = false,
    this.typeOfTechnique,
    this.imageUrl,
  });

  final String? brand;
  final String? model;
  final String? number;
  final String? color;
  final String? height;
  final String? width;
  final bool online;
  final String? typeOfTechnique;
  final String? imageUrl;

  String get vehicleSummary {
    final parts = <String>[
      if (brand != null && brand!.trim().isNotEmpty) brand!.trim(),
      if (model != null && model!.trim().isNotEmpty) model!.trim(),
    ];
    return parts.isEmpty ? '—' : parts.join(' ');
  }

  factory DeliverymanRequestData.fromJson(Map<String, dynamic> json) {
    return DeliverymanRequestData(
      brand: json['brand']?.toString(),
      model: json['model']?.toString(),
      number: json['number']?.toString(),
      color: json['color']?.toString(),
      height: json['height']?.toString(),
      width: json['width']?.toString(),
      online: json['online'] == true ||
          json['online'] == 1 ||
          json['online'] == '1',
      typeOfTechnique: json['type_of_technique']?.toString(),
      imageUrl: json['images[0]']?.toString() ??
          (json['images'] is List && (json['images'] as List).isNotEmpty
              ? (json['images'] as List).first?.toString()
              : null),
    );
  }
}

class DeliverymanRequestUser {
  const DeliverymanRequestUser({
    this.firstname,
    this.lastname,
  });

  final String? firstname;
  final String? lastname;

  String get fullName {
    final name = '${firstname ?? ''} ${lastname ?? ''}'.trim();
    return name.isEmpty ? '—' : name;
  }

  factory DeliverymanRequestUser.fromJson(Map<String, dynamic> json) {
    return DeliverymanRequestUser(
      firstname: json['firstname']?.toString(),
      lastname: json['lastname']?.toString(),
    );
  }
}

class DeliverymanRequestModel {
  const DeliverymanRequestModel({
    required this.id,
    required this.status,
    this.deletedAt,
    this.user,
    this.data,
  });

  final int id;
  final String status;
  final String? deletedAt;
  final DeliverymanRequestUser? user;
  final DeliverymanRequestData? data;

  bool get canChangeStatus => deletedAt == null || deletedAt!.isEmpty;

  String get displayName => user?.fullName ?? '#$id';

  DeliverymanRequestModel copyWith({
    int? id,
    String? status,
    String? deletedAt,
    DeliverymanRequestUser? user,
    DeliverymanRequestData? data,
  }) {
    return DeliverymanRequestModel(
      id: id ?? this.id,
      status: status ?? this.status,
      deletedAt: deletedAt ?? this.deletedAt,
      user: user ?? this.user,
      data: data ?? this.data,
    );
  }

  factory DeliverymanRequestModel.fromJson(Map<String, dynamic> json) {
    DeliverymanRequestUser? user;
    final rawModel = json['model'];
    if (rawModel is Map) {
      user = DeliverymanRequestUser.fromJson(
        Map<String, dynamic>.from(rawModel),
      );
    }

    DeliverymanRequestData? data;
    final rawData = json['data'];
    if (rawData is Map) {
      data = DeliverymanRequestData.fromJson(
        Map<String, dynamic>.from(rawData),
      );
    }

    return DeliverymanRequestModel(
      id: _parseInt(json['id']),
      status: json['status']?.toString() ?? 'pending',
      deletedAt: json['deleted_at']?.toString(),
      user: user,
      data: data,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class DeliverymanRequestsPageResult {
  const DeliverymanRequestsPageResult({
    required this.requests,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<DeliverymanRequestModel> requests;
  final int currentPage;
  final int lastPage;
  final int total;
}
