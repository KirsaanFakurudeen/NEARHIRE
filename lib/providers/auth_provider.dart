import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../core/services/auth_service.dart';
import '../core/constants/app_constants.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  String get role => _user?.role ?? '';

  void _setLoading(bool val) { _isLoading = val; notifyListeners(); }
  void _setError(String? msg) { _error = msg; notifyListeners(); }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    _setLoading(true); _setError(null);
    try {
      final data = await _authService.registerUser(
        name: name, email: email, phone: phone, password: password, role: role,
      );
      _user = User.fromJson(data['user']);
      await _saveRole(_user!.role);
      notifyListeners();
      return data;
    } catch (e) {
      _setError(e.toString()); rethrow;
    } finally { _setLoading(false); }
  }

  Future<void> login({
    required String emailOrPhone,
    required String password,
  }) async {
    _setLoading(true); _setError(null);
    try {
      final data = await _authService.loginWithPassword(
        emailOrPhone: emailOrPhone, password: password,
      );
      _user = User.fromJson(data['user']);
      await _saveRole(_user!.role);
      notifyListeners();
    } catch (e) {
      _setError(e.toString()); rethrow;
    } finally { _setLoading(false); }
  }

  Future<Map<String, dynamic>> requestOtp({required String phone}) async {
    _setLoading(true); _setError(null);
    try {
      return await _authService.loginWithOtp(phone: phone);
    } catch (e) {
      _setError(e.toString()); rethrow;
    } finally { _setLoading(false); }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String userId,
    required String otpCode,
  }) async {
    _setLoading(true); _setError(null);
    try {
      final data = await _authService.verifyOtp(userId: userId, otpCode: otpCode);
      _user = User.fromJson(data['user']);
      await _saveRole(_user!.role);
      notifyListeners();
      return data;
    } catch (e) {
      _setError(e.toString()); rethrow;
    } finally { _setLoading(false); }
  }

  Future<void> setRoleAndUser(Map<String, dynamic> userData) async {
    _user = User.fromJson(userData['user'] ?? userData);
    await _saveRole(_user!.role);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingCompleteKey, true);
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final fbUser = _authService.currentUser;
    if (fbUser == null) return;
    try {
      // Force token refresh to confirm session is still valid
      await fbUser.getIdToken(true);
      // Load full user data from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(fbUser.uid)
          .get();
      if (doc.exists) {
        _user = User.fromJson(doc.data()!);
        await _saveRole(_user!.role);
      } else {
        // User doc missing, treat as not authenticated
        await _authService.logout();
      }
      notifyListeners();
    } catch (_) {
      await _authService.logout();
    }
  }

  Future<String?> getStoredRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userRoleKey);
  }

  Future<void> logout() async {
    _setLoading(true);
    try { await _authService.logout(); } catch (_) {}
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userRoleKey);
    await prefs.remove(AppConstants.onboardingCompleteKey);
    _isLoading = false;
    notifyListeners();
  }

  void clearError() { _error = null; notifyListeners(); }

  Future<void> _saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userRoleKey, role);
  }
}
