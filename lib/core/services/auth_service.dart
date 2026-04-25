import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

class AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Email/Password Register ──────────────────────────────────────────────
  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final userData = {
      'userId': uid,
      'fullName': name,
      'email': email,
      'phone': phone,
      'role': role,
      'otpVerified': true,
      'createdAt': FieldValue.serverTimestamp(),
    };
    await _db.collection('users').doc(uid).set(userData);
    return {'userId': uid, 'user': userData};
  }

  // ── Email/Password Login ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> loginWithPassword({
    required String emailOrPhone,
    required String password,
  }) async {
    final email = emailOrPhone.contains('@')
        ? emailOrPhone
        : await _emailFromPhone(emailOrPhone);
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final token = await cred.user!.getIdToken() ?? '';
    final doc = await _db.collection('users').doc(uid).get();
    return {'token': token, 'user': doc.data()!};
  }

  // ── Phone OTP ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> loginWithOtp({required String phone}) async {
    // Returns verificationId so the OTP screen can verify
    String? verificationId;
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (_) {},
      verificationFailed: (e) => throw Exception(e.message),
      codeSent: (id, _) => verificationId = id,
      codeAutoRetrievalTimeout: (_) {},
      timeout: const Duration(seconds: AppConstants.otpResendSeconds),
    );
    return {'userId': verificationId ?? '', 'verificationId': verificationId};
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String userId, // userId == verificationId for phone flow
    required String otpCode,
  }) async {
    final credential = fb.PhoneAuthProvider.credential(
      verificationId: userId,
      smsCode: otpCode,
    );
    final cred = await _auth.signInWithCredential(credential);
    final uid = cred.user!.uid;
    final token = await cred.user!.getIdToken() ?? '';

    // Check if user doc exists; create minimal one if not
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      await _db.collection('users').doc(uid).set({
        'userId': uid,
        'fullName': '',
        'email': cred.user!.email ?? '',
        'phone': cred.user!.phoneNumber ?? '',
        'role': '',
        'otpVerified': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    final userData = (await _db.collection('users').doc(uid).get()).data()!;
    return {'token': token, 'user': userData};
  }

  Future<void> logout() async => _auth.signOut();

  Future<String?> getStoredToken() async =>
      _auth.currentUser?.getIdToken();

  fb.User? get currentUser => _auth.currentUser;

  // ── Helpers ──────────────────────────────────────────────────────────────
  Future<String> _emailFromPhone(String phone) async {
    final snap = await _db
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) throw Exception('No account found for this phone.');
    return snap.docs.first.data()['email'] as String;
  }
}
