import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../models/models.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  final _storage = const FlutterSecureStorage();

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> tryAutoLogin() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return;
    try {
      final res = await ApiClient.dio.get('/auth/me');
      _user = UserModel.fromJson(res.data['user']);
      notifyListeners();
    } catch (_) {
      await _storage.delete(key: 'auth_token');
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiClient.dio.post('/auth/login', data: {'email': email, 'password': password});
      await _storage.write(key: 'auth_token', value: res.data['token']);
      _user = UserModel.fromJson(res.data['user']);
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Login failed';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendEmailOtp(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await ApiClient.dio.post('/auth/send-email-otp', data: {'email': email});
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Failed to send OTP';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyEmailOtp(String email, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await ApiClient.dio.post('/auth/verify-email-otp', data: {'email': email, 'otp': otp});
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'OTP verification failed';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiClient.dio.post('/auth/register', data: {
        'name': name, 'email': email, 'phone': phone, 'password': password,
      });
      await _storage.write(key: 'auth_token', value: res.data['token']);
      _user = UserModel.fromJson(res.data['user']);
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Registration failed';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    _user = null;
    notifyListeners();
  }
}
