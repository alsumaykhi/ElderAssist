/// Stored in Firestore as `type` on each medication document.
enum MedicationType {
  medication,
  supplement;

  String get firestoreValue => name;

  static MedicationType fromFirestore(Object? raw) {
    if (raw == 'supplement') return MedicationType.supplement;
    return MedicationType.medication;
  }
}
