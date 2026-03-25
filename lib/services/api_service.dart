import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_response.dart';

/// Base HTTP service — all API calls go through here
class ApiService {
  final http.Client _client = http.Client();
  String? _authToken;

  void setToken(String? token) => _authToken = token;
  String? get token => _authToken;
  bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;

  Map<String, String> get _headers => ApiConfig.headers(_authToken);

  Uri _uri(String endpoint) => Uri.parse('${ApiConfig.baseUrl}$endpoint');

  // ── GET ──
  Future<ApiResponse<T>> get<T>(String endpoint, {T Function(Map<String, dynamic>)? fromData}) async {
    try {
      debugPrint('[API GET] ${_uri(endpoint)}');
      final response = await _client.get(_uri(endpoint), headers: _headers)
          .timeout(ApiConfig.connectTimeout);
      return _handleResponse(response, fromData: fromData);
    } catch (e) {
      debugPrint('[API ERROR] GET $endpoint: $e');
      return ApiResponse.error('Network error: $e');
    }
  }

  // ── POST ──
  Future<ApiResponse<T>> post<T>(String endpoint, Map<String, dynamic> body, {T Function(Map<String, dynamic>)? fromData}) async {
    try {
      debugPrint('[API POST] ${_uri(endpoint)}');
      debugPrint('[API BODY] ${const JsonEncoder.withIndent('  ').convert(body)}');
      final response = await _client.post(_uri(endpoint), headers: _headers, body: jsonEncode(body))
          .timeout(ApiConfig.connectTimeout);
      return _handleResponse(response, fromData: fromData);
    } catch (e) {
      debugPrint('[API ERROR] POST $endpoint: $e');
      return ApiResponse.error('Network error: $e');
    }
  }

  // ── PUT ──
  Future<ApiResponse<T>> put<T>(String endpoint, Map<String, dynamic> body, {T Function(Map<String, dynamic>)? fromData}) async {
    try {
      debugPrint('[API PUT] ${_uri(endpoint)}');
      final response = await _client.put(_uri(endpoint), headers: _headers, body: jsonEncode(body))
          .timeout(ApiConfig.connectTimeout);
      return _handleResponse(response, fromData: fromData);
    } catch (e) {
      debugPrint('[API ERROR] PUT $endpoint: $e');
      return ApiResponse.error('Network error: $e');
    }
  }

  // ── DELETE ──
  Future<ApiResponse<T>> delete<T>(String endpoint, {T Function(Map<String, dynamic>)? fromData}) async {
    try {
      debugPrint('[API DELETE] ${_uri(endpoint)}');
      final response = await _client.delete(_uri(endpoint), headers: _headers)
          .timeout(ApiConfig.connectTimeout);
      return _handleResponse(response, fromData: fromData);
    } catch (e) {
      debugPrint('[API ERROR] DELETE $endpoint: $e');
      return ApiResponse.error('Network error: $e');
    }
  }

  // ── Multipart (file upload) ──
  Future<ApiResponse<T>> uploadMultipart<T>(
    String endpoint, {
    required Map<String, String> fields,
    required Map<String, List<int>> files, // {fieldName: bytes}
    required Map<String, String> fileNames, // {fieldName: fileName}
    T Function(Map<String, dynamic>)? fromData,
  }) async {
    try {
      debugPrint('[API UPLOAD] ${_uri(endpoint)} fields=${fields.keys} files=${fileNames.keys}');
      final request = http.MultipartRequest('POST', _uri(endpoint));
      request.headers.addAll({'Accept': 'application/json', if (_authToken != null) 'Authorization': 'Bearer $_authToken'});
      request.fields.addAll(fields);

      for (final entry in files.entries) {
        request.files.add(http.MultipartFile.fromBytes(
          entry.key,
          entry.value,
          filename: fileNames[entry.key] ?? 'file',
        ));
      }

      final streamed = await _client.send(request).timeout(ApiConfig.connectTimeout);
      final response = await http.Response.fromStream(streamed);
      return _handleResponse(response, fromData: fromData);
    } catch (e) {
      debugPrint('[API ERROR] UPLOAD $endpoint: $e');
      return ApiResponse.error('Upload error: $e');
    }
  }

  // ── Response handler ──
  ApiResponse<T> _handleResponse<T>(http.Response response, {T Function(Map<String, dynamic>)? fromData}) {
    debugPrint('[API RESPONSE] ${response.statusCode}');
    try {
      final json = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.fromJson(json is Map<String, dynamic> ? json : {'status': 'success', 'data': json}, fromData: fromData);
      }
      return ApiResponse.error(json['message'] ?? 'Request failed', statusCode: response.statusCode);
    } catch (e) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(success: true, message: 'Success', statusCode: response.statusCode);
      }
      return ApiResponse.error('Parse error: $e', statusCode: response.statusCode);
    }
  }

  void dispose() => _client.close();
}
