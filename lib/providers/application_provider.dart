import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/application.dart';
import '../core/services/api_service.dart';

class ApplicationProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Application> _applications = [];
  bool _isLoading = false;
  String? _error;

  List<Application> get applications => _applications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchApplicationsForSeeker(String seekerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.get('/applications/seeker/$seekerId');
      final List data = res.data['applications'] ?? [];
      _applications = data.map((a) => Application.fromJson(a)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchApplicationsForJob(String jobId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.get('/applications/job/$jobId');
      final List data = res.data['applications'] ?? [];
      _applications = data.map((a) => Application.fromJson(a)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Application> submitApplication({
    required String jobId,
    required String seekerId,
    required String applyMethod,
    String? resumeUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.post('/applications', data: {
        'jobId': jobId,
        'seekerId': seekerId,
        'applyMethod': applyMethod,
        if (resumeUrl != null) 'resumeUrl': resumeUrl,
      });
      final app = Application.fromJson(res.data['application']);
      _applications.insert(0, app);
      notifyListeners();
      return app;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitApplicationWithResume({
    required String jobId,
    required String seekerId,
    required String filePath,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final formData = FormData.fromMap({
        'jobId': jobId,
        'seekerId': seekerId,
        'applyMethod': 'resume',
        'resume': await MultipartFile.fromFile(filePath),
      });
      final res = await _api.postFormData('/applications/upload', formData);
      final app = Application.fromJson(res.data['application']);
      _applications.insert(0, app);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateApplicationStatus(
      String applicationId, String status) async {
    try {
      await _api.patch('/applications/$applicationId', data: {'status': status});
      final idx = _applications.indexWhere((a) => a.applicationId == applicationId);
      if (idx != -1) {
        final old = _applications[idx];
        _applications[idx] = Application.fromJson({
          ...old.toJson(),
          'status': status,
        });
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> scheduleInterview(
      String applicationId, DateTime scheduledAt) async {
    try {
      await _api.patch('/applications/$applicationId', data: {
        'status': 'interview_scheduled',
        'interviewScheduledAt': scheduledAt.toIso8601String(),
      });
      final idx = _applications.indexWhere((a) => a.applicationId == applicationId);
      if (idx != -1) {
        final old = _applications[idx];
        _applications[idx] = Application.fromJson({
          ...old.toJson(),
          'status': 'interview_scheduled',
          'interviewScheduledAt': scheduledAt.toIso8601String(),
        });
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
