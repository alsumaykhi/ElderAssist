import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/elder_assist_logo.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../home/screens/home_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import 'pin_recovery_screen.dart';

class PinUnlockScreen extends StatefulWidget {
  const PinUnlockScreen({super.key});

  static const String routePath = '/unlock-pin';
  static const String routeName = 'pin_unlock';

  @override
  State<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<PinUnlockScreen> {
  final TextEditingController _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController
      ..clear()
      ..dispose();
    super.dispose();
  }

  Future<void> _onUnlock(BuildContext context) async {
    final router = GoRouter.of(context);
    final authProvider = context.read<AuthProvider>();

    FocusScope.of(context).unfocus();
    final success =
        await authProvider.unlockWithPin(_pinController.text.trim());

    if (!context.mounted) return;

    if (success) {
      router.push(HomeScreen.routePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final AuthState authState = authProvider.state;
    final secondsLocked = authProvider.secondsUntilPinUnlock;
    final isTemporarilyLocked = secondsLocked > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlock'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space7,
            AppTheme.space5,
            AppTheme.space7,
            AppTheme.space7,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 80,
                height: 80,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.brandPrimarySoft,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: const ElderAssistSymbol(size: 64),
              ),
              const SizedBox(height: AppTheme.space6),
              Text(
                'Enter your PIN',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.space3),
              const Text(
                'Enter your PIN to unlock ElderAssist.',
                style: TextStyle(
                  fontSize: 17,
                  color: AppTheme.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppTheme.space7),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
                autofocus: true,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 26,
                  letterSpacing: 10,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  labelText: 'PIN',
                  counterText: '',
                ),
                enabled: !authState.isLoading &&
                    !isTemporarilyLocked &&
                    !authState.requiresPinReauth,
              ),
              if (isTemporarilyLocked) ...[
                const SizedBox(height: AppTheme.space2),
                Text(
                  'Too many attempts. Try again in $secondsLocked seconds.',
                  style: const TextStyle(
                    color: AppTheme.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.space5),
              if (authState.errorMessage != null)
                ErrorBanner(message: authState.errorMessage!),
              const SizedBox(height: AppTheme.space2),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: authState.isLoading ?
                    null :
                    () => context.push(PinRecoveryScreen.routePath),
                  child: const Text('Forgot PIN?'),
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Unlock',
                icon: Icons.lock_open,
                isLoading: authState.isLoading,
                onPressed: authState.isLoading ||
                        isTemporarilyLocked ||
                        authState.requiresPinReauth ?
                    null :
                    () => _onUnlock(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
