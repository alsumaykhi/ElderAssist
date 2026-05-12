import 'package:cloud_firestore/cloud_firestore.dart';

class AdherenceService {
  AdherenceService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _medicationsRef(String seniorUid) {
    return _firestore.collection('users').doc(seniorUid).collection('medications');
  }

  CollectionReference<Map<String, dynamic>> _doseLogsRef(
    String seniorUid,
    String medId,
  ) {
    return _medicationsRef(seniorUid).doc(medId).collection('doseLogs');
  }

  String _todayDateKey() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _doseLogId(String date, String scheduledTime) => '${date}_$scheduledTime';

  String _todayDoseLogId(String scheduledTime) => _doseLogId(_todayDateKey(), scheduledTime);

  DateTime? _scheduledDateTimeToday(String scheduledTime) {
    final parts = scheduledTime.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  Future<void> markDoseTaken({
    required String seniorUid,
    required String medId,
    required String scheduledTime,
  }) async {
    final docRef = _doseLogsRef(seniorUid, medId).doc(_todayDoseLogId(scheduledTime));
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(docRef);
      if (existing.exists) {
        return;
      }

      transaction.set(docRef, {
        'scheduledTime': scheduledTime,
        'status': 'taken',
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<String?> getDoseStatusToday({
    required String seniorUid,
    required String medId,
    required String scheduledTime,
  }) async {
    final doc = await _doseLogsRef(
      seniorUid,
      medId,
    ).doc(_todayDoseLogId(scheduledTime)).get();
    if (!doc.exists) return null;
    final data = doc.data();
    return data?['status'] as String?;
  }

  Future<void> detectMissedDosesForToday(String seniorUid) async {
    final now = DateTime.now();
    final todayKey = _todayDateKey();
    final medicationsSnapshot = await _medicationsRef(seniorUid).get();

    for (final medDoc in medicationsSnapshot.docs) {
      final medData = medDoc.data();
      final isActive = medData['isActive'] as bool? ?? true;
      if (!isActive) continue;

      final startDateValue = medData['startDate'];
      final endDateValue = medData['endDate'];
      final today = DateTime(now.year, now.month, now.day);

      if (startDateValue is Timestamp) {
        final start = startDateValue.toDate();
        final startDate = DateTime(start.year, start.month, start.day);
        if (today.isBefore(startDate)) continue;
      }

      if (endDateValue is Timestamp) {
        final end = endDateValue.toDate();
        final endDate = DateTime(end.year, end.month, end.day);
        if (today.isAfter(endDate)) continue;
      }

      final times = (medData['times'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[];

      for (final scheduledTime in times) {
        final scheduled = _scheduledDateTimeToday(scheduledTime);
        if (scheduled == null) continue;

        final graceCutoff = scheduled.add(const Duration(minutes: 30));
        if (!now.isAfter(graceCutoff)) continue;

        final doseDocRef = _doseLogsRef(
          seniorUid,
          medDoc.id,
        ).doc(_doseLogId(todayKey, scheduledTime));

        await _firestore.runTransaction((transaction) async {
          final existing = await transaction.get(doseDocRef);
          if (existing.exists) {
            return;
          }

          transaction.set(doseDocRef, {
            'scheduledTime': scheduledTime,
            'status': 'missed',
            'timestamp': FieldValue.serverTimestamp(),
          });
        });
      }
    }
  }
}

