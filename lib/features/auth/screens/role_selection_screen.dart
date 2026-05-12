import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/elder_assist_logo.dart';
import '../../profile/screens/caregiver_profile_setup_screen.dart';
import '../../profile/screens/senior_profile_setup_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  static const String routePath = '/role';
  static const String routeName = 'role_selection';

  Future<void> _onRoleSelected(
    BuildContext context,
    String role,
  ) async {
    final router = GoRouter.of(context);
    final authProvider = context.read<AuthProvider>();

    await authProvider.createUserProfile(role);

    if (!context.mounted) return;

    final nextState = authProvider.state;
    if (nextState.errorMessage == null) {
      if (role == 'senior') {
        router.push(SeniorProfileSetupScreen.routePath);
      } else {
        router.push(CaregiverProfileSetupScreen.routePath);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = context.watch<AuthProvider>().state;
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
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
              const Center(child: ElderAssistSymbol(size: 56)),
              const SizedBox(height: AppTheme.space6),
              Text(
                'Who are you?',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: AppTheme.space3),
              const Text(
                'Choose how you will use ElderAssist. You can always change this later.',
                style: TextStyle(
                  fontSize: 17,
                  color: AppTheme.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppTheme.space8),
              if (authState.errorMessage != null) ...[
                ErrorBanner(message: authState.errorMessage!),
                const SizedBox(height: AppTheme.space5),
              ],
              _RoleChoiceCard(
                title: 'I am a Senior',
                description:
                    'Track medications, check in daily, and stay connected with your caregiver.',
                icon: Icons.elderly,
                color: AppTheme.brandPrimary,
                soft: AppTheme.brandPrimarySoft,
                onTap:
                    isLoading ? null : () => _onRoleSelected(context, 'senior'),
              ),
              const SizedBox(height: AppTheme.space5),
              _RoleChoiceCard(
                title: 'I am a Caregiver',
                description:
                    'Monitor the wellbeing of the seniors you care for from one place.',
                icon: Icons.volunteer_activism,
                color: AppTheme.info,
                soft: AppTheme.infoSoft,
                onTap: isLoading
                    ? null
                    : () => _onRoleSelected(context, 'caregiver'),
              ),
              if (isLoading) ...[
                const SizedBox(height: AppTheme.space7),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleChoiceCard extends StatelessWidget {
  const _RoleChoiceCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.soft,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color soft;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.55 : 1,
      child: AppCard(
        onTap: onTap ?? () {},
        padding: const EdgeInsets.all(AppTheme.space6),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: AppTheme.space5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.space4),
            Icon(Icons.chevron_right, color: color, size: 28),
          ],
        ),
      ),
    );
  }
}
