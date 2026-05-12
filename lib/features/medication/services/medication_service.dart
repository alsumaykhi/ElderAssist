import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/medication.dart';

class MedicationService {
  MedicationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _medicationsRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('medications');

  Future<void> addMedication(String userId, Medication medication) async {
    final colRef = _medicationsRef(userId);
    final docRef = medication.id.isEmpty ? colRef.doc() : colRef.doc(medication.id);
    final id = medication.id.isEmpty ? docRef.id : medication.id;
    final toSave = medication.copyWith(id: id);

    await docRef.set(toSave.toMap());
  }

  Future<void> updateMedication(String userId, Medication medication) async {
    await _medicationsRef(userId).doc(medication.id).update(medication.toMap());
  }

  Future<List<Medication>> fetchMedications(String userId) async {
    final snapshot = await _medicationsRef(userId).get();

    return snapshot.docs
        .map((doc) => Medication.fromMap(doc.data(), docId: doc.id))
        .toList();
  }

  Future<void> deleteMedication(String userId, String medicationId) async {
    await _medicationsRef(userId).doc(medicationId).delete();
  }
}
