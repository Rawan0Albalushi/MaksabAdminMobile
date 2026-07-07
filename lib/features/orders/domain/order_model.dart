import 'order_detail_models.dart';

class OrderModel {
  const OrderModel({
    required this.id,
    required this.status,
    this.totalPrice,
    this.username,
    this.phone,
    this.address,
    this.deliveryType,
    this.note,
    this.createdAt,
    this.shopName,
    this.zoneName,
    this.shopLogo,
    this.shopPhone,
    this.shopId,
    this.shopUuid,
    this.orderDetailsCount,
    this.items = const [],
    this.deliveryFee,
    this.tax,
    this.serviceFee,
    this.couponPrice,
    this.totalDiscount,
    this.deliveryDate,
    this.deliveryTime,
    this.deliveryMan,
    this.otp,
  });

  final int id;
  final String status;
  final num? totalPrice;
  final String? username;
  final String? phone;
  final dynamic address;
  final String? deliveryType;
  final String? note;
  final String? createdAt;
  final String? shopName;
  final String? zoneName;
  final String? shopLogo;
  final String? shopPhone;
  final int? shopId;
  final String? shopUuid;
  final int? orderDetailsCount;
  final List<OrderLineItem> items;
  final num? deliveryFee;
  final num? tax;
  final num? serviceFee;
  final num? couponPrice;
  final num? totalDiscount;
  final String? deliveryDate;
  final String? deliveryTime;
  final OrderDeliveryPerson? deliveryMan;
  final String? otp;

  bool get isPickup => deliveryType == 'pickup';

  String? get shopNumber {
    final phone = shopPhone?.trim();
    if (phone != null && phone.isNotEmpty) return phone;
    if (shopId != null) return shopId.toString();
    return null;
  }

  String get formattedAddress {
    if (address == null) return '—';
    if (address is String) {
      final text = address.toString().trim();
      return text.isEmpty ? '—' : text;
    }
    if (address is Map) {
      final map = Map<String, dynamic>.from(address as Map);
      final parts = <String>[
        if (map['address'] != null) map['address'].toString(),
        if (map['house'] != null) map['house'].toString(),
        if (map['floor'] != null) map['floor'].toString(),
        if (map['office'] != null) map['office'].toString(),
      ].where((p) => p.trim().isNotEmpty).toList();
      return parts.isEmpty ? '—' : parts.join(', ');
    }
    return '—';
  }

  num get itemsSubtotal {
    if (items.isEmpty) return totalPrice ?? 0;
    return items.fold<num>(
      0,
      (sum, item) => sum + (item.totalPrice ?? 0),
    );
  }

  OrderModel copyWith({
    String? shopPhone,
    String? shopName,
    String? shopLogo,
  }) {
    return OrderModel(
      id: id,
      status: status,
      totalPrice: totalPrice,
      username: username,
      phone: phone,
      address: address,
      deliveryType: deliveryType,
      note: note,
      createdAt: createdAt,
      shopName: shopName ?? this.shopName,
      zoneName: zoneName,
      shopLogo: shopLogo ?? this.shopLogo,
      shopPhone: shopPhone ?? this.shopPhone,
      shopId: shopId,
      shopUuid: shopUuid,
      orderDetailsCount: orderDetailsCount,
      items: items,
      deliveryFee: deliveryFee,
      tax: tax,
      serviceFee: serviceFee,
      couponPrice: couponPrice,
      totalDiscount: totalDiscount,
      deliveryDate: deliveryDate,
      deliveryTime: deliveryTime,
      deliveryMan: deliveryMan,
      otp: otp,
    );
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final detailsRaw = json['details'];
    final shop = _resolveShop(json);

    return OrderModel(
      id: json['id'] as int,
      status: json['status']?.toString() ?? 'new',
      totalPrice: json['total_price'] as num?,
      username: _readCustomerName(json),
      phone: _readPhone(json),
      address: json['address'],
      deliveryType: json['delivery_type']?.toString(),
      note: json['note']?.toString(),
      createdAt: json['created_at']?.toString(),
      shopName: _readShopName(shop),
      zoneName: _readZoneName(json, shop),
      shopLogo: _readShopLogo(shop),
      shopPhone: _readShopPhone(shop),
      shopId: _readShopId(json, shop),
      shopUuid: _readShopUuid(shop),
      orderDetailsCount: json['order_details_count'] as int?,
      items: detailsRaw is List
          ? detailsRaw
              .whereType<Map>()
              .map((e) => OrderLineItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      deliveryFee: json['delivery_fee'] as num?,
      tax: json['tax'] as num?,
      serviceFee: json['service_fee'] as num?,
      couponPrice: json['coupon_price'] as num?,
      totalDiscount: json['total_discount'] as num?,
      deliveryDate: json['delivery_date']?.toString(),
      deliveryTime: json['delivery_time']?.toString(),
      deliveryMan: _readDeliveryMan(json),
      otp: json['otp']?.toString(),
    );
  }

  static OrderDeliveryPerson? _readDeliveryMan(Map<String, dynamic> json) {
    for (final key in ['deliveryman', 'delivery_man', 'deliveryMan']) {
      final raw = json[key];
      if (raw is Map) {
        return OrderDeliveryPerson.fromJson(
          Map<String, dynamic>.from(raw),
        );
      }
    }
    return null;
  }

  static String? _readCustomerName(Map<String, dynamic> json) {
    final user = json['user'];
    if (user is Map) {
      final first = user['firstname']?.toString() ?? '';
      final last = user['lastname']?.toString() ?? '';
      final name = '$first $last'.trim();
      if (name.isNotEmpty) return name;
    }

    final username = json['username']?.toString().trim();
    if (username != null && username.isNotEmpty) return username;

    return null;
  }

  static String? _readPhone(Map<String, dynamic> json) {
    final phone = json['phone']?.toString().trim();
    if (phone != null && phone.isNotEmpty) return phone;

    final user = json['user'];
    if (user is Map) {
      final userPhone = user['phone']?.toString().trim();
      if (userPhone != null && userPhone.isNotEmpty) return userPhone;
    }

    return null;
  }

  static dynamic _resolveShop(Map<String, dynamic> json) {
    for (final key in ['shop', 'restaurant', 'seller']) {
      final value = json[key];
      if (value is Map) return value;
    }
    return null;
  }

  static String? _readShopName(dynamic shop) => _readLocalizedTitle(shop);

  static String? _readZoneName(Map<String, dynamic> json, dynamic shop) {
    for (final zone in [
      json['zone'],
      shop is Map ? shop['zone'] : null,
    ]) {
      final name = _readLocalizedTitle(zone);
      if (name != null) return name;
    }
    return null;
  }

  static String? _readLocalizedTitle(dynamic value) {
    if (value is! Map) return null;
    final map = Map<String, dynamic>.from(value);
    final translation = map['translation'];
    if (translation is Map && translation['title'] != null) {
      return translation['title'].toString();
    }
    if (map['title'] != null) return map['title'].toString();
    if (map['name'] != null) return map['name'].toString();
    return null;
  }

  static String? _readShopLogo(dynamic shop) {
    if (shop is! Map) return null;
    return shop['logo_img']?.toString();
  }

  static String? _readShopPhone(dynamic shop) {
    if (shop is! Map) return null;

    final phone = shop['phone']?.toString().trim();
    if (phone != null && phone.isNotEmpty) return phone;

    final seller = shop['seller'];
    if (seller is Map) {
      final sellerPhone = seller['phone']?.toString().trim();
      if (sellerPhone != null && sellerPhone.isNotEmpty) return sellerPhone;
    }

    return null;
  }

  static int? _readShopId(Map<String, dynamic> json, dynamic shop) {
    for (final value in [
      json['shop_id'],
      shop is Map ? shop['id'] : null,
    ]) {
      if (value is int) return value;
      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return null;
  }

  static String? _readShopUuid(dynamic shop) {
    if (shop is! Map) return null;
    final uuid = shop['uuid']?.toString().trim();
    if (uuid != null && uuid.isNotEmpty) return uuid;
    return null;
  }
}

class OrdersPageResult {
  const OrdersPageResult({
    required this.orders,
    required this.statistic,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<OrderModel> orders;
  final Map<String, dynamic> statistic;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
}
