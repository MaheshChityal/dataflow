/// Generic API response wrapper
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.message = '',
    this.data,
    this.statusCode = 200,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, {T Function(Map<String, dynamic>)? fromData}) {
    return ApiResponse(
      success: json['status'] == 'success' || json['success'] == true,
      message: json['message'] ?? '',
      data: json['data'] != null && fromData != null ? fromData(json['data']) : null,
      statusCode: json['statusCode'] ?? 200,
    );
  }

  factory ApiResponse.error(String message, {int statusCode = 500}) {
    return ApiResponse(success: false, message: message, statusCode: statusCode);
  }
}

/// Login response
class LoginResponse {
  final String token;
  final String userId;
  final String username;
  final String role;

  LoginResponse({required this.token, required this.userId, required this.username, this.role = ''});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? '',
    );
  }
}

/// Template list item
class TemplateListItem {
  final String id;
  final String name;
  final String department;
  final String status;
  final String createdAt;

  TemplateListItem({required this.id, required this.name, required this.department, this.status = '', this.createdAt = ''});

  factory TemplateListItem.fromJson(Map<String, dynamic> json) {
    return TemplateListItem(
      id: json['id'] ?? json['templateId'] ?? '',
      name: json['templateName'] ?? json['name'] ?? '',
      department: json['department'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}
