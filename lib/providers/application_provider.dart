import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/application.dart';

class ApplicationProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<Application> _applications = [];
  bool _isLoading = false;
  String? _error;

  List<Application> get applications => _applications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchApplicationsForSeeker(String seekerId) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      final snap = await _db
          .collection('applications')
          .where('seekerId', isEqualTo: seekerId)
          .orderBy('appliedAt', descending: true)
          .get();
      _applications = snap.docs
          .map((d) => Application.fromJson({...d.data(), 'applicationId': d.id}))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<void> fetchApplicationsForJob(String jobId) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      final snap = await _db
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .orderBy('appliedAt', descending: true)
          .get();
      _applications = snap.docs
          .map((d) => Application.fromJson({...d.data(), 'applicationId': d.id}))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<Application> submitApplication({
    required String jobId,
    required String seekerId,
    required String applyMethod,
    String? resumeUrl,
  }) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      final data = {
        'jobId': jobId,
        'seekerId': seekerId,
        'applyMethod': applyMethod,
        if (resumeUrl != null) 'resumeUrl': resumeUrl,
        'status': 'pending',
        'appliedAt': FieldValue.serverTimestamp(),
      };
      final ref = await _db.collection('applications').add(data);
      final app = Application.fromJson({
        ...data,
        'applicationId': ref.id,
        'appliedAt': DateTime.now().toIso8601String(),
      });
      _applications.insert(0, app);
      notifyListeners();
      return app;
    } catch (e) {
      _error = e.toString(); rethrow;
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<void> submitApplicationWithResume({
    required String jobId,
    required String seekerId,
    required String filePath,
  }) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      // Upload PDF to Firebase Storage
      final file = File(filePath);
      final storageRef = _storage
          .ref()
          .child('resumes/$seekerId/${DateTime.now().millisecondsSinceEpoch}.pdf');
      await storageRef.putFile(file);
      final resumeUrl = await storageRef.getDownloadURL();
      await submitApplication(
        jobId: jobId,
        seekerId: seekerId,
        applyMethod: 'resume',
        resumeUrl: resumeUrl,
      );
    } catch (e) {
      _error = e.toString(); rethrow;
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<void> updateApplicationStatus(String applicationId, String status) async {
    try {
      await _db.collection('applications').doc(applicationId).update({'status': status});
      final idx = _applications.indexWhere((a) => a.applicationId == applicationId);
      if (idx != -1) {
        final old = _applications[idx];
        _applications[idx] = Application.fromJson({...old.toJson(), 'status': status});
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString(); rethrow;
    }
  }

  Future<void> scheduleInterview(String applicationId, DateTime scheduledAt) async {
    try {
      await _db.collection('applications').doc(applicationId).update({
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
      _error = e.toString(); rethrow;
    }
  }

  void clearError() { _error = null; notifyListeners(); }
}
