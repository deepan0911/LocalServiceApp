import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/models.dart';

// ─── Auth ────────────────────────────────────────────────────────────────────
class AdminAuthProvider extends ChangeNotifier {
  AdminUser? _user;
  bool _isLoading = false;
  String? _error;
  final _storage = const FlutterSecureStorage();

  AdminUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> tryAutoLogin() async {
    final token = await _storage.read(key: 'admin_token');
    if (token == null) return;
    try {
      final res = await ApiClient.dio.get('/auth/me');
      if (res.data['user']['role'] == 'admin') {
        _user = AdminUser.fromJson(res.data['user']);
        notifyListeners();
      }
    } catch (_) {
      await _storage.delete(key: 'admin_token');
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      final res = await ApiClient.dio.post('/auth/login', data: {'email': email, 'password': password});
      if (res.data['user']['role'] != 'admin') {
        _error = 'Access denied. Admin only.';
        _isLoading = false; notifyListeners(); return false;
      }
      await _storage.write(key: 'admin_token', value: res.data['token']);
      _user = AdminUser.fromJson(res.data['user']);
      _isLoading = false; notifyListeners(); return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Login failed';
      _isLoading = false; notifyListeners(); return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'admin_token');
    _user = null; notifyListeners();
  }
}

// ─── Worker Verification ─────────────────────────────────────────────────────
class WorkerVerificationProvider extends ChangeNotifier {
  List<AdminWorker> _workers = [];
  bool _isLoading = false;
  String? _error;

  List<AdminWorker> get workers => _workers;
  bool get isLoading => _isLoading;

  Future<void> fetchWorkers({String status = 'pending'}) async {
    _isLoading = true; notifyListeners();
    try {
      final res = await ApiClient.dio.get('/admin/workers', queryParameters: {'status': status, 'limit': 50});
      _workers = (res.data['data'] as List).map((w) => AdminWorker.fromJson(w)).toList();
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Failed to load';
    }
    _isLoading = false; notifyListeners();
  }

  Future<bool> verifyWorker(String workerId, String action, {String? reason}) async {
    try {
      await ApiClient.dio.put('/admin/workers/$workerId/verify', data: {'action': action, 'reason': reason});
      _workers.removeWhere((w) => w.id == workerId);
      notifyListeners(); return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Failed'; return false;
    }
  }
}

// ─── Booking Management ───────────────────────────────────────────────────────
class BookingManagementProvider extends ChangeNotifier {
  List<AdminBooking> _bookings = [];
  bool _isLoading = false;

  List<AdminBooking> get bookings => _bookings;
  bool get isLoading => _isLoading;

  Future<void> fetchBookings({String? status}) async {
    _isLoading = true; notifyListeners();
    try {
      final res = await ApiClient.dio.get('/admin/bookings', queryParameters: status != null ? {'status': status} : {});
      _bookings = (res.data['data'] as List).map((b) => AdminBooking.fromJson(b)).toList();
    } catch (_) {}
    _isLoading = false; notifyListeners();
  }
}

// ─── Analytics ───────────────────────────────────────────────────────────────
class AnalyticsProvider extends ChangeNotifier {
  Analytics? _analytics;
  bool _isLoading = false;

  Analytics? get analytics => _analytics;
  bool get isLoading => _isLoading;

  Future<void> fetchAnalytics() async {
    _isLoading = true; notifyListeners();
    try {
      final res = await ApiClient.dio.get('/admin/analytics');
      _analytics = Analytics.fromJson(res.data['data']);
    } catch (_) {}
    _isLoading = false; notifyListeners();
  }
}

// ─── Complaints ───────────────────────────────────────────────────────────────
class ComplaintProvider extends ChangeNotifier {
  List<Complaint> _complaints = [];
  bool _isLoading = false;

  List<Complaint> get complaints => _complaints;
  bool get isLoading => _isLoading;

  Future<void> fetchComplaints({String? status}) async {
    _isLoading = true; notifyListeners();
    try {
      final res = await ApiClient.dio.get('/admin/complaints', queryParameters: status != null ? {'status': status} : {});
      _complaints = (res.data['data'] as List).map((c) => Complaint.fromJson(c)).toList();
    } catch (_) {}
    _isLoading = false; notifyListeners();
  }

  Future<bool> resolveComplaint(String id, String resolution) async {
    try {
      await ApiClient.dio.put('/admin/complaints/$id/resolve', data: {'resolution': resolution});
      await fetchComplaints();
      return true;
    } catch (_) { return false; }
  }
}
