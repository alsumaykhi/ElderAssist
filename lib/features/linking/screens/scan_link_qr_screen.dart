import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../caregiver_dashboard/screens/caregiver_dashboard_screen.dart';
import '../../home/screens/senior_home_screen.dart';
import '../providers/linking_provider.dart';
import '../utils/link_qr_payload.dart';
import 'link_caregiver_screen.dart';

/// In-app QR scan for seniors to link using the same 6-digit [linkCodes] as manual entry.
class ScanLinkQrScreen extends StatefulWidget {
  const ScanLinkQrScreen({super.key});

  static const String routePath = '/link-caregiver/scan';
  static const String routeName = 'scan_link_qr';

  @override
  State<ScanLinkQrScreen> createState() => _ScanLinkQrScreenState();
}

class _ScanLinkQrScreenState extends State<ScanLinkQrScreen> {
  late final MobileScannerController _controller;
  bool _handling = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _tryLink(String code) async {
    final authProvider = context.read<AuthProvider>();
    final linkingProvider = context.read<LinkingProvider>();
    final router = GoRouter.of(context);

    final user = authProvider.state.firebaseUser;
    if (user == null) return;

    if (authProvider.userRole == 'caregiver') {
      router.go(CaregiverDashboardScreen.routePath);
      return;
    }

    await linkingProvider.validateAndLink(
      code: code,
      seniorUid: user.uid,
    );

    if (!mounted) return;

    if (linkingProvider.linkSuccess) {
      HapticFeedback.mediumImpact();
      router.go(SeniorHomeScreen.routePath);
    } else {
      setState(() => _handling = false);
      await _controller.start();
    }
  }

  Future<void> _onBarcode(BarcodeCapture capture) async {
    if (_handling) return;
    final raw = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    final code = LinkQrPayload.parse(raw);
    if (code == null) return;

    setState(() => _handling = true);
    await _controller.stop();
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Link caregiver?'),
        content: Text(
          'Use linking code $code to connect with your caregiver?',
          style: const TextStyle(fontSize: 17, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Link'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmed != true) {
      setState(() => _handling = false);
      await _controller.start();
      return;
    }

    await _tryLink(code);
  }

  @override
  Widget build(BuildContext context) {
    final linking = context.watch<LinkingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR code'),
        actions: [
          IconButton(
            tooltip: 'Torch',
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                final on = state.torchState == TorchState.on;
                return Icon(on ? Icons.flash_on : Icons.flash_off);
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space7,
              AppTheme.space5,
              AppTheme.space7,
              AppTheme.space4,
            ),
            child: Text(
              'Point your camera at the QR code on your caregiver\'s phone.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                    height: 1.45,
                    color: AppTheme.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space7),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: _controller,
                      onDetect: _onBarcode,
                    ),
                    if (_handling || linking.isLoading)
                      const ColoredBox(
                        color: Color(0x66000000),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (linking.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space7,
                AppTheme.space4,
                AppTheme.space7,
                0,
              ),
              child: ErrorBanner(message: linking.errorMessage!),
            ),
          SafeArea(
            minimum: const EdgeInsets.all(AppTheme.space7),
            child: PrimaryButton(
              label: 'Enter code instead',
              variant: PrimaryButtonVariant.tonal,
              icon: Icons.dialpad,
              onPressed: (_handling || linking.isLoading)
                  ? null
                  : () => context.go(LinkCaregiverScreen.routePath),
            ),
          ),
        ],
      ),
    );
  }
}
