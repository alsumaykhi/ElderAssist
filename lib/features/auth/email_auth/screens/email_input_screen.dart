import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../providers/auth_provider.dart';
import 'create_password_screen.dart';
import 'password_sign_in_screen.dart';

/// Step 1: collect email, then sign-in (default) or explicit account creation.
///
/// We do not use [AuthProvider.fetchEmailSignInMethods] here: Firebase email
/// enumeration protection often hides whether an email exists, which routed
/// existing users through the wrong screen. New users use the secondary action.
class EmailInputScreen extends StatefulWidget {
  const EmailInputScreen({super.key});

  static const String routePath = '/auth/email';
  static const String routeName = 'email_input';

  @override
  State<EmailInputScreen> createState() => _EmailInputScreenState();
}

class _EmailInputScreenState extends State<EmailInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _goToPasswordSignIn() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final email = AuthProvider.normalizeEmailInput(_emailController.text);
    final encoded = Uri.encodeComponent(email);
    context.push('${PasswordSignInScreen.routePath}?email=$encoded');
  }

  Future<void> _goToCreateAccount() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final email = AuthProvider.normalizeEmailInput(_emailController.text);
    final encoded = Uri.encodeComponent(email);
    context.push('${CreatePasswordScreen.routePath}?email=$encoded');
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthProvider>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in with email'),
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
                Text(
                  'What is your email?',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.space3),
                const Text(
                  'If you already use ElderAssist with this email, continue to enter your password.',
                  style: TextStyle(
                    fontSize: 17,
                    color: AppTheme.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppTheme.space7),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  autofocus: true,
                  style: const TextStyle(fontSize: 18),
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter your email.';
                    }
                    if (!v.contains('@')) {
                      return 'Please enter a valid email.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.space5),
                if (authState.errorMessage != null)
                  ErrorBanner(message: authState.errorMessage!),
                const Spacer(),
                PrimaryButton(
                  label: 'Continue to sign in',
                  icon: Icons.arrow_forward,
                  isLoading: authState.isLoading,
                  onPressed:
                      authState.isLoading ? null : _goToPasswordSignIn,
                ),
                const SizedBox(height: AppTheme.space4),
                TextButton(
                  onPressed: authState.isLoading ? null : _goToCreateAccount,
                  child: const Text('New here? Create an account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
