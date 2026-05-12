import 'package:cloud_firestore/cloud_firestore.dart';

import 'chat_role.dart';
import 'suggested_supplement.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.emergency = false,
    this.suggestedSupplements = const [],
  });

  final String id;
  final ChatRole role;
  final String text;
  final DateTime? createdAt;
  final bool emergency;
  final List<SuggestedSupplement> suggestedSupplements;

  factory ChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final createdAt = data['createdAt'];
    final rawList = data['suggestedSupplements'];
    final supplements = <SuggestedSupplement>[];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          final s = SuggestedSupplement.fromJson(item);
          if (s.name.isNotEmpty) supplements.add(s);
        } else if (item is Map) {
          final s = SuggestedSupplement.fromJson(
            item.map((k, v) => MapEntry(k.toString(), v)),
          );
          if (s.name.isNotEmpty) supplements.add(s);
        }
      }
    }
    return ChatMessage(
      id: doc.id,
      role: ChatRole.fromFirestore(data['role'] as String?),
      text: data['text'] as String? ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      emergency: data['emergency'] as bool? ?? false,
      suggestedSupplements: supplements,
    );
  }
}
