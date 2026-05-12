import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../medication/providers/medication_provider.dart';
import '../models/chat_message.dart';
import '../models/chat_role.dart';
import '../models/health_assistant_response.dart';
import '../models/suggested_supplement.dart';
import '../repository/chat_repository.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider({
    required ChatRepository chatRepository,
    required MedicationProvider medicationProvider,
  })  : _chatRepository = chatRepository,
        _medicationProvider = medicationProvider;

  final ChatRepository _chatRepository;
  final MedicationProvider _medicationProvider;

  StreamSubscription<List<ChatMessage>>? _sub;
  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool _isSending = false;
  bool get isSending => _isSending;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _latestEmergency = false;
  bool get latestEmergency => _latestEmergency;

  HealthAssistantResponse? _lastResponse;
  HealthAssistantResponse? get lastResponse => _lastResponse;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  bool get isUserSignedIn => FirebaseAuth.instance.currentUser != null;

  void startListening() {
    final uid = _userId;
    if (uid == null) return;
    _sub?.cancel();
    _sub = _chatRepository.watchMessages(uid).listen(
      _onMessages,
      onError: (_) {
        _errorMessage = 'Could not load chat history.';
        notifyListeners();
      },
    );
  }

  void _onMessages(List<ChatMessage> list) {
    _messages = list;
    _recomputeEmergencyFlag();
    notifyListeners();
  }

  void _recomputeEmergencyFlag() {
    ChatMessage? lastAssistant;
    for (var i = _messages.length - 1; i >= 0; i--) {
      final m = _messages[i];
      if (m.role == ChatRole.assistant) {
        lastAssistant = m;
        break;
      }
    }
    _latestEmergency = lastAssistant?.emergency == true;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> sendUserMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    if (FirebaseAuth.instance.currentUser == null) {
      _errorMessage = 'Please sign in to use the assistant.';
      notifyListeners();
      return;
    }

    final uid = _userId;
    if (uid == null) {
      _errorMessage = 'Please sign in to use the assistant.';
      notifyListeners();
      return;
    }

    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _chatRepository.sendMessage(
        uid: uid,
        message: trimmed,
      );
      _lastResponse = response;
      _latestEmergency = response.emergency;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _lastResponse = null;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> addSuggestedSupplementsToMedications(
    List<SuggestedSupplement> items,
  ) async {
    if (items.isEmpty) return;
    for (final s in items) {
      await _medicationProvider.addSupplementFromAssistant(
        name: s.name,
        dosage: s.dosage.isEmpty ? 'As directed' : s.dosage,
      );
    }
  }

  Future<void> clearChatHistory() async {
    final uid = _userId;
    if (uid == null) {
      throw Exception('Please sign in to clear chat history.');
    }

    try {
      await _chatRepository.clearChatHistory(uid);
      _messages = [];
      _latestEmergency = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e, st) {
      developer.log(
        'Failed to clear chat history.',
        name: 'ChatProvider',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
