import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Low-level service for caregiver-senior linking via 6-digit codes.
class LinkingService {
  LinkingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final Random _random = Random();

  static const int _maxAttempts = 20;

  Future<String> generateLinkCode(String caregiverUid) async {
    for (var i = 0; i < _maxAttempts; i++) {
      final code = _generateRandomCode();

      final doc = await _firestore
          .collection('linkCodes')
          .doc(code)
          .get();

      if (!doc.exists) {
        await _firestore.collection('linkCodes').doc(code).set({
          'code': code,
          'caregiverId': caregiverUid,
          'createdAt': FieldValue.serverTimestamp(),
          'isUsed': false,
          'usedBy': null,
          'usedAt': null,
        });
        return code;
      }
    }
    throw StateError('Could not generate unique link code after $_maxAttempts attempts');
  }

  Future<bool> validateAndLink({
    required String code,
    required String seniorUid,
  }) async {
    if (code.length != 6 || !RegExp(r'^\d+$').hasMatch(code)) {
      return false;
    }

    final doc = await _firestore.collection('linkCodes').doc(code).get();

    if (!doc.exists) return false;

    final data = doc.data();
    if (data == null) return false;

    final isUsed = data['isUsed'] as bool? ?? true;
    if (isUsed) return false;

    final caregiverId = data['caregiverId'] as String?;
    if (caregiverId == null || caregiverId.isEmpty) return false;

    final batch = _firestore.batch();

    final seniorRef = _firestore.collection('users').doc(seniorUid);
    batch.update(seniorRef, {'caregiverId': caregiverId});

    final caregiverRef = _firestore.collection('users').doc(caregiverId);
    batch.update(caregiverRef, {
      'seniorIds': FieldValue.arrayUnion([seniorUid]),
    });

    final linkCodeRef = _firestore.collection('linkCodes').doc(code);
    batch.update(linkCodeRef, {
      'isUsed': true,
      'usedBy': seniorUid,
      'usedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return true;
  }

  String _generateRandomCode() {
    final n = _random.nextInt(900000) + 100000;
    return n.toString();
  }
}
