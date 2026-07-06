class ApiException implements Exception {
  ApiException({required this.message, this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => message;
}

class ApiResponse<T> {
  ApiResponse({
    required this.status,
    this.message,
    this.data,
    this.statusCode,
  });

  final bool status;
  final String? message;
  final T? data;
  final String? statusCode;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic raw)? parser,
  ) {
    return ApiResponse(
      status: json['status'] == true,
      message: json['message']?.toString(),
      statusCode: json['statusCode']?.toString(),
      data: parser != null && json['data'] != null
          ? parser(json['data'])
          : json['data'] as T?,
    );
  }
}
