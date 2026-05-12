import 'package:cloud_firestore/cloud_firestore.dart';

import 'medication_type.dart';

class Medication {
  const Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.times,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    required this.createdAt,
    this.type = MedicationType.medication,
  });

  final String id;
  final String name;
  final String dosage;
  final List<String> times;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;
  final MedicationType type;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'times': times,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'type': type.firestoreValue,
    };
  }

  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    List<String>? times,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
    MedicationType? type,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      times: times ?? List<String>.from(this.times),
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
    );
  }

  factory Medication.fromMap(Map<String, dynamic> map, {String? docId}) {
    final createdAt = map['createdAt'];
    final startDate = map['startDate'];
    final endDateVal = map['endDate'];

    return Medication(
      id: docId ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      dosage: map['dosage'] as String? ?? '',
      times: (map['times'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      startDate: startDate is Timestamp
          ? startDate.toDate()
          : DateTime.now(),
      endDate: endDateVal is Timestamp ? endDateVal.toDate() : null,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.now(),
      type: MedicationType.fromFirestore(map['type']),
    );
  }
}
