import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/email_auth/screens/create_password_screen.dart';
import '../../features/auth/email_auth/screens/email_input_screen.dart';
import '../../features/auth/email_auth/screens/password_sign_in_screen.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/auth/screens/otp_verification_screen.dart';
import '../../features/auth/screens/phone_input_screen.dart';
import '../../features/auth/screens/pin_unlock_screen.dart';
import '../../features/auth/screens/pin_recovery_screen.dart';
import '../../features/auth/screens/role_selection_screen.dart';
import '../../features/auth/screens/set_pin_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/profile/screens/caregiver_profile_setup_screen.dart';
import '../../features/profile/screens/senior_profile_setup_screen.dart';
import '../../features/caregiver_dashboard/screens/caregiver_dashboard_screen.dart';
import '../../features/caregiver_dashboard/screens/senior_detail_screen.dart';
import '../../features/home/screens/caregiver_home_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/senior_home_screen.dart';
import '../../features/linking/screens/caregiver_link_code_screen.dart';
import '../../features/linking/screens/link_caregiver_screen.dart';
import '../../features/linking/screens/scan_link_qr_screen.dart';
import '../../features/medication/screens/add_medication_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/care_chat/screens/caregiver_medication_form_screen.dart';
import '../../features/care_chat/screens/caregiver_senior_chat_screen.dart';
import '../../features/care_chat/screens/my_caregiver_screen.dart';
import '../../features/medication/screens/medication_list_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static GoRouter createRouter() {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: SplashScreen.routePath,
      routes: [
        GoRoute(
          path: SplashScreen.routePath,
          name: SplashScreen.routeName,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: PhoneInputScreen.routePath,
          name: PhoneInputScreen.routeName,
          builder: (context, state) => const PhoneInputScreen(),
        ),
        GoRoute(
          path: EmailInputScreen.routePath,
          name: EmailInputScreen.routeName,
          builder: (context, state) => const EmailInputScreen(),
        ),
        GoRoute(
          path: PasswordSignInScreen.routePath,
          name: PasswordSignInScreen.routeName,
          builder: (context, state) {
            final raw = state.uri.queryParameters['email'] ?? '';
            final email =
                raw.isEmpty ? '' : AuthService.normalizeEmail(raw);
            return PasswordSignInScreen(email: email);
          },
        ),
        GoRoute(
          path: CreatePasswordScreen.routePath,
          name: CreatePasswordScreen.routeName,
          builder: (context, state) {
            final raw = state.uri.queryParameters['email'] ?? '';
            final email =
                raw.isEmpty ? '' : AuthService.normalizeEmail(raw);
            return CreatePasswordScreen(email: email);
          },
        ),
        GoRoute(
          path: OtpVerificationScreen.routePath,
          name: OtpVerificationScreen.routeName,
          builder: (context, state) {
            final phoneNumber =
                state.uri.queryParameters['phoneNumber'] ?? '';
            return OtpVerificationScreen(phoneNumber: phoneNumber);
          },
        ),
        GoRoute(
          path: RoleSelectionScreen.routePath,
          name: RoleSelectionScreen.routeName,
          builder: (context, state) => const RoleSelectionScreen(),
        ),
        GoRoute(
          path: SeniorProfileSetupScreen.routePath,
          name: SeniorProfileSetupScreen.routeName,
          builder: (context, state) => const SeniorProfileSetupScreen(),
        ),
        GoRoute(
          path: CaregiverProfileSetupScreen.routePath,
          name: CaregiverProfileSetupScreen.routeName,
          builder: (context, state) => const CaregiverProfileSetupScreen(),
        ),
        GoRoute(
          path: SetPinScreen.routePath,
          name: SetPinScreen.routeName,
          builder: (context, state) => const SetPinScreen(),
        ),
        GoRoute(
          path: PinUnlockScreen.routePath,
          name: PinUnlockScreen.routeName,
          builder: (context, state) => const PinUnlockScreen(),
        ),
        GoRoute(
          path: PinRecoveryScreen.routePath,
          name: PinRecoveryScreen.routeName,
          builder: (context, state) => const PinRecoveryScreen(),
        ),
        GoRoute(
          path: HomeScreen.routePath,
          name: HomeScreen.routeName,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: CaregiverHomeScreen.routePath,
          name: CaregiverHomeScreen.routeName,
          builder: (context, state) => const CaregiverHomeScreen(),
        ),
        GoRoute(
          path: CaregiverLinkCodeScreen.routePath,
          name: CaregiverLinkCodeScreen.routeName,
          builder: (context, state) => const CaregiverLinkCodeScreen(),
        ),
        GoRoute(
          path: CaregiverDashboardScreen.routePath,
          name: CaregiverDashboardScreen.routeName,
          builder: (context, state) => const CaregiverDashboardScreen(),
        ),
        GoRoute(
          path: '${SeniorDetailScreen.routePath}/:uid',
          name: SeniorDetailScreen.routeName,
          builder: (context, state) {
            final uid = state.pathParameters['uid'] ?? '';
            return SeniorDetailScreen(seniorUid: uid);
          },
        ),
        GoRoute(
          path: SeniorHomeScreen.routePath,
          name: SeniorHomeScreen.routeName,
          builder: (context, state) => const SeniorHomeScreen(),
        ),
        GoRoute(
          path: LinkCaregiverScreen.routePath,
          name: LinkCaregiverScreen.routeName,
          builder: (context, state) => const LinkCaregiverScreen(),
        ),
        GoRoute(
          path: ScanLinkQrScreen.routePath,
          name: ScanLinkQrScreen.routeName,
          builder: (context, state) => const ScanLinkQrScreen(),
        ),
        GoRoute(
          path: MedicationListScreen.routePath,
          name: MedicationListScreen.routeName,
          builder: (context, state) => const MedicationListScreen(),
        ),
        GoRoute(
          path: AddMedicationScreen.routePath,
          name: AddMedicationScreen.routeName,
          builder: (context, state) => const AddMedicationScreen(),
        ),
        GoRoute(
          path: ChatScreen.routePath,
          name: ChatScreen.routeName,
          builder: (context, state) => const ChatScreen(),
        ),
        GoRoute(
          path: '/care-chat/:peerUid',
          name: CaregiverSeniorChatScreen.routeName,
          builder: (context, state) {
            final peerUid = state.pathParameters['peerUid'] ?? '';
            return CaregiverSeniorChatScreen(peerUid: peerUid);
          },
        ),
        GoRoute(
          path: '/care-chat/:peerUid/medication-form',
          name: CaregiverMedicationFormScreen.routeName,
          builder: (context, state) {
            final peerUid = state.pathParameters['peerUid'] ?? '';
            final mode = state.uri.queryParameters['mode'] ?? 'add';
            final medId = state.uri.queryParameters['medId'];
            return CaregiverMedicationFormScreen(
              peerUid: peerUid,
              mode: mode,
              medicationId: medId,
            );
          },
        ),
        GoRoute(
          path: MyCaregiverScreen.routePath,
          name: MyCaregiverScreen.routeName,
          builder: (context, state) => const MyCaregiverScreen(),
        ),
      ],
    );
  }
}
