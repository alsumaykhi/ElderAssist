import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/notification_service.dart';
import '../repository/check_in_repository.dart';

class CheckInProvider extends ChangeNotifier {
  CheckInProvider({
    required CheckInRepository checkInRepository,
    required NotificationService notificationService,
  })  : _checkInRepository = checkInRepository,
        _notificationService = notificationService;

  final CheckInRepository _checkInRepository;
  final NotificationService _notificationService;

  bool _isCheckedInToday = false;
  bool get isCheckedInToday => _isCheckedInToday;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadTodayStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _isCheckedInToday = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _isCheckedInToday = await _checkInRepository.hasCheckedInToday(uid);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> confirmToday() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _checkInRepository.confirmToday(uid);
      _isCheckedInToday = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Run after the cutoff time to mark today as missed if not confirmed.
  Future<void> runCutoffCheck(String cutoffTime) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (!_isAfterCutoff(cutoffTime)) return;

    if (!_isCheckedInToday) {
      await _checkInRepository.markMissedIfNeeded(uid);
      // Do not flip _isCheckedInToday to true, since status is "missed".
      notifyListeners();
    }
  }

  /// Schedule daily reminder and cutoff notifications based on cutoff time.
  Future<void> scheduleDailyReminders(String cutoffTime) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final parts = cutoffTime.split(':');
    if (parts.length < 2) return;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return;

    final reminderHour = (hour + 23) % 24;
    final reminderTime =
        '${reminderHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    final reminderId = _notificationId(uid, 'checkin_reminder');
    final cutoffId = _notificationId(uid, 'checkin_cutoff');

    await _notificationService.scheduleDailyCheckInNotification(
      timeStr: reminderTime,
      id: reminderId,
      title: 'Daily check-in',
      body: 'Please confirm you are okay today.',
    );

    await _notificationService.scheduleDailyCheckInNotification(
      timeStr: cutoffTime,
      id: cutoffId,
      title: 'Check-in window closing',
      body: 'Last chance to confirm you are okay today.',
    );
  }

  bool _isAfterCutoff(String cutoffTime) {
    final parts = cutoffTime.split(':');
    if (parts.length < 2) return false;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return false;

    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day, hour, minute);
    return now.isAfter(cutoff);
  }

  int _notificationId(String uid, String type) {
    final hash = Object.hash(type, uid);
    return hash & 0x7FFFFFFF;
  }
}

