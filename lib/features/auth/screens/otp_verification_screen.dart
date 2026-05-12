import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import 'pin_unlock_screen.dart';
import 'role_selection_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  static const String routePath = '/otp';
  static const String routeName = 'otp_verification';

  final String phoneNumber;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = context.watch<AuthProvider>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify code'),
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
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.brandPrimarySoft,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(
                  Icons.sms_outlined,
                  color: AppTheme.brandPrimary,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppTheme.space6),
              Text(
                'Enter the 6-digit code',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.space3),
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 17,
                    color: AppTheme.textSecondary,
                    height: 1.45,
                  ),
                  children: [
                    const TextSpan(text: 'We sent a code to '),
                    TextSpan(
                      text: widget.phoneNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space7),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 30,
                  letterSpacing: 12,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                ),
              ),
              const SizedBox(height: AppTheme.space5),
              if (authState.errorMessage != null)
                ErrorBanner(message: authState.errorMessage!),
              const Spacer(),
              PrimaryButton(
                label: 'Verify and continue',
                icon: Icons.check_circle_outline,
                isLoading: authState.isLoading,
                onPressed: authState.isLoading
                    ? null
                    : () async {
                        final code = _codeController.text.trim();
                        final router = GoRouter.of(context);
                        FocusScope.of(context).unfocus();

                        final authProvider = context.read<AuthProvider>();
                        await authProvider.verifyOtp(code);
                        final nextState = authProvider.state;

                        if (nextState.errorMessage == null &&
                            nextState.firebaseUser != null) {
                          if (nextState.isNewUser) {
                            router.push(RoleSelectionScreen.routePath);
                          } else {
                            router.push(PinUnlockScreen.routePath);
                          }
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
