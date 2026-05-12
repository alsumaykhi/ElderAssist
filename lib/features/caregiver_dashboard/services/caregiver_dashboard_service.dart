import 'package:cloud_firestore/cloud_firestore.dart';

import '../../checkin/models/check_in.dart';
import '../models/dashboard_data.dart';
import '../models/dashboard_summary.dart';
import '../models/senior_detail.dart';
import '../models/senior_summary.dart';
import '../models/status_models.dart';

/// Service for fetching caregiver dashboard data from Firestore.
class CaregiverDashboardService {
  CaregiverDashboardService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _usersRef() =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> _medicationsRef(String seniorUid) =>
      _usersRef().doc(seniorUid).collection('medications');

  CollectionReference<Map<String, dynamic>> _checkInsRef(String seniorUid) =>
      _usersRef().doc(seniorUid).collection('checkIns');

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime? _scheduledDateTime(DateTime day, String scheduledTime) {
    final parts = scheduledTime.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  bool _isMedicationActiveOnDay(
    Map<String, dynamic> medData,
    DateTime day,
  ) {
    final isActive = medData['isActive'] as bool? ?? true;
    if (!isActive) return false;

    final dayStart = _startOfDay(day);

    final startDateValue = medData['startDate'];
    if (startDateValue is Timestamp) {
      final startDate = _startOfDay(startDateValue.toDate());
      if (dayStart.isBefore(startDate)) return false;
    }

    final endDateValue = medData['endDate'];
    if (endDateValue is Timestamp) {
      final endDate = _startOfDay(endDateValue.toDate());
      if (dayStart.isAfter(endDate)) return false;
    }

    return true;
  }

  Future<List<String>> _seniorIdsForCaregiver(String caregiverUid) async {
    final caregiverDoc = await _usersRef().doc(caregiverUid).get();
    if (!caregiverDoc.exists) return <String>[];
    final data = caregiverDoc.data();
    final ids = data?['seniorIds'] as List<dynamic>? ?? <dynamic>[];
    return ids.map((e) => e.toString()).where((id) => id.isNotEmpty).toList();
  }

  Future<String?> _doseLogStatusForDate({
    required String seniorUid,
    required String medicationId,
    required String dateKey,
    required String scheduledTime,
  }) async {
    final doseId = '${dateKey}_$scheduledTime';
    final doseDoc = await _medicationsRef(seniorUid)
        .doc(medicationId)
        .collection('doseLogs')
        .doc(doseId)
        .get();
    if (!doseDoc.exists) return null;
    return doseDoc.data()?['status'] as String?;
  }

  Future<Map<String, int>> _doseCountsForDate({
    required String seniorUid,
    required DateTime date,
  }) async {
    final medicationsSnapshot = await _medicationsRef(seniorUid).get();
    final dateKey = _dateKey(date);
    var total = 0;
    var taken = 0;
    var missed = 0;

    for (final medDoc in medicationsSnapshot.docs) {
      final medData = medDoc.data();
      if (!_isMedicationActiveOnDay(medData, date)) continue;

      final times = (medData['times'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[];
      total += times.length;

      final statuses = await Future.wait(
        times.map(
          (time) => _doseLogStatusForDate(
            seniorUid: seniorUid,
            medicationId: medDoc.id,
            dateKey: dateKey,
            scheduledTime: time,
          ),
        ),
      );
      for (final status in statuses) {
        if (status == 'taken') taken += 1;
        if (status == 'missed') missed += 1;
      }
    }

    return <String, int>{
      'total': total,
      'taken': taken,
      'missed': missed,
    };
  }

  DashboardSummary _buildOverviewSummary(List<SeniorSummary> seniors) {
    var checkedIn = 0;
    var missedCheckIn = 0;
    var missedMedication = 0;
    for (final senior in seniors) {
      if (senior.checkInStatusToday == CheckInStatus.confirmed) checkedIn += 1;
      if (senior.checkInStatusToday == CheckInStatus.missed) missedCheckIn += 1;
      missedMedication += senior.dosesMissedToday;
    }

    return DashboardSummary(
      totalSeniors: seniors.length,
      checkedInCount: checkedIn,
      missedCheckInCount: missedCheckIn,
      missedMedicationCount: missedMedication,
    );
  }

  Future<DashboardData> fetchDashboardData(String caregiverUid) async {
    final seniors = await fetchLinkedSeniors(caregiverUid);
    final summary = _buildOverviewSummary(seniors);
    return DashboardData(summary: summary, seniors: seniors);
  }

  Future<List<SeniorSummary>> fetchLinkedSeniors(String caregiverUid) async {
    final seniorIds = await _seniorIdsForCaregiver(caregiverUid);
    if (seniorIds.isEmpty) return <SeniorSummary>[];

    final seniors = <SeniorSummary>[];
    final now = DateTime.now();
    final today = _startOfDay(now);
    final todayKey = _dateKey(today);

    final seniorDocs = await Future.wait(
      seniorIds.map((seniorUid) => _usersRef().doc(seniorUid).get()),
    );

    for (final seniorDoc in seniorDocs) {
      if (!seniorDoc.exists) continue;
      final seniorUid = seniorDoc.id;

      final seniorData = seniorDoc.data();
      if (seniorData == null) continue;

      final medsSnapshot = await _medicationsRef(seniorUid).get();

      var medicationCount = 0;
      var totalScheduled = 0;
      var dosesTaken = 0;
      var dosesMissed = 0;
      DateTime? nextMedicationTime;

      for (final medDoc in medsSnapshot.docs) {
        final medData = medDoc.data();
        if (!_isMedicationActiveOnDay(medData, today)) continue;
        medicationCount += 1;

        final times = (medData['times'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>[];

        totalScheduled += times.length;

        final statuses = await Future.wait(
          times.map(
            (time) => _doseLogStatusForDate(
              seniorUid: seniorUid,
              medicationId: medDoc.id,
              dateKey: todayKey,
              scheduledTime: time,
            ),
          ),
        );

        for (var i = 0; i < times.length; i++) {
          final time = times[i];
          final scheduled = _scheduledDateTime(today, time);
          if (scheduled != null && scheduled.isAfter(now)) {
            if (nextMedicationTime == null || scheduled.isBefore(nextMedicationTime)) {
              nextMedicationTime = scheduled;
            }
          }

          final status = statuses[i];
          if (status == 'taken') dosesTaken += 1;
          if (status == 'missed') dosesMissed += 1;
        }
      }

      DateTime? lastCheckIn;
      final lastCheckInVal = seniorData['lastCheckIn'];
      if (lastCheckInVal is Timestamp) {
        lastCheckIn = lastCheckInVal.toDate();
      }

      final checkInDoc = await _checkInsRef(seniorUid).doc(todayKey).get();
      final checkInStatusToday = checkInDoc.exists
          ? CheckInStatusParsing.fromFirestore(
              checkInDoc.data()?['status'] as String?,
            )
          : CheckInStatus.pending;

      final adherencePercentage = totalScheduled == 0
          ? 100.0
          : (dosesTaken / totalScheduled) * 100.0;

      final alertLevel = checkInStatusToday == CheckInStatus.missed
          ? AlertLevel.critical
          : (dosesMissed > 0 && checkInStatusToday == CheckInStatus.confirmed)
              ? AlertLevel.warning
              : AlertLevel.normal;

      seniors.add(
        SeniorSummary(
          uid: seniorUid,
          firstName: seniorData['firstName'] as String? ?? '',
          lastName: seniorData['lastName'] as String? ?? '',
          age: seniorData['age'] as int?,
          gender: seniorData['gender'] as String?,
          lastCheckIn: lastCheckIn,
          medicationCount: medicationCount,
          checkInStatusToday: checkInStatusToday,
          totalDosesScheduledToday: totalScheduled,
          dosesTakenToday: dosesTaken,
          dosesMissedToday: dosesMissed,
          adherencePercentage: adherencePercentage,
          nextMedicationTime: nextMedicationTime,
          alertLevel: alertLevel,
        ),
      );
    }

    return seniors;
  }

  Future<List<CheckIn>> fetchLast7Days(String seniorUid) async {
    final now = DateTime.now();
    final last7Keys = List<String>.generate(
      7,
      (index) => _dateKey(_startOfDay(now.subtract(Duration(days: index)))),
    );
    final byDate = <String, CheckIn>{};

    final checkInDocs = await Future.wait(
      last7Keys.map((dateKey) => _checkInsRef(seniorUid).doc(dateKey).get()),
    );
    for (final doc in checkInDocs) {
      if (!doc.exists) continue;
      final data = doc.data() ?? <String, dynamic>{};
      byDate[doc.id] = CheckIn.fromMap(data);
    }

    return last7Keys.map((key) {
      final existing = byDate[key];
      if (existing != null) return existing;
      return CheckIn(
        date: key,
        timestamp: now,
        status: 'missed',
      );
    }).toList();
  }

  Future<double> computeWeeklyAdherence(String seniorUid) async {
    final now = DateTime.now();
    var totalScheduled = 0;
    var totalTaken = 0;

    final days = List<DateTime>.generate(
      7,
      (i) => _startOfDay(now.subtract(Duration(days: i))),
    );
    final weeklyCounts = await Future.wait(
      days.map((day) => _doseCountsForDate(seniorUid: seniorUid, date: day)),
    );
    for (final counts in weeklyCounts) {
      totalScheduled += counts['total'] ?? 0;
      totalTaken += counts['taken'] ?? 0;
    }

    if (totalScheduled == 0) return 100.0;
    return (totalTaken / totalScheduled) * 100.0;
  }

  Future<SeniorDetail> fetchSeniorDetail(String seniorUid) async {
    final userDoc = await _usersRef().doc(seniorUid).get();
    final userData = userDoc.data() ?? <String, dynamic>{};
    final firstName = userData['firstName'] as String? ?? '';
    final lastName = userData['lastName'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();
    final age = userData['age'] as int?;
    final gender = userData['gender'] as String?;
    final conditions = (userData['chronicConditions'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];
    final allergies = (userData['allergies'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];

    final now = DateTime.now();
    final today = _startOfDay(now);
    final todayKey = _dateKey(today);

    final medsSnapshot = await _medicationsRef(seniorUid).get();
    final todaysMedication = <SeniorMedicationStatus>[];

    for (final medDoc in medsSnapshot.docs) {
      final medData = medDoc.data();
      if (!_isMedicationActiveOnDay(medData, today)) continue;
      final medName = medData['name'] as String? ?? 'Medication';
      final times = (medData['times'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[];
      final statusByTime = <String, String>{};

      final statuses = await Future.wait(
        times.map(
          (time) => _doseLogStatusForDate(
            seniorUid: seniorUid,
            medicationId: medDoc.id,
            dateKey: todayKey,
            scheduledTime: time,
          ),
        ),
      );
      for (var i = 0; i < times.length; i++) {
        statusByTime[times[i]] = statuses[i] ?? 'pending';
      }

      todaysMedication.add(
        SeniorMedicationStatus(
          medicationName: medName,
          scheduledTimes: times,
          statusByTime: statusByTime,
        ),
      );
    }

    final history = await fetchLast7Days(seniorUid);
    final weeklyAdherence = await computeWeeklyAdherence(seniorUid);

    return SeniorDetail(
      uid: seniorUid,
      fullName: fullName.isEmpty ? 'Senior' : fullName,
      age: age,
      gender: gender,
      conditions: conditions,
      allergies: allergies,
      last7DaysCheckIns: history,
      todaysMedication: todaysMedication,
      weeklyAdherencePercentage: weeklyAdherence,
    );
  }
}

