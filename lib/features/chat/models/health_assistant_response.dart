import 'suggested_supplement.dart';

class HealthAssistantResponse {
  const HealthAssistantResponse({
    required this.replyText,
    required this.emergency,
    required this.suggestedSupplements,
    this.symptomSummary,
  });

  final String replyText;
  final bool emergency;
  final List<SuggestedSupplement> suggestedSupplements;
  final String? symptomSummary;

  factory HealthAssistantResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['suggestedSupplements'];
    final list = <SuggestedSupplement>[];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          final s = SuggestedSupplement.fromJson(item);
          if (s.name.isNotEmpty) list.add(s);
        } else if (item is Map) {
          final s = SuggestedSupplement.fromJson(
            item.map((k, v) => MapEntry(k.toString(), v)),
          );
          if (s.name.isNotEmpty) list.add(s);
        }
      }
    }
    return HealthAssistantResponse(
      replyText: json['replyText'] as String? ?? '',
      emergency: json['emergency'] as bool? ?? false,
      suggestedSupplements: list,
      symptomSummary: json['symptomSummary'] as String?,
    );
  }
}
