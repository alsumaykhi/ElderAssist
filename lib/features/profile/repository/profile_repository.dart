import '../models/user_profile.dart';
import '../services/profile_service.dart';

class ProfileRepository {
  ProfileRepository({required ProfileService profileService})
      : _profileService = profileService;

  final ProfileService _profileService;

  Future<void> saveProfile(UserProfile profile) =>
      _profileService.saveProfile(profile);
}
