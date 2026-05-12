import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/app_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import 'caregiver_home_screen.dart';
import 'senior_home_screen.dart';

/// Redirects to CaregiverHomeScreen or SeniorHomeScreen based on user role.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String routePath = '/home';
  static const String routeName = 'home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasRedirected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final role = authProvider.userRole;

    if (role != null && !_hasRedirected) {
      _hasRedirected = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        if (role == 'caregiver') {
          authProvider.registerFcmTokenIfNeeded();
          context.go(CaregiverHomeScreen.routePath);
        } else {
          context.go(SeniorHomeScreen.routePath);
        }
      });
    }

    return const Scaffold(
      body: LoadingState(message: 'Getting things ready…'),
    );
  }
}
