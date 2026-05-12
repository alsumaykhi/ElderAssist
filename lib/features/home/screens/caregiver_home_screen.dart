import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/elder_assist_logo.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/pin_unlock_screen.dart';
import '../../caregiver_dashboard/screens/caregiver_dashboard_screen.dart';
import '../../linking/screens/caregiver_link_code_screen.dart';

/// Main menu for caregivers after sign-in.
class CaregiverHomeScreen extends StatelessWidget {
  const CaregiverHomeScreen({super.key});

  static const String routePath = '/caregiver-home';
  static const String routeName = 'caregiver_home';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final firstName = (auth.state.userProfile?['firstName'] as String?) ?? '';
    final greeting = _greetingForNow();
    final fullGreeting =
        firstName.isEmpty ? '$greeting!' : '$greeting, $firstName';

    return Scaffold(
      appBar: AppBar(
        title: const Center(child: ElderAssistAppBarTitle()),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space6,
            AppTheme.space5,
            AppTheme.space6,
            AppTheme.space9,
          ),
          children: [
            Text(
              fullGreeting,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: AppTheme.space2),
            const Text(
              'Manage the seniors in your care.',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.space7),
            const SectionHeader('Your tools'),
            ActionTile(
              icon: Icons.people_outline,
              title: 'My seniors',
              subtitle: 'View status, medications, and check-ins',
              onTap: () => context.push(CaregiverDashboardScreen.routePath),
            ),
            const SizedBox(height: AppTheme.space4),
            ActionTile(
              icon: Icons.qr_code_2,
              title: 'Get linking code',
              subtitle: 'Share a code so a senior can connect',
              iconColor: AppTheme.info,
              iconBackground: AppTheme.infoSoft,
              onTap: () => context.push(CaregiverLinkCodeScreen.routePath),
            ),
            const SizedBox(height: AppTheme.space4),
            ActionTile(
              icon: Icons.lock_outline,
              title: 'Lock app',
              subtitle: 'Lock with PIN',
              iconColor: AppTheme.textSecondary,
              iconBackground: AppTheme.surfaceMuted,
              onTap: () => context.push(PinUnlockScreen.routePath),
            ),
          ],
        ),
      ),
    );
  }

  String _greetingForNow() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}
