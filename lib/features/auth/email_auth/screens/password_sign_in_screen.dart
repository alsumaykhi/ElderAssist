import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../providers/auth_provider.dart';
import '../../screens/pin_unlock_screen.dart';
import '../../screens/role_selection_screen.dart';
import 'create_password_screen.dart';

/// Step 2a: password for an existing email account.
class PasswordSignInScreen extends StatefulWidget {
  const PasswordSignInScreen({super.key, required this.email});

  final String email;

  static const String routePath = '/auth/email/sign-in';
  static const String routeName = 'email_password_sign_in';

  @override
  State<PasswordSignInScreen> createState() => _PasswordSignInScreenState();
}

class _PasswordSignInScreenState extends State<PasswordSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _awaitingVerification = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.email.isEmpty) {
        context.pop();
        return;
      }
      context.read<AuthProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _afterSignedIn(AuthProvider auth) async {
    await FirebaseAuth.instance.currentUser?.reload();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await auth.sendEmailVerificationToCurrentUser();
      setState(() => _awaitingVerification = true);
      return;
    }
    await _goNext(auth);
  }

  Future<void> _goNext(AuthProvider auth) async {
    final next = await auth.finalizeVerifiedEmailUserSession();
    if (!mounted) return;
    if (next == null) return;
    if (next == EmailAuthFlowNext.roleSelection) {
      context.pushReplacement(RoleSelectionScreen.routePath);
    } else {
      context.pushReplacement(PinUnlockScreen.routePath);
    }
  }

  Future<void> _onContinue() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final email = AuthProvider.normalizeEmailInput(widget.email);
    final outcome = await auth.signInWithEmailPasswordOutcome(
      email,
      _passwordController.text,
    );
    if (!mounted) return;
    switch (outcome) {
      case EmailPasswordSignInOutcome.userNotFound:
        final encoded = Uri.encodeComponent(email);
        context.pushReplacement(
          '${CreatePasswordScreen.routePath}?email=$encoded',
        );
        return;
      case EmailPasswordSignInOutcome.success:
        await _afterSignedIn(auth);
        return;
      case EmailPasswordSignInOutcome.wrongPassword:
      case EmailPasswordSignInOutcome.invalidEmail:
      case EmailPasswordSignInOutcome.failed:
        return;
    }
  }

  Future<void> _onVerifiedContinue() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();
    await _goNext(auth);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final authState = auth.state;

    return Scaffold(
      appBar: AppBar(
        title: Text(_awaitingVerification ? 'Verify email' : 'Enter password'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space7,
            AppTheme.space5,
            AppTheme.space7,
            AppTheme.space7,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AccountChip(email: widget.email),
                const SizedBox(height: AppTheme.space6),
                Expanded(
                  child: SingleChildScrollView(
                    child: _awaitingVerification
                        ? _VerifyEmailNotice(email: widget.email)
                        : _PasswordSection(
                            controller: _passwordController,
                            obscure: _obscure,
                            onToggleObscure: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                  ),
                ),
                if (authState.errorMessage != null) ...[
                  ErrorBanner(message: authState.errorMessage!),
                  const SizedBox(height: AppTheme.space5),
                ],
                if (!_awaitingVerification) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: authState.isLoading ? null : _onForgotPassword,
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space2),
                  PrimaryButton(
                    label: 'Continue',
                    icon: Icons.login,
                    isLoading: authState.isLoading,
                    onPressed: authState.isLoading ? null : _onContinue,
                  ),
                  const SizedBox(height: AppTheme.space4),
                  TextButton(
                    onPressed: authState.isLoading
                        ? null
                        : () {
                            final email = AuthProvider.normalizeEmailInput(
                                widget.email);
                            context.pushReplacement(
                              '${CreatePasswordScreen.routePath}?email=${Uri.encodeComponent(email)}',
                            );
                          },
                    child: const Text('New here? Create an account'),
                  ),
                ] else ...[
                  PrimaryButton(
                    label: 'I have verified my email',
                    icon: Icons.mark_email_read_outlined,
                    isLoading: authState.isLoading,
                    onPressed: authState.isLoading ? null : _onVerifiedContinue,
                  ),
                  const SizedBox(height: AppTheme.space4),
                  TextButton.icon(
                    onPressed: authState.isLoading
                        ? null
                        : () => auth.sendEmailVerificationToCurrentUser(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Resend verification email'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onForgotPassword() async {
    final auth = context.read<AuthProvider>();
    final outcome = await auth.sendPasswordReset(widget.email);
    if (!mounted) return;
    switch (outcome) {
      case PasswordResetOutcome.success:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Password reset email sent to ${widget.email}.',
            ),
          ),
        );
        return;
      case PasswordResetOutcome.invalidEmail:
      case PasswordResetOutcome.userNotFound:
      case PasswordResetOutcome.failed:
        return;
    }
  }
}

class _AccountChip extends StatelessWidget {
  const _AccountChip({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space5,
        vertical: AppTheme.space4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.mail_outline,
              color: AppTheme.brandPrimary, size: 20),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Text(
              email,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordSection extends StatelessWidget {
  const _PasswordSection({
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
  });

  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller,
          obscureText: obscure,
          autofillHints: const [AutofillHints.password],
          autofocus: true,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              onPressed: onToggleObscure,
              icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
              color: AppTheme.textSecondary,
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) {
              return 'Please enter your password.';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _VerifyEmailNotice extends StatelessWidget {
  const _VerifyEmailNotice({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_unread_outlined,
            size: 56, color: AppTheme.brandPrimary),
        const SizedBox(height: AppTheme.space5),
        const Text(
          'Verify your email',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.space3),
        Text(
          'We sent a verification link to $email. Tap the link in the email, then return here to continue.',
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
            height: 1.45,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
