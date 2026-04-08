import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../models/models.dart';

class WorkerProvider extends ChangeNotifier {
  List<WorkerModel> _workers = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  List<WorkerModel> get workers => _workers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> fetchWorkers({String? skill, bool refresh = false}) async {
    if (refresh) {
      _workers = [];
      _currentPage = 1;
      _hasMore = true;
    }
    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    if (refresh) notifyListeners();

    try {
      final queryParams = <String, dynamic>{'page': _currentPage, 'limit': 20};
      if (skill != null && skill.isNotEmpty) queryParams['skill'] = skill;

      final res = await ApiClient.dio.get('/workers', queryParameters: queryParams);
      final List data = res.data['data'];
      final newWorkers = data.map((w) => WorkerModel.fromJson(w)).toList();
      
      _workers.addAll(newWorkers);
      _hasMore = _workers.length < (res.data['total'] ?? 0);
      _currentPage++;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Failed to load workers';
    }
    _isLoading = false;
    notifyListeners();
  }
}
