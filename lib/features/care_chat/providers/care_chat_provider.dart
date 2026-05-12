import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/foundation.dart';

import '../../auth/providers/auth_provider.dart';
import '../../medication/models/medication.dart';
import '../../medication/repository/medication_repository.dart';
import '../models/care_chat_message.dart';
import '../models/care_chat_message_type.dart';
import '../models/medication_proposal_payload.dart';
import '../repository/care_chat_repository.dart';

class CareChatProvider extends ChangeNotifier {
  CareChatProvider({
    required CareChatRepository careChatRepository,
    required MedicationRepository medicationRepository,
  })  : _careChatRepository = careChatRepository,
        _medicationRepository = medicationRepository;

  final CareChatRepository _careChatRepository;
  final MedicationRepository _medicationRepository;
  CareChatRepository get repository => _careChatRepository;

  StreamSubscription<List<CareChatMessage>>? _sub;
  List<CareChatMessage> _messages = [];
  List<CareChatMessage> get messages => List.unmodifiable(_messages);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSending = false;
  bool get isSending => _isSending;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _chatId;
  String? get chatId => _chatId;

  String? _caregiverId;
  String? get caregiverId => _caregiverId;

  String? _seniorId;
  String? get seniorId => _seniorId;

  String? _peerName;
  String? get peerName => _peerName;

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;
  String? get currentUid => _currentUid;

  bool get isCaregiverCurrentUser => _caregiverId != null && _caregiverId == _currentUid;
  bool get isSeniorCurrentUser => _seniorId != null && _seniorId == _currentUid;

  Future<void> initForUsers({
    required String caregiverId,
    required String seniorId,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    _caregiverId = caregiverId;
    _seniorId = seniorId;
    notifyListeners();

    try {
      final linked = await _careChatRepository.areUsersLinked(
        caregiverId: caregiverId,
        seniorId: seniorId,
      );
      if (!linked) {
        throw Exception('Users are not linked. Chat is unavailable.');
      }
      _chatId = await _careChatRepository.ensureChat(
        caregiverId: caregiverId,
        seniorId: seniorId,
      );
      _attachStream();

      final peerId = _currentUid == caregiverId ? seniorId : caregiverId;
      final peerProfile = await _careChatRepository.getUserProfile(peerId);
      final first = peerProfile?['firstName'] as String? ?? '';
      final last = peerProfile?['lastName'] as String? ?? '';
      _peerName = '$first $last'.trim();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> initForPeer({
    required String peerUid,
    required AuthProvider authProvider,
  }) async {
    final currentUid = _currentUid;
    final role = authProvider.userRole;
    if (currentUid == null || role == null) {
      _errorMessage = 'Please sign in to open chat.';
      notifyListeners();
      return;
    }

    if (role == 'caregiver') {
      return initForUsers(caregiverId: currentUid, seniorId: peerUid);
    }

    if (role == 'senior') {
      return initForUsers(caregiverId: peerUid, seniorId: currentUid);
    }

    _errorMessage = 'Unsupported role for care chat.';
    notifyListeners();
  }

  Future<void> sendText(String text) async {
    final chatId = _chatId;
    final uid = _currentUid;
    if (chatId == null || uid == null) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _isSending = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _careChatRepository.sendTextMessage(
        chatId: chatId,
        senderId: uid,
        text: trimmed,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> sendMedia({
    required CareChatMessageType type,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    String? caption,
  }) async {
    final chatId = _chatId;
    final uid = _currentUid;
    if (chatId == null || uid == null) return;

    _isSending = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _careChatRepository.sendMediaMessage(
        chatId: chatId,
        senderId: uid,
        type: type,
        text: caption,
        bytes: bytes,
        contentType: contentType,
        fileName: fileName,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> sendMediaFile({
    required CareChatMessageType type,
    required File file,
    required String fileName,
    required String contentType,
    String? caption,
  }) async {
    final chatId = _chatId;
    final uid = _currentUid;
    if (chatId == null || uid == null) return;

    _isSending = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _careChatRepository.sendMediaFileMessage(
        chatId: chatId,
        senderId: uid,
        type: type,
        text: caption,
        file: file,
        contentType: contentType,
        fileName: fileName,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<List<Medication>> fetchSeniorMedications() async {
    final seniorId = _seniorId;
    final uid = _currentUid;
    if (seniorId == null || uid == null) return <Medication>[];
    if (!isCaregiverCurrentUser) return <Medication>[];
    return await _medicationRepository.fetchMedications(seniorId);
  }

  Future<void> sendMedicationProposal({
    required String name,
    required String dosage,
    required String time,
    String? notes,
  }) async {
    await _sendProposal(
      type: CareChatMessageType.medicationProposal,
      payload: MedicationProposalPayload(
        name: name.trim(),
        dosage: dosage.trim(),
        time: time.trim(),
        notes: notes?.trim(),
      ),
    );
  }

  Future<void> sendMedicationEditProposal({
    required String medicationId,
    required String name,
    required String dosage,
    required String time,
    String? notes,
  }) async {
    await _sendProposal(
      type: CareChatMessageType.medicationEditProposal,
      payload: MedicationProposalPayload(
        medicationId: medicationId.trim(),
        name: name.trim(),
        dosage: dosage.trim(),
        time: time.trim(),
        notes: notes?.trim(),
      ),
    );
  }

  Future<void> _sendProposal({
    required CareChatMessageType type,
    required MedicationProposalPayload payload,
  }) async {
    final chatId = _chatId;
    final uid = _currentUid;
    if (chatId == null || uid == null) return;
    if (!isCaregiverCurrentUser) {
      _errorMessage = 'Only caregivers can send medication proposals.';
      notifyListeners();
      return;
    }

    _isSending = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _careChatRepository.sendMedicationProposal(
        chatId: chatId,
        senderId: uid,
        type: type,
        payload: payload,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> respondToProposal(CareChatMessage message, {required bool accept}) async {
    final chatId = _chatId;
    final seniorId = _seniorId;
    if (chatId == null || seniorId == null) return;
    if (!isSeniorCurrentUser) {
      _errorMessage = 'Only seniors can respond to proposals.';
      notifyListeners();
      return;
    }
    if (!message.isPendingProposal) return;

    _isSending = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _careChatRepository.respondToProposal(
        chatId: chatId,
        messageId: message.id,
        accept: accept,
      );

      if (accept) {
        final proposal = message.proposal;
        if (proposal == null) {
          throw Exception('Proposal payload missing.');
        }
        if (message.type == CareChatMessageType.medicationProposal) {
          final med = Medication(
            id: '',
            name: proposal.name,
            dosage: proposal.dosage,
            times: <String>[proposal.time],
            startDate: DateTime.now(),
            createdAt: DateTime.now(),
            isActive: true,
          );
          await _medicationRepository.addMedication(seniorId, med);
        } else if (message.type == CareChatMessageType.medicationEditProposal) {
          final medId = proposal.medicationId;
          if (medId == null || medId.isEmpty) {
            throw Exception('Medication ID missing for edit proposal.');
          }
          final medications = await _medicationRepository.fetchMedications(seniorId);
          final existing = medications.where((m) => m.id == medId).toList();
          if (existing.isEmpty) {
            throw Exception('Medication to edit was not found.');
          }
          final updated = existing.first.copyWith(
            name: proposal.name,
            dosage: proposal.dosage,
            times: <String>[proposal.time],
          );
          await _medicationRepository.updateMedication(seniorId, updated);
          await _careChatRepository.markProposalApplied(
            chatId: chatId,
            messageId: message.id,
            medicationId: updated.id,
          );
        }
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> softDeleteMessage(String messageId) async {
    final chatId = _chatId;
    final uid = _currentUid;
    if (chatId == null || uid == null) return;
    if (!isCaregiverCurrentUser) {
      _errorMessage = 'Only caregivers can delete messages.';
      notifyListeners();
      return;
    }
    try {
      await _careChatRepository.softDeleteMessage(
        chatId: chatId,
        messageId: messageId,
        deletedBy: uid,
      );
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  void _attachStream() {
    final chatId = _chatId;
    if (chatId == null) return;
    _sub?.cancel();
    _sub = _careChatRepository.streamMessages(chatId).listen(
      (messages) {
        _messages = messages;
        notifyListeners();
      },
      onError: (_) {
        _errorMessage = 'Failed to load chat messages.';
        notifyListeners();
      },
    );
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
