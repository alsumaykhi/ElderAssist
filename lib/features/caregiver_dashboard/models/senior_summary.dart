import 'status_models.dart';

/// Summary of a linked senior for the caregiver dashboard.
class SeniorSummary {
  const SeniorSummary({
    required this.uid,
    required this.firstName,
    required this.lastName,
    this.age,
    this.gender,
    this.lastCheckIn,
    required this.medicationCount,
    required this.checkInStatusToday,
    required this.totalDosesScheduledToday,
    required this.dosesTakenToday,
    required this.dosesMissedToday,
    required this.adherencePercentage,
    this.nextMedicationTime,
    required this.alertLevel,
  });

  final String uid;
  final String firstName;
  final String lastName;
  final int? age;
  final String? gender;
  final DateTime? lastCheckIn;
  final int medicationCount;
  final CheckInStatus checkInStatusToday;
  final int totalDosesScheduledToday;
  final int dosesTakenToday;
  final int dosesMissedToday;
  final double adherencePercentage;
  final DateTime? nextMedicationTime;
  final AlertLevel alertLevel;

  String get fullName => '$firstName $lastName'.trim();
}
