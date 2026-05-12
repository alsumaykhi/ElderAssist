import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/pin_service.dart';
import '../services/auth_service.dart';

/// Repository that coordinates authentication and PIN operations.
class AuthRepository {
  AuthRepository({
    required AuthService authService,
    required PinService pinService,
  })  : _authService = authService,
        _pinService = pinService;

  final AuthService _authService;
  final PinService _pinService;

  Future<void> sendOtp(
    String phoneNumber,
    Function(String verificationId) onCodeSent,
  ) {
    return _authService.sendOtp(phoneNumber, onCodeSent);
  }

  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) {
    return _authService.verifyOtp(verificationId, smsCode);
  }

  Future<List<String>> fetchSignInMethodsForEmail(String email) =>
      _authService.fetchSignInMethodsForEmail(email);

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) =>
      _authService.signInWithEmailAndPassword(email: email, password: password);

  Future<void> sendPasswordResetEmail(String email) =>
      _authService.sendPasswordResetEmail(email);

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) =>
      _authService.createUserWithEmailAndPassword(email: email, password: password);

  Future<void> sendEmailVerification(User user) =>
      _authService.sendEmailVerification(user);

  Future<void> reloadUser(User user) => _authService.reloadUser(user);

  Future<void> reauthenticateWithEmailPassword({
    required String email,
    required String password,
  }) =>
      _authService.reauthenticateWithEmailPassword(
        email: email,
        password: password,
      );

  Future<void> sendReauthOtp(
    String phoneNumber,
    Function(String verificationId) onCodeSent,
  ) =>
      _authService.sendReauthOtp(phoneNumber, onCodeSent);

  Future<void> reauthenticateWithPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) =>
      _authService.reauthenticateWithPhoneOtp(
        verificationId: verificationId,
        smsCode: smsCode,
      );

  Future<void> createUserProfile({
    required String uid,
    required String role,
    String? phoneNumber,
    String? email,
  }) {
    return _authService.createUserProfile(
      uid: uid,
      role: role,
      phoneNumber: phoneNumber,
      email: email,
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile(String uid) {
    return _authService.getUserProfile(uid);
  }

  Future<void> saveFcmToken({
    required String uid,
    required String fcmToken,
  }) {
    return _authService.saveFcmToken(uid: uid, fcmToken: fcmToken);
  }

  Future<void> savePin(String pin) => _pinService.savePin(pin);

  String createPinHash(String pin) => _pinService.createPinHash(pin);

  Future<bool> verifyPin(String inputPin) => _pinService.verifyPin(inputPin);

  Future<bool> hasPin() => _pinService.hasPin();

  Future<void> updatePinHash({
    required String uid,
    required String pinHash,
  }) =>
      _authService.updatePinHash(uid: uid, pinHash: pinHash);
}
