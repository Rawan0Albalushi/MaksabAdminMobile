class OrderLineItem {
  const OrderLineItem({
    required this.id,
    required this.quantity,
    this.totalPrice,
    this.note,
    this.productName,
    this.productImage,
    this.addons = const [],
  });

  final int id;
  final int quantity;
  final num? totalPrice;
  final String? note;
  final String? productName;
  final String? productImage;
  final List<OrderLineItem> addons;

  factory OrderLineItem.fromJson(Map<String, dynamic> json) {
    final stock = json['stock'];
    final product = stock is Map ? stock['product'] : null;
    final addonsRaw = json['addons'];

    return OrderLineItem(
      id: json['id'] as int? ?? 0,
      quantity: json['quantity'] as int? ?? 1,
      totalPrice: json['total_price'] as num?,
      note: json['note']?.toString(),
      productName: _readProductName(product),
      productImage: _readProductImage(product),
      addons: addonsRaw is List
          ? addonsRaw
              .whereType<Map>()
              .map((e) => OrderLineItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

  static String? _readProductName(dynamic product) {
    if (product is! Map) return null;
    final translation = product['translation'];
    if (translation is Map && translation['title'] != null) {
      return translation['title'].toString();
    }
    return null;
  }

  static String? _readProductImage(dynamic product) {
    if (product is! Map) return null;
    return product['img']?.toString();
  }
}

class OrderDeliveryPerson {
  const OrderDeliveryPerson({required this.name, this.phone});

  final String name;
  final String? phone;

  factory OrderDeliveryPerson.fromJson(Map<String, dynamic> json) {
    final first = json['firstname']?.toString() ?? '';
    final last = json['lastname']?.toString() ?? '';
    final name = '$first $last'.trim();
    return OrderDeliveryPerson(
      name: name.isEmpty ? '—' : name,
      phone: json['phone']?.toString(),
    );
  }
}
