import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import '../repository/profile_repository.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository;

  final ProfileRepository _profileRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> saveProfile(UserProfile profile) async {
    _errorMessage = _validateProfile(profile);
    if (_errorMessage != null) {
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileRepository.saveProfile(profile);
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Failed to save profile. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? _validateProfile(UserProfile profile) {
    if (profile.firstName.trim().isEmpty) {
      return 'First name is required.';
    }
    if (profile.lastName.trim().isEmpty) {
      return 'Last name is required.';
    }
    if (profile.isSenior) {
      if (profile.age == null || profile.age! < 1 || profile.age! > 150) {
        return 'Please enter a valid age (1–150).';
      }
      if (profile.emergencyContactName == null ||
          profile.emergencyContactName!.trim().isEmpty) {
        return 'Emergency contact name is required.';
      }
      if (profile.emergencyContactPhone == null ||
          profile.emergencyContactPhone!.trim().isEmpty) {
        return 'Emergency contact phone is required.';
      }
    }
    return null;
  }
}
