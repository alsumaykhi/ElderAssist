import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../home/screens/home_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';

enum _RecoveryMethod { password, phoneOtp }

class PinRecoveryScreen extends StatefulWidget {
  const PinRecoveryScreen({super.key});

  static const String routePath = '/recover-pin';
  static const String routeName = 'pin_recovery';

  @override
  State<PinRecoveryScreen> createState() => _PinRecoveryScreenState();
}

class _PinRecoveryScreenState extends State<PinRecoveryScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  _RecoveryMethod _method = _RecoveryMethod.password;
  bool _reauthenticated = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _otpController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _reauthWithPassword(AuthProvider auth) async {
    await auth.reauthenticateWithPassword(_passwordController.text.trim());
    if (!mounted || auth.state.errorMessage != null) return;
    setState(() => _reauthenticated = true);
  }

  Future<void> _sendOtp(AuthProvider auth) async {
    await auth.sendPinRecoveryOtp();
    if (!mounted) return;
    if (auth.state.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent to your phone number.')),
      );
    }
  }

  Future<void> _verifyOtp(AuthProvider auth) async {
    await auth.reauthenticateWithRecoveryOtp(_otpController.text.trim());
    if (!mounted || auth.state.errorMessage != null) return;
    setState(() => _reauthenticated = true);
  }

  Future<void> _saveNewPin(AuthProvider auth) async {
    await auth.resetPinAfterRecovery(
      _pinController.text.trim(),
      _confirmPinController.text.trim(),
    );
    if (!mounted) return;
    if (auth.state.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN updated successfully.')),
      );
      context.go(HomeScreen.routePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthState state = context.watch<AuthProvider>().state;
    final auth = context.read<AuthProvider>();
    final user = FirebaseAuth.instance.currentUser;
    final hasPassword = (user?.email ?? '').isNotEmpty;
    final hasPhone = (user?.phoneNumber ?? '').isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Forgot PIN')),
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
              if (!_reauthenticated) ...[
                const Text(
                  'Re-authenticate to reset your PIN',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.space3),
                const Text(
                  'For security, confirm your identity first.',
                  style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: AppTheme.space6),
                if (hasPassword && hasPhone)
                  SegmentedButton<_RecoveryMethod>(
                    segments: const [
                      ButtonSegment(
                        value: _RecoveryMethod.password,
                        label: Text('Email password'),
                        icon: Icon(Icons.lock_outline),
                      ),
                      ButtonSegment(
                        value: _RecoveryMethod.phoneOtp,
                        label: Text('Phone OTP'),
                        icon: Icon(Icons.sms_outlined),
                      ),
                    ],
                    selected: <_RecoveryMethod>{_method},
                    onSelectionChanged: (selected) {
                      setState(() => _method = selected.first);
                    },
                  ),
                const SizedBox(height: AppTheme.space6),
                if (_method == _RecoveryMethod.password || !hasPhone)
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Account password',
                      prefixIcon: Icon(Icons.password),
                    ),
                  ),
                if (_method == _RecoveryMethod.phoneOtp && hasPhone) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'OTP code',
                            prefixIcon: Icon(Icons.verified_user_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.space3),
                      TextButton(
                        onPressed: state.isLoading ? null : () => _sendOtp(auth),
                        child: const Text('Send OTP'),
                      ),
                    ],
                  ),
                ],
                const Spacer(),
                PrimaryButton(
                  label: _method == _RecoveryMethod.phoneOtp && hasPhone ?
                    'Verify OTP' :
                    'Verify password',
                  icon: Icons.verified_user_outlined,
                  isLoading: state.isLoading,
                  onPressed: state.isLoading ?
                    null :
                    () {
                        if (_method == _RecoveryMethod.phoneOtp && hasPhone) {
                          _verifyOtp(auth);
                        } else {
                          _reauthWithPassword(auth);
                        }
                      },
                ),
              ] else ...[
                const Text(
                  'Set a new PIN',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.space3),
                const Text(
                  'Create a new 4-6 digit PIN.',
                  style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: AppTheme.space6),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'New PIN',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: AppTheme.space4),
                TextField(
                  controller: _confirmPinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Confirm PIN',
                    counterText: '',
                  ),
                ),
                const Spacer(),
                PrimaryButton(
                  label: 'Save new PIN',
                  icon: Icons.check_circle_outline,
                  isLoading: state.isLoading,
                  onPressed: state.isLoading ? null : () => _saveNewPin(auth),
                ),
              ],
              if (state.errorMessage != null) ...[
                const SizedBox(height: AppTheme.space5),
                ErrorBanner(message: state.errorMessage!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
