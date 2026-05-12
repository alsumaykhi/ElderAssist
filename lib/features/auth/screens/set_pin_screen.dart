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

class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key});

  static const String routePath = '/set-pin';
  static const String routeName = 'set_pin';

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  @override
  void dispose() {
    _pinController
      ..clear()
      ..dispose();
    _confirmPinController
      ..clear()
      ..dispose();
    super.dispose();
  }

  Future<void> _onSavePin(BuildContext context) async {
    final router = GoRouter.of(context);
    final authProvider = context.read<AuthProvider>();

    FocusScope.of(context).unfocus();

    await authProvider.setPin(
      _pinController.text.trim(),
      _confirmPinController.text.trim(),
    );

    if (!context.mounted) return;

    final state = authProvider.state;
    if (state.errorMessage == null) {
      router.push(HomeScreen.routePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = context.watch<AuthProvider>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create PIN'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                  Icons.lock_outline,
                  color: AppTheme.brandPrimary,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppTheme.space6),
              Text(
                'Set your PIN',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.space3),
              const Text(
                'Choose a 4–6 digit PIN that is easy for you to remember but hard for others to guess.',
                style: TextStyle(
                  fontSize: 17,
                  color: AppTheme.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppTheme.space7),
              _PinField(
                controller: _pinController,
                label: 'New PIN',
              ),
              const SizedBox(height: AppTheme.space5),
              _PinField(
                controller: _confirmPinController,
                label: 'Confirm PIN',
              ),
              const SizedBox(height: AppTheme.space5),
              if (authState.errorMessage != null)
                ErrorBanner(message: authState.errorMessage!),
              const SizedBox(height: AppTheme.space8),
              PrimaryButton(
                label: 'Save PIN and continue',
                icon: Icons.check_circle_outline,
                isLoading: authState.isLoading,
                onPressed:
                    authState.isLoading ? null : () => _onSavePin(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  const _PinField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: 6,
      obscureText: true,
      textAlign: TextAlign.center,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(
        fontSize: 26,
        letterSpacing: 10,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
      ),
    );
  }
}
