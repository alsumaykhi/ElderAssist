import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/primary_button.dart';
import '../email_auth/screens/email_input_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import 'otp_verification_screen.dart';

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  static const String routePath = '/phone';
  static const String routeName = 'phone_input';

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Holds the full E.164 number (e.g. +966501234567) once the user
  /// has entered a valid number in the IntlPhoneField.
  PhoneNumber? _phoneNumber;

  @override
  Widget build(BuildContext context) {
    final AuthState authState = context.watch<AuthProvider>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in'),
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
                _Header(),
                const SizedBox(height: AppTheme.space7),
                IntlPhoneField(
                  initialCountryCode: 'SA',
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 19),
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                  ),
                  validator: (phone) {
                    if (phone == null || phone.number.trim().isEmpty) {
                      return 'Please enter your phone number.';
                    }
                    final digitsOnly =
                        phone.number.replaceAll(RegExp(r'\D'), '');
                    if (digitsOnly.length < 7 || digitsOnly.length > 15) {
                      return 'Please enter a valid phone number.';
                    }

                    // Some intl_phone_field/libphonenumber combinations can throw
                    // NumberTooShortException while the user is still typing.
                    // Treat that as invalid input instead of crashing.
                    try {
                      if (!phone.isValidNumber()) {
                        return 'Please enter a valid phone number.';
                      }
                    } catch (_) {
                      return 'Please enter a valid phone number.';
                    }
                    return null;
                  },
                  onChanged: (phone) {
                    _phoneNumber = phone;
                  },
                  onSaved: (phone) {
                    _phoneNumber = phone;
                  },
                ),
                const SizedBox(height: AppTheme.space5),
                if (authState.errorMessage != null)
                  ErrorBanner(message: authState.errorMessage!),
                const Spacer(),
                PrimaryButton(
                  label: 'Send code',
                  icon: Icons.sms_outlined,
                  isLoading: authState.isLoading,
                  onPressed: authState.isLoading
                      ? null
                      : () async {
                          FocusScope.of(context).unfocus();

                          if (!_formKey.currentState!.validate()) return;
                          _formKey.currentState!.save();

                          final fullNumber =
                              _phoneNumber!.completeNumber.trim();

                          final router = GoRouter.of(context);
                          final authProvider = context.read<AuthProvider>();

                          await authProvider.sendOtp(fullNumber);
                          final nextState = authProvider.state;

                          if (nextState.errorMessage == null &&
                              nextState.verificationId != null) {
                            router.push(
                              '${OtpVerificationScreen.routePath}?phoneNumber=${Uri.encodeComponent(fullNumber)}',
                            );
                          }
                        },
                ),
                const SizedBox(height: AppTheme.space4),
                const _OrDivider(),
                const SizedBox(height: AppTheme.space4),
                OutlinedButton.icon(
                  onPressed: authState.isLoading
                      ? null
                      : () async {
                          final router = GoRouter.of(context);
                          final authProvider = context.read<AuthProvider>();
                          await router.push(EmailInputScreen.routePath);
                          if (!context.mounted) return;
                          await authProvider.signOutIfUnverifiedEmailOnly();
                        },
                  icon: const Icon(Icons.mail_outline, size: 22),
                  label: const Text('Sign in with email'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter your phone number',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppTheme.space3),
        const Text(
          'We will send a one-time code to confirm your number.',
          style: TextStyle(
            fontSize: 17,
            color: AppTheme.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: Divider(color: AppTheme.border)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.space4),
          child: Text(
            'OR',
            style: TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppTheme.border)),
      ],
    );
  }
}
