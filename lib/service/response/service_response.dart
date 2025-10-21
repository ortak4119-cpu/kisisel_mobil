class ServiceResponse<T> {
  final int statusCode;
  final T? data;
  final String? message;
  final Map<String, dynamic>? errors;

  ServiceResponse({
    required this.statusCode,
    this.data,
    this.message,
    this.errors,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  bool get isError => !isSuccess;

  String get errorMessage {
    if (message != null && message!.isNotEmpty) {
      return message!;
    }

    if (errors != null && errors!.isNotEmpty) {
      // Validation hatalarını birleştir
      final errorList = <String>[];
      errors!.forEach((key, value) {
        if (value is List) {
          errorList.addAll(value.cast<String>());
        } else if (value is String) {
          errorList.add(value);
        }
      });
      return errorList.join(', ');
    }

    return 'Bir hata oluştu';
  }

  factory ServiceResponse.fromJson(
      Map<String, dynamic> json,
      T Function(dynamic)? fromJsonT,
      ) {
    return ServiceResponse<T>(
      statusCode: 200, // HTTP client tarafından set edilecek
      data: fromJsonT != null && json['data'] != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      message: json['message'] as String?,
      errors: json['errors'] as Map<String, dynamic>?,
    );
  }

  factory ServiceResponse.error({
    required int statusCode,
    String? message,
    Map<String, dynamic>? errors,
  }) {
    return ServiceResponse<T>(
      statusCode: statusCode,
      message: message,
      errors: errors,
    );
  }

  factory ServiceResponse.success({
    required T data,
    String? message,
    int statusCode = 200,
  }) {
    return ServiceResponse<T>(
      statusCode: statusCode,
      data: data,
      message: message,
    );
  }
}

// Paginated response için özel class
class PaginatedResponse<T> {
  final List<T> data;
  final PaginationMeta meta;

  PaginatedResponse({
    required this.data,
    required this.meta,
  });

  factory PaginatedResponse.fromJson(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic>) fromJsonT,
      ) {
    return PaginatedResponse<T>(
      data: (json['data'] as List)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      meta: PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }
}

class PaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int from;
  final int to;

  PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.from,
    required this.to,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['current_page'] as int,
      lastPage: json['last_page'] as int,
      perPage: json['per_page'] as int,
      total: json['total'] as int,
      from: json['from'] as int,
      to: json['to'] as int,
    );
  }

  bool get hasNextPage => currentPage < lastPage;
  bool get hasPreviousPage => currentPage > 1;
}