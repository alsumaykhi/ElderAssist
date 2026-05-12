import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/elder_assist_logo.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../caregiver_dashboard/screens/caregiver_dashboard_screen.dart';
import '../../home/screens/senior_home_screen.dart';
import '../providers/linking_provider.dart';
import 'scan_link_qr_screen.dart';

/// Screen for seniors to enter a 6-digit code and link with their caregiver.
/// Only seniors should access this screen.
class LinkCaregiverScreen extends StatefulWidget {
  const LinkCaregiverScreen({super.key});

  static const String routePath = '/link-caregiver';
  static const String routeName = 'link_caregiver';

  @override
  State<LinkCaregiverScreen> createState() => _LinkCaregiverScreenState();
}

class _LinkCaregiverScreenState extends State<LinkCaregiverScreen> {
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadUserProfile();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _onLink(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final linkingProvider = context.read<LinkingProvider>();
    final router = GoRouter.of(context);

    final user = authProvider.state.firebaseUser;
    if (user == null) return;

    final role = authProvider.userRole;
    if (role == 'caregiver') {
      router.go(CaregiverDashboardScreen.routePath);
      return;
    }

    await linkingProvider.validateAndLink(
      code: _codeController.text.trim(),
      seniorUid: user.uid,
    );

    if (!context.mounted) return;

    if (linkingProvider.linkSuccess) {
      router.go(SeniorHomeScreen.routePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final linkingProvider = context.watch<LinkingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Link caregiver'),
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
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.brandPrimarySoft,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const ElderAssistSymbol(size: 60),
              ),
              const SizedBox(height: AppTheme.space6),
              Text(
                'Enter your 6-digit code',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.space3),
              const Text(
                'Ask your caregiver for the code or QR in their app. You can type the numbers here or scan the QR.',
                style: TextStyle(
                  fontSize: 17,
                  color: AppTheme.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppTheme.space7),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 32,
                  letterSpacing: 12,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                ),
              ),
              const SizedBox(height: AppTheme.space5),
              if (linkingProvider.errorMessage != null)
                ErrorBanner(message: linkingProvider.errorMessage!),
              const Spacer(),
              PrimaryButton(
                label: 'Scan QR code',
                icon: Icons.qr_code_scanner,
                variant: PrimaryButtonVariant.tonal,
                isLoading: false,
                onPressed: linkingProvider.isLoading
                    ? null
                    : () => context.push(ScanLinkQrScreen.routePath),
              ),
              const SizedBox(height: AppTheme.space4),
              PrimaryButton(
                label: 'Link',
                icon: Icons.link,
                isLoading: linkingProvider.isLoading,
                onPressed: linkingProvider.isLoading
                    ? null
                    : () => _onLink(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
