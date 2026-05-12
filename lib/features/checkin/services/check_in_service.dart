import 'package:cloud_firestore/cloud_firestore.dart';

class CheckInService {
  CheckInService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _checkInsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('checkIns');

  String _todayKey() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> confirmToday(String seniorUid) async {
    final today = _todayKey();

    final checkInRef = _checkInsRef(seniorUid).doc(today);
    final ts = FieldValue.serverTimestamp();

    await checkInRef.set({
      'date': today,
      'timestamp': ts,
      'status': 'confirmed',
    });

    await _firestore.collection('users').doc(seniorUid).update({
      'lastCheckIn': ts,
    });
  }

  Future<void> markMissedIfNeeded(String seniorUid) async {
    final today = _todayKey();
    final doc = await _checkInsRef(seniorUid).doc(today).get();
    if (doc.exists) return;

    await _checkInsRef(seniorUid).doc(today).set({
      'date': today,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'missed',
    });
  }

  Future<bool> hasCheckedInToday(String seniorUid) async {
    final today = _todayKey();
    final doc = await _checkInsRef(seniorUid).doc(today).get();
    if (!doc.exists) return false;
    final data = doc.data();
    return (data?['status'] as String?) == 'confirmed';
  }
}

