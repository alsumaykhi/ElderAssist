import 'package:flutter/material.dart';
import 'dart:io';

import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../medication/models/medication.dart';
import '../models/care_chat_message.dart';
import '../models/care_chat_message_type.dart';
import '../providers/care_chat_provider.dart';

class CaregiverSeniorChatScreen extends StatefulWidget {
  const CaregiverSeniorChatScreen({
    super.key,
    required this.peerUid,
  });

  static const String routePath = '/care-chat/:peerUid';
  static const String routeName = 'caregiver_senior_chat';

  final String peerUid;

  @override
  State<CaregiverSeniorChatScreen> createState() =>
      _CaregiverSeniorChatScreenState();
}

class _CaregiverSeniorChatScreenState extends State<CaregiverSeniorChatScreen> {
  final TextEditingController _composerController = TextEditingController();
  bool _initialized = false;
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CareChatProvider>().initForPeer(
            peerUid: widget.peerUid,
            authProvider: context.read<AuthProvider>(),
          );
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    _composerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CareChatProvider>();
    final title = provider.peerName == null || provider.peerName!.isEmpty
        ? 'Care chat'
        : provider.peerName!;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (provider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.space5,
                  AppTheme.space4,
                  AppTheme.space5,
                  0,
                ),
                child: ErrorBanner(message: provider.errorMessage!),
              ),
            Expanded(
              child: provider.isLoading && provider.messages.isEmpty
                  ? const LoadingState(message: 'Loading chat…')
                  : _MessageList(messages: provider.messages),
            ),
            if (provider.isCaregiverCurrentUser)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.space4,
                  0,
                  AppTheme.space4,
                  AppTheme.space3,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: provider.isSending
                        ? null
                        : () => _openMedicationsSheet(context),
                    icon: const Icon(Icons.medication_outlined),
                    label: const Text('Medications'),
                  ),
                ),
              ),
            _Composer(
              controller: _composerController,
              isSending: provider.isSending,
              isRecording: _isRecording,
              onCameraPressed: () => _openCameraSheet(context),
              onVoiceHoldStart: () => _startVoiceRecording(context),
              onVoiceHoldEnd: () => _stopVoiceRecordingAndSend(context),
              onSend: () async {
                final text = _composerController.text;
                _composerController.clear();
                await provider.sendText(text);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCameraSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take photo'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _captureAndSendImage(context, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined),
                title: const Text('Record video'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _captureAndSendVideo(context, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _openGalleryTypeSheet(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openGalleryTypeSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('Choose photo'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _captureAndSendImage(context, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.movie_outlined),
                title: const Text('Choose video'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _captureAndSendVideo(context, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _captureAndSendImage(
    BuildContext context,
    ImageSource source,
  ) async {
    final provider = context.read<CareChatProvider>();
    final xfile = await _picker.pickImage(source: source, imageQuality: 85);
    if (xfile == null) return;
    await provider.sendMediaFile(
      type: CareChatMessageType.image,
      file: File(xfile.path),
      fileName: xfile.name,
      contentType: _guessContentTypeFromName(xfile.name, fallback: 'image/jpeg'),
    );
  }

  Future<void> _captureAndSendVideo(
    BuildContext context,
    ImageSource source,
  ) async {
    final provider = context.read<CareChatProvider>();
    final xfile = await _picker.pickVideo(source: source);
    if (xfile == null) return;
    await provider.sendMediaFile(
      type: CareChatMessageType.video,
      file: File(xfile.path),
      fileName: xfile.name,
      contentType: _guessContentTypeFromName(xfile.name, fallback: 'video/mp4'),
    );
  }

  String _guessContentTypeFromName(String name, {required String fallback}) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webm')) return 'video/webm';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.m4a')) return 'audio/mp4';
    if (lower.endsWith('.aac')) return 'audio/aac';
    if (lower.endsWith('.wav')) return 'audio/wav';
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    return fallback;
  }

  Future<void> _startVoiceRecording(BuildContext context) async {
    if (_isRecording) return;
    final hasPerm = await _recorder.hasPermission();
    if (!hasPerm) return;

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/care_chat_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    setState(() => _isRecording = true);
  }

  Future<void> _stopVoiceRecordingAndSend(BuildContext context) async {
    if (!_isRecording) return;
    final provider = context.read<CareChatProvider>();
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (!await file.exists()) return;
    await provider.sendMediaFile(
      type: CareChatMessageType.voiceMemo,
      file: file,
      fileName: file.uri.pathSegments.isEmpty
          ? 'voice.m4a'
          : file.uri.pathSegments.last,
      contentType: 'audio/mp4',
    );
  }

  Future<void> _openMedicationsSheet(BuildContext context) async {
    final provider = context.read<CareChatProvider>();
    final meds = await provider.fetchSeniorMedications();

    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space5,
              AppTheme.space5,
              AppTheme.space5,
              AppTheme.space5,
            ),
            child: _CaregiverMedicationsSheet(
              medications: meds,
              onProposeNew: () {
                Navigator.of(sheetContext).pop();
                context.push(
                  '/care-chat/${widget.peerUid}/medication-form?mode=add',
                );
              },
              onProposeEdit: (med) {
                Navigator.of(sheetContext).pop();
                context.push(
                  '/care-chat/${widget.peerUid}/medication-form?mode=edit&medId=${Uri.encodeComponent(med.id)}',
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _CaregiverMedicationsSheet extends StatelessWidget {
  const _CaregiverMedicationsSheet({
    required this.medications,
    required this.onProposeNew,
    required this.onProposeEdit,
  });

  final List<Medication> medications;
  final VoidCallback onProposeNew;
  final void Function(Medication medication) onProposeEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Medications',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              onPressed: onProposeNew,
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Propose new medication',
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space3),
        if (medications.isEmpty)
          const EmptyState(
            icon: Icons.medication_outlined,
            title: 'No medications yet',
            message: 'Propose the first medication to get started.',
          )
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: medications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final med = medications[index];
                return ListTile(
                  leading: const Icon(Icons.medication_outlined),
                  title: Text(med.name),
                  subtitle: Text(
                    '${med.dosage}${med.times.isNotEmpty ? ' · ${med.times.join(', ')}' : ''}',
                  ),
                  trailing: IconButton(
                    onPressed: () => onProposeEdit(med),
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Propose edit',
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: AppTheme.space4),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onProposeNew,
            icon: const Icon(Icons.add),
            label: const Text('Propose new medication'),
          ),
        ),
      ],
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.messages});

  final List<CareChatMessage> messages;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const EmptyState(
        icon: Icons.forum_outlined,
        title: 'No messages yet',
        message: 'Start the conversation with your caregiver or senior.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space4,
        AppTheme.space4,
        AppTheme.space4,
        AppTheme.space5,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return _MessageBubble(message: msg);
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final CareChatMessage message;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CareChatProvider>();
    final mine = message.senderId == provider.currentUid;

    final bool sentByCaregiver = message.senderId == provider.caregiverId;
    final bool sentBySenior = message.senderId == provider.seniorId;

    final Color bg;
    final Color fg;

    if (sentByCaregiver) {
      bg = mine ? AppTheme.brandPrimary : AppTheme.brandPrimarySoft;
      fg = mine ? Colors.white : AppTheme.brandPrimaryDark;
    } else if (sentBySenior) {
      bg = mine ? AppTheme.success : AppTheme.successSoft;
      fg = mine ? Colors.white : AppTheme.success.withValues(alpha: 0.9);
    } else {
      bg = AppTheme.surfaceMuted;
      fg = AppTheme.textPrimary;
    }

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.space3),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space4,
          vertical: AppTheme.space3,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.7,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.status == 'deleted')
              Text(
                'Message deleted',
                style: TextStyle(
                  color: fg.withValues(alpha: 0.9),
                  fontStyle: FontStyle.italic,
                ),
              )
            else ...[
              Text(
                _titleForType(message.type),
                style: TextStyle(
                  color: fg.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              if ((message.text ?? '').isNotEmpty)
                Text(
                  message.text!,
                  style: TextStyle(color: fg, fontSize: 15),
                ),
              if (message.mediaUrl != null && message.mediaUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    message.mediaUrl!,
                    style: TextStyle(
                      color: fg,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              if (message.proposal != null)
                MedicationProposalCard(
                  message: message,
                  isSeniorViewer: provider.isSeniorCurrentUser,
                  isSending: provider.isSending,
                  textColor: fg,
                ),
              const SizedBox(height: 4),
              if (message.createdAt != null)
                Text(
                  _formatTime(message.createdAt!),
                  style: TextStyle(
                    fontSize: 11,
                    color: fg.withValues(alpha: 0.7),
                  ),
                ),
              if (provider.isCaregiverCurrentUser && message.status != 'deleted')
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => provider.softDeleteMessage(message.id),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _titleForType(CareChatMessageType type) {
    switch (type) {
      case CareChatMessageType.text:
        return 'Text';
      case CareChatMessageType.voiceMemo:
        return 'Voice memo';
      case CareChatMessageType.image:
        return 'Image';
      case CareChatMessageType.video:
        return 'Video';
      case CareChatMessageType.medicationProposal:
        return 'Medication proposal';
      case CareChatMessageType.medicationEditProposal:
        return 'Medication edit proposal';
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class MedicationProposalCard extends StatelessWidget {
  const MedicationProposalCard({
    super.key,
    required this.message,
    required this.isSeniorViewer,
    required this.isSending,
    required this.textColor,
  });

  final CareChatMessage message;
  final bool isSeniorViewer;
  final bool isSending;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final proposal = message.proposal;
    if (proposal == null) return const SizedBox.shrink();
    final (badgeColor, badgeLabel) = _badgeForStatus(message.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Medication proposal',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textColor.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badgeLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${proposal.name} · ${proposal.dosage} · ${proposal.time}',
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        if ((proposal.notes ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              proposal.notes!,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
          ),
        if (isSeniorViewer && message.isPendingProposal) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isSending
                      ? null
                      : () => context
                          .read<CareChatProvider>()
                          .respondToProposal(message, accept: false),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: isSending
                      ? null
                      : () => context
                          .read<CareChatProvider>()
                          .respondToProposal(message, accept: true),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  (Color, String) _badgeForStatus(String status) {
    switch (status) {
      case 'accepted':
        return (AppTheme.success, 'Accepted');
      case 'declined':
        return (AppTheme.danger, 'Declined');
      case 'expired':
        return (AppTheme.textTertiary, 'Expired');
      default:
        return (AppTheme.warning, 'Pending');
    }
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isSending,
    required this.isRecording,
    required this.onCameraPressed,
    required this.onVoiceHoldStart,
    required this.onVoiceHoldEnd,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final bool isRecording;
  final VoidCallback onCameraPressed;
  final VoidCallback onVoiceHoldStart;
  final VoidCallback onVoiceHoldEnd;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space4,
        AppTheme.space3,
        AppTheme.space4,
        AppTheme.space4,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: isSending ? null : onCameraPressed,
            icon: const Icon(Icons.photo_camera_outlined),
            tooltip: 'Camera',
          ),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isSending,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppTheme.space4,
                  vertical: AppTheme.space3,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space3),
          GestureDetector(
            onLongPressStart: (_) => onVoiceHoldStart(),
            onLongPressEnd: (_) => onVoiceHoldEnd(),
            child: SizedBox(
              height: 52,
              width: 52,
              child: IconButton.filled(
                onPressed: null,
                icon: Icon(
                  isRecording ? Icons.mic : Icons.mic_none_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space3),
          SizedBox(
            height: 52,
            width: 52,
            child: IconButton.filled(
              onPressed: isSending ? null : onSend,
              icon: isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ),
        ],
      ),
    );
  }
}
