import 'dart:typed_data';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/care_chat_message.dart';
import '../models/care_chat_message_type.dart';
import '../models/medication_proposal_payload.dart';

class CareChatService {
  CareChatService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> _usersRef() =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> _chatsRef() =>
      _firestore.collection('caregiver_senior_chats');

  CollectionReference<Map<String, dynamic>> _messagesRef(String chatId) =>
      _chatsRef().doc(chatId).collection('messages');

  String buildChatId({
    required String caregiverId,
    required String seniorId,
  }) {
    return '${caregiverId}_$seniorId';
  }

  Future<bool> areUsersLinked({
    required String caregiverId,
    required String seniorId,
  }) async {
    final caregiverDoc = await _usersRef().doc(caregiverId).get();
    final seniorDoc = await _usersRef().doc(seniorId).get();
    if (!caregiverDoc.exists || !seniorDoc.exists) return false;
    final caregiverData = caregiverDoc.data() ?? <String, dynamic>{};
    final seniorData = seniorDoc.data() ?? <String, dynamic>{};
    final seniorIds = (caregiverData['seniorIds'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toSet();
    final caregiverIdOnSenior = seniorData['caregiverId'] as String? ?? '';
    return seniorIds.contains(seniorId) && caregiverIdOnSenior == caregiverId;
  }

  Future<String?> caregiverIdForSenior(String seniorId) async {
    final doc = await _usersRef().doc(seniorId).get();
    if (!doc.exists) return null;
    final data = doc.data() ?? <String, dynamic>{};
    final caregiverId = data['caregiverId'] as String?;
    if (caregiverId == null || caregiverId.isEmpty) return null;
    return caregiverId;
  }

  Future<String?> firstLinkedSeniorIdForCaregiver(String caregiverId) async {
    final doc = await _usersRef().doc(caregiverId).get();
    if (!doc.exists) return null;
    final data = doc.data() ?? <String, dynamic>{};
    final seniorIds = (data['seniorIds'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .where((id) => id.isNotEmpty)
        .toList();
    if (seniorIds.isEmpty) return null;
    return seniorIds.first;
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _usersRef().doc(uid).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  Future<String> ensureChat({
    required String caregiverId,
    required String seniorId,
  }) async {
    final chatId = buildChatId(caregiverId: caregiverId, seniorId: seniorId);
    final chatRef = _chatsRef().doc(chatId);
    await chatRef.set(
      <String, dynamic>{
        'caregiverId': caregiverId,
        'seniorId': seniorId,
        'participants': <String>[caregiverId, seniorId],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    return chatId;
  }

  Stream<List<CareChatMessage>> streamMessages(String chatId) {
    return _messagesRef(chatId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CareChatMessage.fromFirestore(chatId, doc))
              .toList(),
        );
  }

  Future<String> sendTextMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    final messageRef = _messagesRef(chatId).doc();
    final now = FieldValue.serverTimestamp();
    await messageRef.set(<String, dynamic>{
      'senderId': senderId,
      'type': CareChatMessageType.text.firestoreValue,
      'status': 'active',
      'text': text.trim(),
      'createdAt': now,
      'updatedAt': now,
    });
    await _touchChat(
      chatId,
      preview: text.trim().isEmpty ? 'Text message' : text.trim(),
    );
    return messageRef.id;
  }

  Future<String> sendMediaMessage({
    required String chatId,
    required String senderId,
    required CareChatMessageType type,
    String? text,
    required Uint8List bytes,
    required String contentType,
    required String fileName,
  }) async {
    final messageRef = _messagesRef(chatId).doc();
    final storagePath = 'chat_media/$chatId/${messageRef.id}/$fileName';
    final storageRef = _storage.ref(storagePath);
    await storageRef.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );
    final mediaUrl = await storageRef.getDownloadURL();
    final now = FieldValue.serverTimestamp();

    await messageRef.set(<String, dynamic>{
      'senderId': senderId,
      'type': type.firestoreValue,
      'status': 'active',
      'text': text?.trim(),
      'mediaUrl': mediaUrl,
      'mediaPath': storagePath,
      'createdAt': now,
      'updatedAt': now,
    });

    await _touchChat(chatId, preview: '${type.firestoreValue} message');
    return messageRef.id;
  }

  Future<String> sendMediaFileMessage({
    required String chatId,
    required String senderId,
    required CareChatMessageType type,
    String? text,
    required File file,
    required String contentType,
    required String fileName,
  }) async {
    final messageRef = _messagesRef(chatId).doc();
    final storagePath = 'chat_media/$chatId/${messageRef.id}/$fileName';
    final storageRef = _storage.ref(storagePath);
    await storageRef.putFile(
      file,
      SettableMetadata(contentType: contentType),
    );
    final mediaUrl = await storageRef.getDownloadURL();
    final now = FieldValue.serverTimestamp();

    await messageRef.set(<String, dynamic>{
      'senderId': senderId,
      'type': type.firestoreValue,
      'status': 'active',
      'text': text?.trim(),
      'mediaUrl': mediaUrl,
      'mediaPath': storagePath,
      'createdAt': now,
      'updatedAt': now,
    });

    await _touchChat(chatId, preview: '${type.firestoreValue} message');
    return messageRef.id;
  }

  Future<String> sendMedicationProposal({
    required String chatId,
    required String senderId,
    required CareChatMessageType type,
    required MedicationProposalPayload payload,
  }) async {
    final messageRef = _messagesRef(chatId).doc();
    final expiresAt = Timestamp.fromDate(
      DateTime.now().toUtc().add(const Duration(hours: 24)),
    );
    final now = FieldValue.serverTimestamp();
    await messageRef.set(<String, dynamic>{
      'senderId': senderId,
      'type': type.firestoreValue,
      'status': 'pending',
      'payload': payload.toMap(),
      'expiresAt': expiresAt,
      'createdAt': now,
      'updatedAt': now,
    });
    await _touchChat(chatId, preview: 'Medication proposal');
    return messageRef.id;
  }

  Future<void> respondToProposal({
    required String chatId,
    required String messageId,
    required bool accept,
  }) async {
    await _messagesRef(chatId).doc(messageId).update(<String, dynamic>{
      'status': accept ? 'accepted' : 'declined',
      'respondedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _touchChat(chatId, preview: accept ? 'Proposal accepted' : 'Proposal declined');
  }

  Future<void> softDeleteMessage({
    required String chatId,
    required String messageId,
    required String deletedBy,
  }) async {
    final ref = _messagesRef(chatId).doc(messageId);
    final snapshot = await ref.get();
    final mediaPath = snapshot.data()?['mediaPath'] as String?;
    await ref.update(<String, dynamic>{
      'status': 'deleted',
      'text': null,
      'mediaUrl': null,
      'mediaPath': null,
      'payload': null,
      'deletedBy': deletedBy,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (mediaPath != null && mediaPath.isNotEmpty) {
      try {
        await _storage.ref(mediaPath).delete();
      } catch (_) {
        // Ignore missing objects to keep delete non-blocking.
      }
    }
    await _touchChat(chatId, preview: 'Message deleted');
  }

  Future<void> markProposalApplied({
    required String chatId,
    required String messageId,
    String? medicationId,
  }) async {
    await _messagesRef(chatId).doc(messageId).update(<String, dynamic>{
      'appliedMedicationId': medicationId,
      'appliedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _touchChat(String chatId, {required String preview}) async {
    await _chatsRef().doc(chatId).set(
      <String, dynamic>{
        'lastMessagePreview': preview,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
