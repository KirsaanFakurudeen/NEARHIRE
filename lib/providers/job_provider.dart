import 'package:flutter/foundation.dart';
import '../models/job_listing.dart';
import '../core/services/api_service.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/distance_helper.dart';

class JobProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<JobListing> _jobs = [];
  List<JobListing> _filteredJobs = [];
  double _radiusKm = AppConstants.defaultRadiusKm;
  double? _userLat;
  double? _userLon;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  // Filters
  String? _filterJobType;
  double? _filterMinPay;
  double? _filterMaxPay;
  String? _filterSchedule;
  String _searchQuery = '';

  List<JobListing> get jobs => _filteredJobs;
  double get radiusKm => _radiusKm;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  String? get filterJobType => _filterJobType;
  double? get filterMinPay => _filterMinPay;
  double? get filterMaxPay => _filterMaxPay;

  Future<void> fetchNearbyJobs({
    required double lat,
    required double lon,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _jobs = [];
    }
    if (!_hasMore) return;

    _userLat = lat;
    _userLon = lon;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.get('/jobs/nearby', params: {
        'lat': lat,
        'lon': lon,
        'radius': _radiusKm,
        'page': _currentPage,
        'limit': 20,
      });
      final List data = res.data['jobs'] ?? [];
      final newJobs = data.map((j) => JobListing.fromJson(j)).toList();
      _jobs = refresh ? newJobs : [..._jobs, ...newJobs];
      _hasMore = newJobs.length == 20;
      _currentPage++;
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchEmployerJobs(String employerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.get('/jobs/employer/$employerId');
      final List data = res.data['jobs'] ?? [];
      _jobs = data.map((j) => JobListing.fromJson(j)).toList();
      _filteredJobs = List.from(_jobs);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setRadius(double radius) {
    _radiusKm = radius;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void applyFilters({
    String? jobType,
    double? minPay,
    double? maxPay,
    String? schedule,
  }) {
    _filterJobType = jobType;
    _filterMinPay = minPay;
    _filterMaxPay = maxPay;
    _filterSchedule = schedule;
    _applyFilters();
  }

  void clearFilters() {
    _filterJobType = null;
    _filterMinPay = null;
    _filterMaxPay = null;
    _filterSchedule = null;
    _searchQuery = '';
    _filteredJobs = List.from(_jobs);
    notifyListeners();
  }

  void _applyFilters() {
    _filteredJobs = _jobs.where((job) {
      if (_searchQuery.isNotEmpty &&
          !job.title.toLowerCase().contains(_searchQuery) &&
          !job.description.toLowerCase().contains(_searchQuery)) {
        return false;
      }
      if (_filterJobType != null && job.jobType != _filterJobType) return false;
      if (_filterMinPay != null && job.payAmount < _filterMinPay!) return false;
      if (_filterMaxPay != null && job.payAmount > _filterMaxPay!) return false;
      if (_filterSchedule != null &&
          !job.schedule.toLowerCase().contains(_filterSchedule!.toLowerCase())) {
        return false;
      }
      if (_userLat != null && _userLon != null) {
        return DistanceHelper.isWithinRadius(
          _userLat!,
          _userLon!,
          job.latitude,
          job.longitude,
          _radiusKm,
        );
      }
      return true;
    }).toList();
    notifyListeners();
  }

  double getDistanceToJob(JobListing job) {
    if (_userLat == null || _userLon == null) return 0;
    return DistanceHelper.calculateDistanceKm(
      _userLat!,
      _userLon!,
      job.latitude,
      job.longitude,
    );
  }

  Future<JobListing?> getJobById(String jobId) async {
    try {
      final res = await _api.get('/jobs/$jobId');
      return JobListing.fromJson(res.data['job']);
    } catch (_) {
      return null;
    }
  }

  Future<void> postJob(Map<String, dynamic> jobData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.post('/jobs', data: jobData);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateJob(String jobId, Map<String, dynamic> data) async {
    try {
      await _api.patch('/jobs/$jobId', data: data);
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> closeJob(String jobId) async {
    try {
      await _api.patch('/jobs/$jobId', data: {'status': 'closed'});
      _jobs.removeWhere((j) => j.jobId == jobId);
      _applyFilters();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }
}
