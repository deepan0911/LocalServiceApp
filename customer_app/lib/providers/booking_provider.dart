import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../models/models.dart';

class BookingProvider extends ChangeNotifier {
  List<BookingModel> _bookings = [];
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  List<BookingModel> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  Future<void> fetchBookings({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      final res = await ApiClient.dio.get('/bookings/customer', queryParameters: queryParams);
      _bookings = (res.data['data'] as List).map((b) => BookingModel.fromJson(b)).toList();
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Failed to fetch bookings';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createBooking({
    required String workerId,
    required String serviceType,
    required String description,
    required Map<String, dynamic> address,
    required DateTime scheduledAt,
    List<String>? imagePaths,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      FormData formData = FormData.fromMap({
        'workerId': workerId,
        'serviceType': serviceType,
        'description': description,
        'address[street]': address['street'],
        'address[city]': address['city'],
        'scheduledAt': scheduledAt.toIso8601String(),
      });

      if (imagePaths != null) {
        for (final path in imagePaths) {
          formData.files.add(MapEntry('images', await MultipartFile.fromFile(path)));
        }
      }

      final res = await ApiClient.dio.post('/bookings', data: formData);
      _bookings.insert(0, BookingModel.fromJson(res.data['data']));
      _successMessage = 'Booking created! Waiting for worker response.';
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Failed to create booking';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelBooking(String bookingId, {String? reason}) async {
    try {
      await ApiClient.dio.put('/bookings/$bookingId/cancel', data: {'reason': reason});
      final idx = _bookings.indexWhere((b) => b.id == bookingId);
      if (idx != -1) {
        _bookings.removeAt(idx);
        notifyListeners();
      }
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Failed to cancel booking';
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitReview(String bookingId, double rating, String comment) async {
    try {
      await ApiClient.dio.post('/bookings/$bookingId/review', data: {'rating': rating, 'comment': comment});
      _successMessage = 'Review submitted!';
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Failed to submit review';
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _error = null;
    _successMessage = null;
  }
}
