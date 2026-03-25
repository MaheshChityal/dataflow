import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';

/// Service to fetch master/dropdown data from API
class MasterDataService {
  final ApiService _api;

  MasterDataService(this._api);

  /// Fetch departments list from API
  /// Returns List<String> of department names
  /// Falls back to static list if API fails
  Future<List<String>> getDepartments() async {
    try {
      final response = await _api.get(ApiConfig.departmentsEndpoint);
      if (response.success && response.data != null) {
        // API returns: {"data": ["Finance", "Operations", ...]}
        // or {"data": [{"id": 1, "name": "Finance"}, ...]}
        final data = response.data;
        if (data is List) {
          return data.map((e) => e is String ? e : (e['name'] ?? e['departmentName'] ?? '$e')).toList().cast<String>();
        }
      }
    } catch (e) {
      debugPrint('[MasterData] getDepartments error: $e');
    }

    // Fallback static list when API unavailable
    debugPrint('[MasterData] Using fallback static departments');
    return _fallbackDepartments;
  }

  static const _fallbackDepartments = [
    'Finance', 'Operations', 'Marketing', 'IT', 'HR', 'Risk', 'Compliance', 'Treasury'
  ];
}
