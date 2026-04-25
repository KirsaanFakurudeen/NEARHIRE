import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_listing.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/distance_helper.dart';

class JobProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<JobListing> _jobs = [];
  List<JobListing> _filteredJobs = [];
  double _radiusKm = AppConstants.defaultRadiusKm;
  double? _userLat;
  double? _userLon;
  bool _isLoading = false;
  String? _error;

  String? _filterJobType;
  double? _filterMinPay;
  double? _filterMaxPay;
  String? _filterSchedule;
  String _searchQuery = '';

  List<JobListing> get jobs => _filteredJobs;
  double get radiusKm => _radiusKm;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => false; // Firestore real-time; no pagination needed for MVP
  String? get filterJobType => _filterJobType;
  double? get filterMinPay => _filterMinPay;
  double? get filterMaxPay => _filterMaxPay;

  Future<void> fetchNearbyJobs({
    required double lat,
    required double lon,
    bool refresh = false,
  }) async {
    _userLat = lat;
    _userLon = lon;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snap = await _db
          .collection('jobs')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      _jobs = snap.docs.map((d) => JobListing.fromJson({...d.data(), 'jobId': d.id})).toList();
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
      final snap = await _db
          .collection('jobs')
          .where('employerId', isEqualTo: employerId)
          .orderBy('createdAt', descending: true)
          .get();
      _jobs = snap.docs.map((d) => JobListing.fromJson({...d.data(), 'jobId': d.id})).toList();
      _filteredJobs = List.from(_jobs);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> postJob(Map<String, dynamic> jobData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _db.collection('jobs').add({
        ...jobData,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
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
      await _db.collection('jobs').doc(jobId).update(data);
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> closeJob(String jobId) async {
    try {
      await _db.collection('jobs').doc(jobId).update({'status': 'closed'});
      _jobs.removeWhere((j) => j.jobId == jobId);
      _applyFilters();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<JobListing?> getJobById(String jobId) async {
    try {
      final doc = await _db.collection('jobs').doc(jobId).get();
      if (!doc.exists) return null;
      return JobListing.fromJson({...doc.data()!, 'jobId': doc.id});
    } catch (_) {
      return null;
    }
  }

  void setRadius(double radius) { _radiusKm = radius; notifyListeners(); }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void applyFilters({String? jobType, double? minPay, double? maxPay, String? schedule}) {
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
          !job.description.toLowerCase().contains(_searchQuery)) return false;
      if (_filterJobType != null && job.jobType != _filterJobType) return false;
      if (_filterMinPay != null && job.payAmount < _filterMinPay!) return false;
      if (_filterMaxPay != null && job.payAmount > _filterMaxPay!) return false;
      if (_filterSchedule != null &&
          !job.schedule.toLowerCase().contains(_filterSchedule!.toLowerCase())) return false;
      if (_userLat != null && _userLon != null && job.latitude != 0 && job.longitude != 0) {
        return DistanceHelper.isWithinRadius(
          _userLat!, _userLon!, job.latitude, job.longitude, _radiusKm,
        );
      }
      return true;
    }).toList();
    notifyListeners();
  }

  double getDistanceToJob(JobListing job) {
    if (_userLat == null || _userLon == null) return 0;
    return DistanceHelper.calculateDistanceKm(
      _userLat!, _userLon!, job.latitude, job.longitude,
    );
  }
}
