import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/login_request.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api;

  AuthService(this._api);

  Future<ApiResponse<LoginResponse>> login(LoginRequest request) async {
    final response = await _api.post<LoginResponse>(
      ApiConfig.loginEndpoint,
      request.toJson(),
      fromData: (json) => LoginResponse.fromJson(json),
    );

    // Store token on success
    if (response.success && response.data != null) {
      _api.setToken(response.data!.token);
    }

    return response;
  }

  Future<ApiResponse> logout() async {
    final response = await _api.post(ApiConfig.logoutEndpoint, {});
    _api.setToken(null);
    return response;
  }

  bool get isLoggedIn => _api.isAuthenticated;
}
