import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../core/services/auth_service.dart';
import '../core/constants/app_constants.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _user != null;
  String get role => _user?.role ?? '';

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _setError(String? msg) {
    _error = msg;
    notifyListeners();
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final data = await _authService.registerUser(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );
      return data;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login({
    required String emailOrPhone,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final data = await _authService.loginWithPassword(
        emailOrPhone: emailOrPhone,
        password: password,
      );
      _token = data['token'];
      _user = User.fromJson(data['user']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userRoleKey, _user!.role);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> requestOtp({required String phone}) async {
    _setLoading(true);
    _setError(null);
    try {
      return await _authService.loginWithOtp(phone: phone);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String userId,
    required String otpCode,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final data = await _authService.verifyOtp(
        userId: userId,
        otpCode: otpCode,
      );
      if (data['token'] != null) {
        _token = data['token'];
        _user = User.fromJson(data['user']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.userRoleKey, _user!.role);
        notifyListeners();
      }
      return data;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setRoleAndUser(Map<String, dynamic> userData) async {
    _user = User.fromJson(userData['user']);
    _token = userData['token'];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userRoleKey, _user!.role);
    await prefs.setBool(AppConstants.onboardingCompleteKey, true);
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final token = await _authService.getStoredToken();
    if (token == null) return;
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString(AppConstants.userRoleKey);
    if (role != null) {
      notifyListeners();
    }
  }

  Future<String?> getStoredRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userRoleKey);
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
    } catch (_) {}
    _user = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userRoleKey);
    await prefs.remove(AppConstants.onboardingCompleteKey);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> devSkipLogin(String role) async {
    _user = User(
      userId: 'dev-user-001',
      fullName: role == 'employer' ? 'Demo Employer' : 'Demo Seeker',
      email: 'demo@nearhire.com',
      phone: '+10000000000',
      role: role,
      otpVerified: true,
    );
    _token = 'dev-token';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userRoleKey, role);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
