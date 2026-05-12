import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/linking_provider.dart';
import '../utils/link_qr_payload.dart';

/// Lets a caregiver generate a 6-digit code for a senior to enter in Link Caregiver.
class CaregiverLinkCodeScreen extends StatefulWidget {
  const CaregiverLinkCodeScreen({super.key});

  static const String routePath = '/caregiver-link-code';
  static const String routeName = 'caregiver_link_code';

  @override
  State<CaregiverLinkCodeScreen> createState() =>
      _CaregiverLinkCodeScreenState();
}

class _CaregiverLinkCodeScreenState extends State<CaregiverLinkCodeScreen> {
  Future<void> _generate() async {
    final user = context.read<AuthProvider>().state.firebaseUser;
    if (user == null) return;
    FocusScope.of(context).unfocus();
    await context.read<LinkingProvider>().generateLinkCode(user.uid);
  }

  void _copy(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final linking = context.watch<LinkingProvider>();
    final code = linking.generatedCode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Link a senior'),
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
              Text(
                'Generate a code',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.space3),
              const Text(
                'Generate a code, then ask your family member to open ElderAssist, tap Link caregiver, and either scan this QR or type the numbers.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppTheme.space7),
              if (code != null) _CodeDisplay(code: code, onCopy: () => _copy(code)),
              const SizedBox(height: AppTheme.space5),
              if (linking.errorMessage != null)
                ErrorBanner(message: linking.errorMessage!),
              const Spacer(),
              PrimaryButton(
                label: code == null ? 'Generate code' : 'Generate new code',
                icon: code == null ? Icons.qr_code_2 : Icons.refresh,
                isLoading: linking.isLoading,
                onPressed: linking.isLoading ? null : _generate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeDisplay extends StatelessWidget {
  const _CodeDisplay({required this.code, required this.onCopy});

  final String code;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space7),
      decoration: BoxDecoration(
        color: AppTheme.brandPrimarySoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.brandPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text(
            'YOUR CODE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.brandPrimaryDark,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          SelectableText(
            code,
            style: const TextStyle(
              fontSize: 44,
              letterSpacing: 8,
              fontWeight: FontWeight.w700,
              color: AppTheme.brandPrimaryDark,
            ),
          ),
          const SizedBox(height: AppTheme.space6),
          Center(
            child: Container(
              padding: const EdgeInsets.all(AppTheme.space5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: AppTheme.brandPrimary.withValues(alpha: 0.15),
                ),
              ),
              child: QrImageView(
                data: LinkQrPayload.encode(code),
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppTheme.brandPrimaryDark,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppTheme.brandPrimaryDark,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          OutlinedButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.content_copy, size: 18),
            label: const Text('Copy code'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.brandPrimaryDark,
              side: BorderSide(
                  color:
                      AppTheme.brandPrimary.withValues(alpha: 0.4)),
              minimumSize: const Size(0, 44),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}
