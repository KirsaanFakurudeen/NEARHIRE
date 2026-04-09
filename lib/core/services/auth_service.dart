import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    final res = await _api.post('/auth/register', data: {
      'fullName': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> loginWithPassword({
    required String emailOrPhone,
    required String password,
  }) async {
    final res = await _api.post('/auth/login', data: {
      'emailOrPhone': emailOrPhone,
      'password': password,
    });
    final data = res.data as Map<String, dynamic>;
    await _storage.write(key: AppConstants.jwtTokenKey, value: data['token']);
    return data;
  }

  Future<Map<String, dynamic>> loginWithOtp({required String phone}) async {
    final res = await _api.post('/auth/request-otp', data: {'phone': phone});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String userId,
    required String otpCode,
  }) async {
    final res = await _api.post('/auth/verify-otp', data: {
      'userId': userId,
      'otpCode': otpCode,
    });
    final data = res.data as Map<String, dynamic>;
    if (data['token'] != null) {
      await _storage.write(key: AppConstants.jwtTokenKey, value: data['token']);
    }
    return data;
  }

  Future<void> refreshToken() async {
    final res = await _api.post('/auth/refresh');
    final data = res.data as Map<String, dynamic>;
    await _storage.write(key: AppConstants.jwtTokenKey, value: data['token']);
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {}
    await _storage.delete(key: AppConstants.jwtTokenKey);
  }

  Future<String?> getStoredToken() =>
      _storage.read(key: AppConstants.jwtTokenKey);
}
