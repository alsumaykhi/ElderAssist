import 'dart:typed_data';
import 'dart:io';

import '../models/care_chat_message.dart';
import '../models/care_chat_message_type.dart';
import '../models/medication_proposal_payload.dart';
import '../services/care_chat_service.dart';

class CareChatRepository {
  CareChatRepository({required CareChatService careChatService})
      : _careChatService = careChatService;

  final CareChatService _careChatService;

  String buildChatId({
    required String caregiverId,
    required String seniorId,
  }) =>
      _careChatService.buildChatId(caregiverId: caregiverId, seniorId: seniorId);

  Future<bool> areUsersLinked({
    required String caregiverId,
    required String seniorId,
  }) =>
      _careChatService.areUsersLinked(caregiverId: caregiverId, seniorId: seniorId);

  Future<String?> caregiverIdForSenior(String seniorId) =>
      _careChatService.caregiverIdForSenior(seniorId);

  Future<String?> firstLinkedSeniorIdForCaregiver(String caregiverId) =>
      _careChatService.firstLinkedSeniorIdForCaregiver(caregiverId);

  Future<Map<String, dynamic>?> getUserProfile(String uid) =>
      _careChatService.getUserProfile(uid);

  Future<String> ensureChat({
    required String caregiverId,
    required String seniorId,
  }) =>
      _careChatService.ensureChat(caregiverId: caregiverId, seniorId: seniorId);

  Stream<List<CareChatMessage>> streamMessages(String chatId) =>
      _careChatService.streamMessages(chatId);

  Future<String> sendTextMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) =>
      _careChatService.sendTextMessage(
        chatId: chatId,
        senderId: senderId,
        text: text,
      );

  Future<String> sendMediaMessage({
    required String chatId,
    required String senderId,
    required CareChatMessageType type,
    String? text,
    required Uint8List bytes,
    required String contentType,
    required String fileName,
  }) =>
      _careChatService.sendMediaMessage(
        chatId: chatId,
        senderId: senderId,
        type: type,
        text: text,
        bytes: bytes,
        contentType: contentType,
        fileName: fileName,
      );

  Future<String> sendMediaFileMessage({
    required String chatId,
    required String senderId,
    required CareChatMessageType type,
    String? text,
    required File file,
    required String contentType,
    required String fileName,
  }) =>
      _careChatService.sendMediaFileMessage(
        chatId: chatId,
        senderId: senderId,
        type: type,
        text: text,
        file: file,
        contentType: contentType,
        fileName: fileName,
      );

  Future<String> sendMedicationProposal({
    required String chatId,
    required String senderId,
    required CareChatMessageType type,
    required MedicationProposalPayload payload,
  }) =>
      _careChatService.sendMedicationProposal(
        chatId: chatId,
        senderId: senderId,
        type: type,
        payload: payload,
      );

  Future<void> respondToProposal({
    required String chatId,
    required String messageId,
    required bool accept,
  }) =>
      _careChatService.respondToProposal(
        chatId: chatId,
        messageId: messageId,
        accept: accept,
      );

  Future<void> softDeleteMessage({
    required String chatId,
    required String messageId,
    required String deletedBy,
  }) =>
      _careChatService.softDeleteMessage(
        chatId: chatId,
        messageId: messageId,
        deletedBy: deletedBy,
      );

  Future<void> markProposalApplied({
    required String chatId,
    required String messageId,
    String? medicationId,
  }) =>
      _careChatService.markProposalApplied(
        chatId: chatId,
        messageId: messageId,
        medicationId: medicationId,
      );
}
