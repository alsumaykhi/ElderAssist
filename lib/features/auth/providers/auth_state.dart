import 'package:firebase_auth/firebase_auth.dart';

class AuthState {
  const AuthState({
    this.isLoading = false,
    this.verificationId,
    this.errorMessage,
    this.firebaseUser,
    this.isNewUser = false,
    this.userProfile,
    this.pinFailedAttempts = 0,
    this.pinLockUntilEpochMs,
    this.requiresPinReauth = false,
  });

  final bool isLoading;
  final String? verificationId;
  final String? errorMessage;
  final User? firebaseUser;
  final bool isNewUser;
  final Map<String, dynamic>? userProfile;
  final int pinFailedAttempts;
  final int? pinLockUntilEpochMs;
  final bool requiresPinReauth;

  AuthState copyWith({
    bool? isLoading,
    String? verificationId,
    String? errorMessage,
    bool clearErrorMessage = false,
    User? firebaseUser,
    bool? isNewUser,
    Map<String, dynamic>? userProfile,
    bool clearUserProfile = false,
    int? pinFailedAttempts,
    int? pinLockUntilEpochMs,
    bool clearPinLockUntil = false,
    bool? requiresPinReauth,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      verificationId: verificationId ?? this.verificationId,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      firebaseUser: firebaseUser ?? this.firebaseUser,
      isNewUser: isNewUser ?? this.isNewUser,
      userProfile: clearUserProfile ? null : (userProfile ?? this.userProfile),
      pinFailedAttempts: pinFailedAttempts ?? this.pinFailedAttempts,
      pinLockUntilEpochMs: clearPinLockUntil ?
        null :
        (pinLockUntilEpochMs ?? this.pinLockUntilEpochMs),
      requiresPinReauth: requiresPinReauth ?? this.requiresPinReauth,
    );
  }
}
