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

/// Step 2b: set password for a new email account, then verify email.
class CreatePasswordScreen extends StatefulWidget {
  const CreatePasswordScreen({super.key, required this.email});

  final String email;

  static const String routePath = '/auth/email/create';
  static const String routeName = 'email_create_password';

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _awaitingVerification = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

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
    _confirmController.dispose();
    super.dispose();
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

  Future<void> _onCreateContinue() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final email = AuthProvider.normalizeEmailInput(widget.email);
    final outcome = await auth.registerWithEmailPasswordOutcome(
      email,
      _passwordController.text,
    );
    if (!mounted) return;
    if (outcome == EmailRegisterOutcome.emailAlreadyInUse) {
      final encoded = Uri.encodeComponent(email);
      context.pushReplacement('/auth/email/sign-in?email=$encoded');
      return;
    }
    if (outcome != EmailRegisterOutcome.success) return;

    await auth.sendEmailVerificationToCurrentUser();
    if (!mounted) return;
    setState(() => _awaitingVerification = true);
  }

  Future<void> _onVerifiedContinue() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();
    await FirebaseAuth.instance.currentUser?.reload();
    await _goNext(auth);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final authState = auth.state;

    return Scaffold(
      appBar: AppBar(
        title:
            Text(_awaitingVerification ? 'Verify email' : 'Create password'),
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
                        : _PasswordFields(
                            passwordController: _passwordController,
                            confirmController: _confirmController,
                            obscurePassword: _obscurePassword,
                            obscureConfirm: _obscureConfirm,
                            onTogglePassword: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            onToggleConfirm: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                  ),
                ),
                if (authState.errorMessage != null) ...[
                  ErrorBanner(message: authState.errorMessage!),
                  const SizedBox(height: AppTheme.space5),
                ],
                if (!_awaitingVerification) ...[
                  PrimaryButton(
                    label: 'Create account',
                    icon: Icons.person_add_alt,
                    isLoading: authState.isLoading,
                    onPressed:
                        authState.isLoading ? null : _onCreateContinue,
                  ),
                  const SizedBox(height: AppTheme.space4),
                  TextButton(
                    onPressed: authState.isLoading
                        ? null
                        : () {
                            final email = AuthProvider.normalizeEmailInput(
                                widget.email);
                            context.pushReplacement(
                              '/auth/email/sign-in?email=${Uri.encodeComponent(email)}',
                            );
                          },
                    child: const Text('Already have an account? Sign in'),
                  ),
                ] else ...[
                  PrimaryButton(
                    label: 'I have verified my email',
                    icon: Icons.mark_email_read_outlined,
                    isLoading: authState.isLoading,
                    onPressed:
                        authState.isLoading ? null : _onVerifiedContinue,
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

class _PasswordFields extends StatelessWidget {
  const _PasswordFields({
    required this.passwordController,
    required this.confirmController,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.onTogglePassword,
    required this.onToggleConfirm,
  });

  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool obscurePassword;
  final bool obscureConfirm;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: passwordController,
          obscureText: obscurePassword,
          autofocus: true,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              onPressed: onTogglePassword,
              icon: Icon(
                  obscurePassword ? Icons.visibility : Icons.visibility_off),
              color: AppTheme.textSecondary,
            ),
            helperText: 'At least 6 characters.',
          ),
          validator: (v) {
            if (v == null || v.isEmpty) {
              return 'Please enter a password.';
            }
            if (v.length < 6) {
              return 'Password must be at least 6 characters.';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.space5),
        TextFormField(
          controller: confirmController,
          obscureText: obscureConfirm,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            labelText: 'Confirm password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              onPressed: onToggleConfirm,
              icon: Icon(
                  obscureConfirm ? Icons.visibility : Icons.visibility_off),
              color: AppTheme.textSecondary,
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) {
              return 'Please confirm your password.';
            }
            if (v != passwordController.text) {
              return 'Passwords do not match.';
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
