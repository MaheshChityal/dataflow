import '../config/api_config.dart';
import '../models/api_response.dart';
import 'api_service.dart';

class PipelineService {
  final ApiService _api;

  PipelineService(this._api);

  /// Submit join mapping configuration
  Future<ApiResponse> submitMapping(Map<String, dynamic> payload) async {
    return _api.post(ApiConfig.pipelineSubmitMappingEndpoint, payload);
  }

  /// Submit output data format
  Future<ApiResponse> submitDataFormat(Map<String, dynamic> payload) async {
    return _api.post(ApiConfig.pipelineSubmitFormatEndpoint, payload);
  }

  /// Save source configuration
  Future<ApiResponse> saveSourceConfig(Map<String, dynamic> payload) async {
    return _api.post(ApiConfig.saveSourceConfigEndpoint, payload);
  }
}
