class SuggestedSupplement {
  const SuggestedSupplement({
    required this.name,
    required this.dosage,
    this.safetyNote,
  });

  final String name;
  final String dosage;
  final String? safetyNote;

  factory SuggestedSupplement.fromJson(Map<String, dynamic> json) {
    return SuggestedSupplement(
      name: (json['name'] as String? ?? '').trim(),
      dosage: (json['dosage'] as String? ?? '').trim(),
      safetyNote: (json['safetyNote'] as String?)?.trim(),
    );
  }
}
