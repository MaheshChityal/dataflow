import 'dart:convert';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/template_request.dart';
import 'api_service.dart';

class TemplateService {
  final ApiService _api;

  TemplateService(this._api);

  /// Create new template (with approval file uploads)
  Future<ApiResponse> createTemplate(TemplateRequest request, {Map<String, List<int>>? approvalFileBytes, Map<String, String>? approvalFileNames}) async {
    if (approvalFileBytes != null && approvalFileBytes.isNotEmpty) {
      // Multipart upload with files
      final fields = <String, String>{};
      final json = request.toJson();
      json.forEach((key, value) {
        if (value is List) {
          fields[key] = jsonEncode(value);
        } else {
          fields[key] = '$value';
        }
      });

      return _api.uploadMultipart(
        ApiConfig.templateCreateEndpoint,
        fields: fields,
        files: approvalFileBytes,
        fileNames: approvalFileNames ?? {},
      );
    } else {
      // JSON only (no files)
      return _api.post(ApiConfig.templateCreateEndpoint, request.toJson());
    }
  }

  /// Get all templates
  Future<ApiResponse<List<TemplateListItem>>> getTemplates() async {
    final response = await _api.get(ApiConfig.templateListEndpoint);
    if (response.success) {
      // Parse list from response
      try {
        final list = (response.data as List?)?.map((e) => TemplateListItem.fromJson(e)).toList() ?? [];
        return ApiResponse(success: true, data: list, message: response.message);
      } catch (_) {
        return ApiResponse(success: true, data: <TemplateListItem>[], message: response.message);
      }
    }
    return ApiResponse.error(response.message, statusCode: response.statusCode);
  }

  /// Get template by ID
  Future<ApiResponse> getTemplateById(String id) async {
    return _api.get('${ApiConfig.templateDetailEndpoint}/$id');
  }
}
