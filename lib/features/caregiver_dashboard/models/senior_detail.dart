import '../../checkin/models/check_in.dart';

class SeniorMedicationStatus {
  const SeniorMedicationStatus({
    required this.medicationName,
    required this.scheduledTimes,
    required this.statusByTime,
  });

  final String medicationName;
  final List<String> scheduledTimes;
  final Map<String, String> statusByTime;
}

class SeniorDetail {
  const SeniorDetail({
    required this.uid,
    required this.fullName,
    this.age,
    this.gender,
    required this.conditions,
    required this.allergies,
    required this.last7DaysCheckIns,
    required this.todaysMedication,
    required this.weeklyAdherencePercentage,
  });

  final String uid;
  final String fullName;
  final int? age;
  final String? gender;
  final List<String> conditions;
  final List<String> allergies;
  final List<CheckIn> last7DaysCheckIns;
  final List<SeniorMedicationStatus> todaysMedication;
  final double weeklyAdherencePercentage;
}

