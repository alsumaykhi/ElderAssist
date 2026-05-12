import '../services/check_in_service.dart';

class CheckInRepository {
  CheckInRepository({required CheckInService checkInService})
      : _checkInService = checkInService;

  final CheckInService _checkInService;

  Future<void> confirmToday(String uid) => _checkInService.confirmToday(uid);

  Future<void> markMissedIfNeeded(String uid) =>
      _checkInService.markMissedIfNeeded(uid);

  Future<bool> hasCheckedInToday(String uid) =>
      _checkInService.hasCheckedInToday(uid);
}

