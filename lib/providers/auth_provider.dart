import 'package:flutter/material.dart';
import '../models/api_response.dart';
import '../models/login_request.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider(this._authService);

  bool _loading = false;
  String? _error;
  LoginResponse? _user;

  bool get loading => _loading;
  String? get error => _error;
  LoginResponse? get user => _user;
  bool get isLoggedIn => _authService.isLoggedIn;

  Future<bool> login(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    final response = await _authService.login(LoginRequest(username: username, password: password));

    _loading = false;

    if (response.success && response.data != null) {
      _user = response.data;
      notifyListeners();
      return true;
    } else {
      // For now, allow login even if API fails (dev mode)
      // Remove this block when backend is ready
      _user = LoginResponse(token: 'dev-token', userId: 'dev', username: username);
      notifyListeners();
      return true;

      // Uncomment below when backend is ready:
      // _error = response.message.isNotEmpty ? response.message : 'Login failed';
      // notifyListeners();
      // return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }
}
