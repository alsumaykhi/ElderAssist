import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Low-level service for Firebase authentication and Firestore user profiles.
class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  /// Trim + lowercase for consistent Auth and Identity Toolkit calls.
  static String normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  Future<void> sendOtp(
    String phoneNumber,
    Function(String verificationId) onCodeSent,
  ) async {
    final completer = Completer<void>();
    _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) {
        // Auto verification is intentionally ignored for manual OTP flow.
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
        if (!completer.isCompleted) completer.complete();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (!completer.isCompleted) completer.complete();
      },
    );
    await completer.future;
  }

  Future<UserCredential> verifyOtp(
    String verificationId,
    String smsCode,
  ) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _firebaseAuth.signInWithCredential(credential);
  }

  /// Same intent as `FirebaseAuth.fetchSignInMethodsForEmail` (removed from Dart
  /// `firebase_auth` 6.x): uses Identity Toolkit `createAuthUri`.
  ///
  /// Uses [normalizeEmail]. Treats `registered == true` as an existing account
  /// even when `signinMethods` is empty (email enumeration protection).
  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    final normalized = normalizeEmail(email);
    if (normalized.isEmpty) return <String>[];

    final app = Firebase.app();
    final uri = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:createAuthUri?key=${app.options.apiKey}',
    );

    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'identifier': normalized,
          'continueUri': 'https://${app.options.projectId}.firebaseapp.com',
        }),
      );
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode != HttpStatus.ok) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Could not look up this email address.',
        );
      }
      final map = jsonDecode(body) as Map<String, dynamic>;
      final registered = map['registered'] as bool? ?? false;
      final raw = map['signinMethods'];
      final methods = raw is List
          ? raw.map((e) => e.toString()).toList()
          : <String>[];
      if (methods.isNotEmpty) {
        return methods;
      }
      if (registered) {
        return <String>['password'];
      }
      return <String>[];
    } finally {
      client.close();
    }
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = normalizeEmail(email);
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    return credential;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(
      email: normalizeEmail(email),
    );
  }

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: normalizeEmail(email),
      password: password,
    );
  }

  Future<void> sendEmailVerification(User user) => user.sendEmailVerification();

  Future<void> reloadUser(User user) => user.reload();

  Future<void> reauthenticateWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'no-current-user');
    }
    final credential = EmailAuthProvider.credential(
      email: normalizeEmail(email),
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> sendReauthOtp(
    String phoneNumber,
    Function(String verificationId) onCodeSent,
  ) async {
    final completer = Completer<void>();
    _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
        if (!completer.isCompleted) completer.complete();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (!completer.isCompleted) completer.complete();
      },
    );
    await completer.future;
  }

  Future<void> reauthenticateWithPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'no-current-user');
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> createUserProfile({
    required String uid,
    required String role,
    String? phoneNumber,
    String? email,
  }) async {
    final data = <String, dynamic>{
      'role': role,
      'caregiverId': null,
      'seniorIds': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'fcmToken': null,
    };
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      data['phoneNumber'] = phoneNumber;
    } else {
      data['phoneNumber'] = '';
    }
    if (email != null && email.isNotEmpty) {
      data['email'] = email;
    }
    await _firestore.collection('users').doc(uid).set(data);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).get();
  }

  Future<void> saveFcmToken({
    required String uid,
    required String fcmToken,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'fcmToken': fcmToken,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePinHash({
    required String uid,
    required String pinHash,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'pinHash': pinHash,
      'pinUpdatedAt': FieldValue.serverTimestamp(),
    });
  }
}
