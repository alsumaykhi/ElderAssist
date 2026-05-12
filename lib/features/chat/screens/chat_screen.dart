import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../medication/providers/medication_provider.dart';
import '../models/chat_role.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  static const String routePath = '/health-chat';
  static const String routeName = 'health_chat';

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().startListening();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Health assistant')),
        body: SafeArea(
          child: EmptyState(
            icon: Icons.lock_outline,
            title: 'Sign in required',
            message: 'You must be signed in to use the Health Assistant.',
            action: SizedBox(
              width: 220,
              child: PrimaryButton(
                label: 'Go back',
                icon: Icons.arrow_back,
                onPressed: () => context.pop(),
              ),
            ),
          ),
        ),
      );
    }

    final chat = context.watch<ChatProvider>();
    final med = context.watch<MedicationProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health assistant'),
        actions: [
          TextButton.icon(
            onPressed: chat.isSending ? null : () => _confirmClearHistory(chat),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Clear Chat History'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _DisclaimerBar(),
            if (chat.latestEmergency) const _EmergencyBanner(),
            if (chat.errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.space5,
                  AppTheme.space4,
                  AppTheme.space5,
                  0,
                ),
                child: ErrorBanner(message: chat.errorMessage!),
              ),
            Expanded(
              child: chat.messages.isEmpty
                  ? const _ChatEmptyState()
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.space5,
                        AppTheme.space5,
                        AppTheme.space5,
                        AppTheme.space5,
                      ),
                      itemCount: chat.messages.length,
                      itemBuilder: (context, index) {
                        final m = chat.messages[index];
                        final isUser = m.role == ChatRole.user;
                        return _MessageBubble(
                          isUser: isUser,
                          text: m.text,
                          trailing: !isUser && m.suggestedSupplements.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(
                                      top: AppTheme.space4),
                                  child: PrimaryButton(
                                    label: med.isLoading
                                        ? 'Adding\u2026'
                                        : 'Add to supplements',
                                    icon: Icons.eco_outlined,
                                    variant: PrimaryButtonVariant.tonal,
                                    isLoading: med.isLoading,
                                    onPressed: med.isLoading || chat.isSending
                                        ? null
                                        : () async {
                                            await chat
                                                .addSuggestedSupplementsToMedications(
                                              m.suggestedSupplements,
                                            );
                                            if (!context.mounted) return;
                                            final err = med.errorMessage;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  err ??
                                                      'Supplements added. Review them under Medications.',
                                                ),
                                              ),
                                            );
                                          },
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
            ),
            _ChatInput(
              controller: _controller,
              isSending: chat.isSending,
              onSend: () => _send(chat),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send(ChatProvider chat) async {
    final text = _controller.text;
    await chat.sendUserMessage(text);
    if (mounted) _controller.clear();
  }

  Future<void> _confirmClearHistory(ChatProvider chat) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear Chat History?'),
          content: const Text(
            'This will permanently delete your chat history. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (shouldClear != true || !mounted) return;

    try {
      await chat.clearChatHistory();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat history cleared.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to clear chat history. Please try again.'),
        ),
      );
    }
  }
}

class _DisclaimerBar extends StatelessWidget {
  const _DisclaimerBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space5,
        vertical: AppTheme.space3,
      ),
      color: AppTheme.warningSoft,
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.warning, size: 18),
          SizedBox(width: AppTheme.space3),
          Expanded(
            child: Text(
              'This assistant does not replace medical advice.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyBanner extends StatelessWidget {
  const _EmergencyBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space5,
        AppTheme.space4,
        AppTheme.space5,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space5),
        decoration: BoxDecoration(
          color: AppTheme.danger,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32),
            SizedBox(width: AppTheme.space4),
            Expanded(
              child: Text(
                'Possible emergency. Call your local emergency number now.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.chat_bubble_outline,
      title: 'Ask anything',
      message:
          'Ask about symptoms, medications, or general wellness. The assistant will reply in plain language.',
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.isUser,
    required this.text,
    this.trailing,
  });

  final bool isUser;
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.85;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.space4),
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space5,
          vertical: AppTheme.space4,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.brandPrimary : AppTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppTheme.radiusMd),
            topRight: const Radius.circular(AppTheme.radiusMd),
            bottomLeft: Radius.circular(
                isUser ? AppTheme.radiusMd : AppTheme.radiusSm / 2),
            bottomRight: Radius.circular(
                isUser ? AppTheme.radiusSm / 2 : AppTheme.radiusMd),
          ),
          border: isUser ? null : Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 18,
                height: 1.45,
                color: isUser ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space5,
        AppTheme.space4,
        AppTheme.space4,
        AppTheme.space4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              style: const TextStyle(fontSize: 17),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppTheme.space5,
                  vertical: AppTheme.space4,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: AppTheme.space3),
          SizedBox(
            height: 56,
            width: 56,
            child: Material(
              color: AppTheme.brandPrimary,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: InkWell(
                onTap: isSending ? null : onSend,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: Center(
                  child: isSending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
