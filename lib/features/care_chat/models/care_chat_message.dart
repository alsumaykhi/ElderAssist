import 'package:cloud_firestore/cloud_firestore.dart';

import 'care_chat_message_type.dart';
import 'medication_proposal_payload.dart';

class CareChatMessage {
  const CareChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.type,
    required this.status,
    this.text,
    this.mediaUrl,
    this.mediaPath,
    this.proposal,
    this.createdAt,
    this.updatedAt,
    this.expiresAt,
    this.respondedAt,
  });

  final String id;
  final String chatId;
  final String senderId;
  final CareChatMessageType type;
  final String status;
  final String? text;
  final String? mediaUrl;
  final String? mediaPath;
  final MedicationProposalPayload? proposal;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;
  final DateTime? respondedAt;

  bool get isProposal =>
      type == CareChatMessageType.medicationProposal ||
      type == CareChatMessageType.medicationEditProposal;

  bool get isPendingProposal => isProposal && status == 'pending';

  factory CareChatMessage.fromFirestore(
    String chatId,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final payload = data['payload'];
    final createdAt = data['createdAt'];
    final updatedAt = data['updatedAt'];
    final expiresAt = data['expiresAt'];
    final respondedAt = data['respondedAt'];

    return CareChatMessage(
      id: doc.id,
      chatId: chatId,
      senderId: data['senderId'] as String? ?? '',
      type: CareChatMessageType.fromFirestore(data['type'] as String?),
      status: data['status'] as String? ?? 'active',
      text: data['text'] as String?,
      mediaUrl: data['mediaUrl'] as String?,
      mediaPath: data['mediaPath'] as String?,
      proposal: payload is Map<String, dynamic>
          ? MedicationProposalPayload.fromMap(payload)
          : (payload is Map
              ? MedicationProposalPayload.fromMap(
                  payload.map((k, v) => MapEntry(k.toString(), v)),
                )
              : null),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : null,
      expiresAt: expiresAt is Timestamp ? expiresAt.toDate() : null,
      respondedAt: respondedAt is Timestamp ? respondedAt.toDate() : null,
    );
  }
}
