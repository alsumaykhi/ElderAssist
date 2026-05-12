class MedicationProposalPayload {
  const MedicationProposalPayload({
    this.medicationId,
    required this.name,
    required this.dosage,
    required this.time,
    this.notes,
  });

  final String? medicationId;
  final String name;
  final String dosage;
  final String time;
  final String? notes;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (medicationId != null && medicationId!.isNotEmpty)
        'medicationId': medicationId,
      'name': name,
      'dosage': dosage,
      'time': time,
      'notes': notes ?? '',
    };
  }

  factory MedicationProposalPayload.fromMap(Map<String, dynamic> map) {
    return MedicationProposalPayload(
      medicationId: map['medicationId'] as String?,
      name: map['name'] as String? ?? '',
      dosage: map['dosage'] as String? ?? '',
      time: map['time'] as String? ?? '',
      notes: (map['notes'] as String?)?.trim(),
    );
  }
}
