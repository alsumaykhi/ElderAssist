import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message.dart';

class ChatHistoryService {
  ChatHistoryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _historyRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('chatHistory');

  Stream<List<ChatMessage>> watchMessages(String uid) {
    return _historyRef(uid)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs.map(ChatMessage.fromFirestore).toList(),
        );
  }

  Future<void> clearChatHistory(String uid) async {
    final messagesRef = _historyRef(uid);

    while (true) {
      final snapshot = await messagesRef.limit(500).get();
      if (snapshot.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
