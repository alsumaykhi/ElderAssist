import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/medication.dart';
import '../services/adherence_service.dart';

class AdherenceProvider extends ChangeNotifier {
  AdherenceProvider({
    required AdherenceService adherenceService,
  }) : _adherenceService = adherenceService;

  final AdherenceService _adherenceService;

  Map<String, String> _doseStatus = {};
  Map<String, String> get doseStatus =>
      Map<String, String>.unmodifiable(_doseStatus);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  String _key(String medId, String scheduledTime) => '$medId|$scheduledTime';

  bool isDoseTaken(String medId, String scheduledTime) {
    return _doseStatus[_key(medId, scheduledTime)] == 'taken';
  }

  bool isDoseMissed(String medId, String scheduledTime) {
    return _doseStatus[_key(medId, scheduledTime)] == 'missed';
  }

  bool isMedicationActiveToday(Medication medication) {
    if (!medication.isActive) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start =
        DateTime(medication.startDate.year, medication.startDate.month, medication.startDate.day);

    if (today.isBefore(start)) return false;

    if (medication.endDate != null) {
      final end = DateTime(
        medication.endDate!.year,
        medication.endDate!.month,
        medication.endDate!.day,
      );
      if (today.isAfter(end)) return false;
    }

    return true;
  }

  Future<void> loadTodayDoseStatus(List<Medication> medications) async {
    final uid = _userId;
    if (uid == null) {
      _doseStatus = {};
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    final Map<String, String> result = {};

    try {
      for (final med in medications) {
        if (!isMedicationActiveToday(med)) continue;
        for (final time in med.times) {
          final status = await _adherenceService.getDoseStatusToday(
            seniorUid: uid,
            medId: med.id,
            scheduledTime: time,
          );
          if (status == 'taken' || status == 'missed') {
            result[_key(med.id, time)] = status!;
          }
        }
      }

      _doseStatus = result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> detectMissedDosesForToday() async {
    final uid = _userId;
    if (uid == null) return;
    await _adherenceService.detectMissedDosesForToday(uid);
  }

  Future<void> refreshForToday(List<Medication> medications) async {
    await detectMissedDosesForToday();
    await loadTodayDoseStatus(medications);
  }

  Future<void> markTaken(String medId, String scheduledTime) async {
    final uid = _userId;
    if (uid == null) return;

    final key = _key(medId, scheduledTime);
    if (_doseStatus[key] == 'taken' || _doseStatus[key] == 'missed') {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _adherenceService.markDoseTaken(
        seniorUid: uid,
        medId: medId,
        scheduledTime: scheduledTime,
      );
      _doseStatus[key] = 'taken';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

