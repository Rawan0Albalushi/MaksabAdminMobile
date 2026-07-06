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
    this.shopLogo,
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
  final String? shopLogo;
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

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final detailsRaw = json['details'];
    final deliveryManRaw = json['deliveryman'];

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
      shopName: _readShopName(json['shop']),
      shopLogo: _readShopLogo(json['shop']),
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
      deliveryMan: deliveryManRaw is Map
          ? OrderDeliveryPerson.fromJson(
              Map<String, dynamic>.from(deliveryManRaw),
            )
          : null,
      otp: json['otp']?.toString(),
    );
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

  static String? _readShopName(dynamic shop) {
    if (shop is! Map) return null;
    final translation = shop['translation'];
    if (translation is Map && translation['title'] != null) {
      return translation['title'].toString();
    }
    if (shop['title'] != null) return shop['title'].toString();
    return null;
  }

  static String? _readShopLogo(dynamic shop) {
    if (shop is! Map) return null;
    return shop['logo_img']?.toString();
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
