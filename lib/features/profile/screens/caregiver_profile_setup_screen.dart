import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/set_pin_screen.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';

class CaregiverProfileSetupScreen extends StatefulWidget {
  const CaregiverProfileSetupScreen({super.key});

  static const String routePath = '/profile/caregiver';
  static const String routeName = 'caregiver_profile_setup';

  @override
  State<CaregiverProfileSetupScreen> createState() =>
      _CaregiverProfileSetupScreenState();
}

class _CaregiverProfileSetupScreenState
    extends State<CaregiverProfileSetupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _onSave(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final router = GoRouter.of(context);

    final user = authProvider.state.firebaseUser;
    if (user == null) return;
    final hasPhone = user.phoneNumber != null && user.phoneNumber!.isNotEmpty;
    final hasEmail = user.email != null && user.email!.isNotEmpty;
    if (!hasPhone && !hasEmail) return;

    final profile = UserProfile(
      uid: user.uid,
      role: 'caregiver',
      phoneNumber: user.phoneNumber ?? '',
      email: user.email,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      createdAt: DateTime.now(),
    );

    await profileProvider.saveProfile(profile);

    if (!context.mounted) return;

    if (profileProvider.errorMessage == null) {
      router.push(SetPinScreen.routePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space6,
            AppTheme.space5,
            AppTheme.space6,
            AppTheme.space9,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tell us about yourself',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.space3),
              const Text(
                'A few quick details so seniors recognize you when you connect.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppTheme.space7),
              const SectionHeader('About you'),
              TextField(
                controller: _firstNameController,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  labelText: 'First name *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: AppTheme.space4),
              TextField(
                controller: _lastNameController,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  labelText: 'Last name *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: AppTheme.space7),
              if (profileProvider.errorMessage != null) ...[
                ErrorBanner(message: profileProvider.errorMessage!),
                const SizedBox(height: AppTheme.space5),
              ],
              PrimaryButton(
                label: 'Continue',
                icon: Icons.arrow_forward,
                isLoading: profileProvider.isLoading,
                onPressed: profileProvider.isLoading
                    ? null
                    : () => _onSave(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
