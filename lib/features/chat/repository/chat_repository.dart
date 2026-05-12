import '../models/chat_message.dart';
import '../models/health_assistant_response.dart';
import '../services/chat_history_service.dart';
import '../services/health_assistant_api_service.dart';

class ChatRepository {
  ChatRepository({
    required ChatHistoryService chatHistoryService,
    required HealthAssistantApiService healthAssistantApiService,
  })  : _chatHistoryService = chatHistoryService,
        _api = healthAssistantApiService;

  final ChatHistoryService _chatHistoryService;
  final HealthAssistantApiService _api;

  Stream<List<ChatMessage>> watchMessages(String uid) =>
      _chatHistoryService.watchMessages(uid);

  Future<HealthAssistantResponse> sendMessage({
    required String uid,
    required String message,
  }) =>
      _api.sendMessage(uid: uid, message: message);

  Future<void> clearChatHistory(String userId) =>
      _chatHistoryService.clearChatHistory(userId);
}
