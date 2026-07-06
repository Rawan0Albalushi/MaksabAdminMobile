import '../../orders/domain/order_model.dart';

class RefundGallery {
  const RefundGallery({this.id, this.path});

  final int? id;
  final String? path;

  factory RefundGallery.fromJson(Map<String, dynamic> json) {
    return RefundGallery(
      id: json['id'] as int?,
      path: json['path']?.toString(),
    );
  }
}

class RefundModel {
  const RefundModel({
    required this.id,
    required this.status,
    this.cause,
    this.answer,
    this.createdAt,
    this.updatedAt,
    this.order,
    this.galleries = const [],
  });

  final int id;
  final String status;
  final String? cause;
  final String? answer;
  final String? createdAt;
  final String? updatedAt;
  final OrderModel? order;
  final List<RefundGallery> galleries;

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isCanceled => status == 'canceled';

  String? get customerName => order?.username;
  String? get shopName => order?.shopName;
  int? get orderId => order?.id;

  factory RefundModel.fromJson(Map<String, dynamic> json) {
    final orderRaw = json['order'];
    final galleriesRaw = json['galleries'];

    return RefundModel(
      id: json['id'] as int,
      status: json['status']?.toString() ?? 'pending',
      cause: json['cause']?.toString(),
      answer: json['answer']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      order: orderRaw is Map
          ? OrderModel.fromJson(Map<String, dynamic>.from(orderRaw))
          : null,
      galleries: galleriesRaw is List
          ? galleriesRaw
              .whereType<Map>()
              .map((e) => RefundGallery.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

class RefundsPageResult {
  const RefundsPageResult({
    required this.refunds,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<RefundModel> refunds;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
}
