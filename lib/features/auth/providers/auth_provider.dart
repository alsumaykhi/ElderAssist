import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../repository/auth_repository.dart';
import '../services/auth_service.dart';
import 'auth_state.dart';

/// Next step after email is verified and Firestore profile state is known.
enum EmailAuthFlowNext {
  roleSelection,
  pinUnlock,
}

/// Result of email/password sign-in for routing and error display.
enum EmailPasswordSignInOutcome {
  success,
  userNotFound,
  wrongPassword,
  invalidEmail,
  failed,
}

/// Result of email/password registration for routing and error display.
enum EmailRegisterOutcome {
  success,
  emailAlreadyInUse,
  failed,
}

enum PasswordResetOutcome {
  success,
  invalidEmail,
  userNotFound,
  failed,
}

class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthRepository authRepository})
      : _authRepository = authRepository;

  final AuthRepository _authRepository;
  Timer? _pinLockTicker;
  String? _recoveryVerificationId;
  AuthState _state = const AuthState();
  AuthState get state => _state;

  int get secondsUntilPinUnlock {
    final untilMs = _state.pinLockUntilEpochMs;
    if (untilMs == null) return 0;
    final remainingMs = untilMs - DateTime.now().millisecondsSinceEpoch;
    if (remainingMs <= 0) return 0;
    return (remainingMs / 1000).ceil();
  }

  void clearError() {
    _state = _state.copyWith(clearErrorMessage: true);
    notifyListeners();
  }

  static String normalizeEmailInput(String email) =>
      AuthService.normalizeEmail(email);

  /// Identity Toolkit lookup (see [AuthService.fetchSignInMethodsForEmail]).
  /// Returns `null` if the request failed.
  Future<List<String>?> fetchEmailSignInMethods(String email) async {
    try {
      return await _authRepository.fetchSignInMethodsForEmail(email);
    } on FirebaseAuthException catch (e) {
      _setError(_firebaseErrorMessage(e));
      return null;
    } catch (_) {
      _setError('Could not look up email. Try again.');
      return null;
    }
  }

  Future<EmailPasswordSignInOutcome> signInWithEmailPasswordOutcome(
    String email,
    String password,
  ) async {
    _setLoading(true, clearError: true);
    try {
      final cred = await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _state = _state.copyWith(
        firebaseUser: cred.user,
        clearErrorMessage: true,
      );
      notifyListeners();
      return EmailPasswordSignInOutcome.success;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return EmailPasswordSignInOutcome.userNotFound;
        case 'wrong-password':
          _setError('Incorrect password.');
          return EmailPasswordSignInOutcome.wrongPassword;
        case 'invalid-email':
          _setError('Invalid email address.');
          return EmailPasswordSignInOutcome.invalidEmail;
        case 'invalid-credential':
          _setError('Incorrect password.');
          return EmailPasswordSignInOutcome.wrongPassword;
        default:
          _setError(_firebaseErrorMessage(e));
          return EmailPasswordSignInOutcome.failed;
      }
    } catch (_) {
      _setError('Sign in failed. Please try again.');
      return EmailPasswordSignInOutcome.failed;
    } finally {
      _setLoading(false);
    }
  }

  Future<PasswordResetOutcome> sendPasswordReset(String email) async {
    final normalized = AuthService.normalizeEmail(email);
    if (normalized.isEmpty) {
      _setError('Please enter a valid email address.');
      return PasswordResetOutcome.invalidEmail;
    }
    _setLoading(true, clearError: true);
    try {
      await _authRepository.sendPasswordResetEmail(normalized);
      _state = _state.copyWith(clearErrorMessage: true);
      notifyListeners();
      return PasswordResetOutcome.success;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        _setError('Invalid email address.');
        return PasswordResetOutcome.invalidEmail;
      }
      if (e.code == 'user-not-found') {
        _setError('No account found for this email.');
        return PasswordResetOutcome.userNotFound;
      }
      _setError(_firebaseErrorMessage(e));
      return PasswordResetOutcome.failed;
    } catch (_) {
      _setError('Could not send reset email. Please try again.');
      return PasswordResetOutcome.failed;
    } finally {
      _setLoading(false);
    }
  }

  Future<EmailRegisterOutcome> registerWithEmailPasswordOutcome(
    String email,
    String password,
  ) async {
    _setLoading(true, clearError: true);
    try {
      final cred = await _authRepository.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _state = _state.copyWith(
        firebaseUser: cred.user,
        clearErrorMessage: true,
      );
      notifyListeners();
      return EmailRegisterOutcome.success;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return EmailRegisterOutcome.emailAlreadyInUse;
      }
      if (e.code == 'invalid-email') {
        _setError('Invalid email address.');
        return EmailRegisterOutcome.failed;
      }
      _setError(_firebaseErrorMessage(e));
      return EmailRegisterOutcome.failed;
    } catch (_) {
      _setError('Could not create account. Please try again.');
      return EmailRegisterOutcome.failed;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendEmailVerificationToCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _authRepository.sendEmailVerification(user);
    } on FirebaseAuthException catch (e) {
      _setError(_firebaseErrorMessage(e));
    } catch (_) {
      _setError('Could not send verification email.');
    }
  }

  /// After the user has verified their email: sync session and return navigation target.
  Future<EmailAuthFlowNext?> finalizeVerifiedEmailUserSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _setError('Not signed in.');
      return null;
    }
    try {
      await _authRepository.reloadUser(user);
    } on FirebaseAuthException catch (e) {
      _setError(_firebaseErrorMessage(e));
      return null;
    }
    final refreshed = FirebaseAuth.instance.currentUser ?? user;
    if (!refreshed.emailVerified) {
      _setError('Verify your email before continuing.');
      return null;
    }
    final snap = await _authRepository.getUserProfile(refreshed.uid);
    final exists = snap.exists && snap.data() != null;
    await setSessionAfterEmailAuth(
      isNewUser: !exists,
      userProfile: exists ? snap.data() : null,
    );
    return exists ? EmailAuthFlowNext.pinUnlock : EmailAuthFlowNext.roleSelection;
  }

  Future<void> sendOtp(String phone) async {
    if (phone.isEmpty) {
      _setError('Please enter a valid phone number.');
      return;
    }

    _setLoading(true, clearError: true);

    try {
      await _authRepository.sendOtp(
        phone,
        (verificationId) {
          _state = _state.copyWith(
            verificationId: verificationId,
          );
          notifyListeners();
        },
      );
    } on FirebaseAuthException catch (e) {
      _setError(_firebaseErrorMessage(e));
    } catch (_) {
      _setError('Failed to send code. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> verifyOtp(String smsCode) async {
    if (smsCode.isEmpty) {
      _setError('Please enter the code sent to your phone.');
      return;
    }

    final verificationId = _state.verificationId;
    if (verificationId == null) {
      _setError('No verification in progress. Please request a new code.');
      return;
    }

    _setLoading(true, clearError: true);

    try {
      final credential = await _authRepository.verifyOtp(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final user = credential.user;
      final isNew =
          credential.additionalUserInfo?.isNewUser ?? _state.isNewUser;

      _state = _state.copyWith(
        firebaseUser: user,
        isNewUser: isNew,
      );
      notifyListeners();

      if (!isNew && user != null) {
        final snapshot = await _authRepository.getUserProfile(user.uid);
        if (snapshot.exists && snapshot.data() != null) {
          _state = _state.copyWith(userProfile: snapshot.data());
          notifyListeners();
        } else {
          _setError('User profile not found. Please contact support.');
          return;
        }
      }
    } on FirebaseAuthException catch (e) {
      _setError(_firebaseErrorMessage(e));
    } catch (_) {
      _setError('Could not verify the code. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createUserProfile(String role) async {
    final user = _state.firebaseUser;
    if (user == null) {
      _setError('You must be signed in to create a profile.');
      return;
    }

    final phoneNumber = user.phoneNumber;
    final email = user.email;
    if ((phoneNumber == null || phoneNumber.isEmpty) &&
        (email == null || email.isEmpty)) {
      _setError('Phone or email not found. Please sign in again.');
      return;
    }

    _setLoading(true, clearError: true);

    try {
      await _authRepository.createUserProfile(
        uid: user.uid,
        role: role,
        phoneNumber: phoneNumber ?? '',
        email: email,
      );
      _state = _state.copyWith(clearErrorMessage: true);
      notifyListeners();
    } on Exception catch (e) {
      _setError(e.toString().isNotEmpty
          ? e.toString()
          : 'Failed to create profile. Please try again.');
    } catch (_) {
      _setError('Failed to create profile. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  static const int _minPinLength = 4;
  static const int _maxPinLength = 6;

  Future<void> setPin(String pin, String confirm) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _setError('Please sign in again.');
      return;
    }
    if (pin.isEmpty) {
      _setError('Please enter a PIN.');
      return;
    }
    if (pin.length < _minPinLength || pin.length > _maxPinLength) {
      _setError('PIN must be 4–6 digits.');
      return;
    }
    if (pin != confirm) {
      _setError('PINs do not match.');
      return;
    }

    _setLoading(true, clearError: true);

    try {
      final hash = _authRepository.createPinHash(pin);
      await _authRepository.savePin(pin);
      await _authRepository.updatePinHash(uid: user.uid, pinHash: hash);
      _state = _state.copyWith(clearErrorMessage: true);
      notifyListeners();
    } catch (_) {
      _setError('Failed to save PIN. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUserProfile() async {
    final user = _state.firebaseUser;
    if (user == null) return;

    try {
      final snapshot = await _authRepository.getUserProfile(user.uid);
      if (snapshot.exists && snapshot.data() != null) {
        _state = _state.copyWith(userProfile: snapshot.data());
        notifyListeners();
      }
    } catch (_) {
      // Ignore; profile may load later
    }
  }

  String? get userRole => _state.userProfile?['role'] as String?;

  Future<bool> unlockWithPin(String pin) async {
    if (pin.isEmpty) {
      _setError('Please enter your PIN.');
      return false;
    }
    if (_state.requiresPinReauth) {
      _setError('Too many failed attempts. Re-authentication is required.');
      return false;
    }
    if (secondsUntilPinUnlock > 0) {
      _setError('PIN is temporarily locked. Try again in $secondsUntilPinUnlock seconds.');
      return false;
    }

    _setLoading(true, clearError: true);

    try {
      final valid = await _authRepository.verifyPin(pin);
      if (!valid) {
        final attempts = _state.pinFailedAttempts + 1;
        if (attempts >= 10) {
          _state = _state.copyWith(
            pinFailedAttempts: attempts,
            requiresPinReauth: true,
            isLoading: false,
            errorMessage: 'Too many failed attempts. Please re-authenticate to reset your PIN.',
          );
          notifyListeners();
          return false;
        }
        if (attempts % 5 == 0) {
          final lockUntil = DateTime.now().add(const Duration(seconds: 60));
          _state = _state.copyWith(
            pinFailedAttempts: attempts,
            pinLockUntilEpochMs: lockUntil.millisecondsSinceEpoch,
            isLoading: false,
            errorMessage: 'Too many attempts. PIN is locked for 60 seconds.',
          );
          _startPinLockTicker();
          notifyListeners();
          return false;
        }
        _state = _state.copyWith(
          pinFailedAttempts: attempts,
          isLoading: false,
          errorMessage: 'Incorrect PIN. Please try again.',
        );
        notifyListeners();
        return false;
      }
      _state = _state.copyWith(
        clearErrorMessage: true,
        pinFailedAttempts: 0,
        clearPinLockUntil: true,
        requiresPinReauth: false,
      );
      notifyListeners();
      return true;
    } catch (_) {
      _setError('Verification failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> reauthenticateWithPassword(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';
    if (user == null || email.isEmpty) {
      _setError('Email re-authentication is not available for this account.');
      return;
    }
    if (password.trim().isEmpty) {
      _setError('Please enter your password.');
      return;
    }
    _setLoading(true, clearError: true);
    try {
      await _authRepository.reauthenticateWithEmailPassword(
        email: email,
        password: password,
      );
      _state = _state.copyWith(clearErrorMessage: true);
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _setError(_firebaseErrorMessage(e));
    } catch (_) {
      _setError('Re-authentication failed. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendPinRecoveryOtp() async {
    final user = FirebaseAuth.instance.currentUser;
    final phone = user?.phoneNumber ?? '';
    if (user == null || phone.isEmpty) {
      _setError('Phone OTP is not available for this account.');
      return;
    }
    _setLoading(true, clearError: true);
    try {
      await _authRepository.sendReauthOtp(phone, (verificationId) {
        _recoveryVerificationId = verificationId;
      });
      _state = _state.copyWith(clearErrorMessage: true);
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _setError(_firebaseErrorMessage(e));
    } catch (_) {
      _setError('Failed to send OTP. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> reauthenticateWithRecoveryOtp(String smsCode) async {
    final verificationId = _recoveryVerificationId;
    if (verificationId == null) {
      _setError('No OTP request found. Please request a new code.');
      return;
    }
    if (smsCode.trim().isEmpty) {
      _setError('Please enter the OTP code.');
      return;
    }
    _setLoading(true, clearError: true);
    try {
      await _authRepository.reauthenticateWithPhoneOtp(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      _state = _state.copyWith(clearErrorMessage: true);
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _setError(_firebaseErrorMessage(e));
    } catch (_) {
      _setError('OTP verification failed. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPinAfterRecovery(String pin, String confirm) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _setError('Please sign in again.');
      return;
    }
    if (pin.isEmpty || confirm.isEmpty) {
      _setError('Please enter and confirm your new PIN.');
      return;
    }
    if (pin.length < _minPinLength || pin.length > _maxPinLength) {
      _setError('PIN must be 4–6 digits.');
      return;
    }
    if (pin != confirm) {
      _setError('PINs do not match.');
      return;
    }
    _setLoading(true, clearError: true);
    try {
      final hash = _authRepository.createPinHash(pin);
      await _authRepository.savePin(pin);
      await _authRepository.updatePinHash(uid: user.uid, pinHash: hash);
      _state = _state.copyWith(
        clearErrorMessage: true,
        pinFailedAttempts: 0,
        clearPinLockUntil: true,
        requiresPinReauth: false,
      );
      _recoveryVerificationId = null;
      notifyListeners();
    } catch (_) {
      _setError('Failed to reset PIN. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  void _startPinLockTicker() {
    _pinLockTicker?.cancel();
    _pinLockTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = secondsUntilPinUnlock;
      if (remaining <= 0) {
        timer.cancel();
        _state = _state.copyWith(clearPinLockUntil: true, clearErrorMessage: true);
        notifyListeners();
        return;
      }
      notifyListeners();
    });
  }

  void _setLoading(bool value, {bool clearError = false}) {
    _state = _state.copyWith(
      isLoading: value,
      clearErrorMessage: clearError,
    );
    notifyListeners();
  }

  void _setError(String message) {
    _state = _state.copyWith(
      isLoading: false,
      errorMessage: message,
    );
    notifyListeners();
  }

  String _firebaseErrorMessage(FirebaseAuthException e) {
    return e.message ?? 'Authentication error. Please try again.';
  }

  @override
  void dispose() {
    _pinLockTicker?.cancel();
    super.dispose();
  }

  /// Syncs local auth state after email/password sign-in (verified) completes.
  Future<void> setSessionAfterEmailAuth({
    required bool isNewUser,
    Map<String, dynamic>? userProfile,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await user.reload();
    final refreshed = FirebaseAuth.instance.currentUser ?? user;
    _state = _state.copyWith(
      firebaseUser: refreshed,
      isNewUser: isNewUser,
      userProfile: userProfile,
      clearErrorMessage: true,
    );
    notifyListeners();
  }

  /// Signs out email-only users who have not verified, after leaving the email flow.
  Future<void> signOutIfUnverifiedEmailOnly() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final hasPhone = user.phoneNumber != null && user.phoneNumber!.isNotEmpty;
    if (hasPhone) return;
    if (user.email != null &&
        user.email!.isNotEmpty &&
        !user.emailVerified) {
      await FirebaseAuth.instance.signOut();
      _state = const AuthState();
      notifyListeners();
    }
  }

  /// Register the current device's FCM token for the logged-in user.
  Future<void> registerFcmTokenIfNeeded() async {
    final user = _state.firebaseUser;
    if (user == null) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      await _authRepository.saveFcmToken(
        uid: user.uid,
        fcmToken: token,
      );
    } catch (_) {
      // Best-effort; ignore errors here.
    }
  }
}
