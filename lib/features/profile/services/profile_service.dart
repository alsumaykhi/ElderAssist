import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';

/// Low-level service for Firestore user profile operations.
class ProfileService {
  ProfileService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> saveProfile(UserProfile profile) async {
    final map = profile.toMap();
    map.remove('createdAt');
    map['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection('users').doc(profile.uid).set(
          map,
          SetOptions(merge: true),
        );
  }
}
