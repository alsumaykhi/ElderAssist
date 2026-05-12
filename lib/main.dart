import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/services/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/services/pin_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/caregiver_dashboard/providers/caregiver_dashboard_provider.dart';
import 'features/caregiver_dashboard/repository/caregiver_dashboard_repository.dart';
import 'features/caregiver_dashboard/services/caregiver_dashboard_service.dart';
import 'features/linking/providers/linking_provider.dart';
import 'features/linking/repository/linking_repository.dart';
import 'features/linking/services/linking_service.dart';
import 'features/checkin/providers/check_in_provider.dart';
import 'features/checkin/repository/check_in_repository.dart';
import 'features/checkin/services/check_in_service.dart';
import 'features/auth/repository/auth_repository.dart';
import 'features/auth/services/auth_service.dart';
import 'features/medication/providers/medication_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/profile/repository/profile_repository.dart';
import 'features/profile/services/profile_service.dart';
import 'features/medication/repository/medication_repository.dart';
import 'features/medication/services/medication_service.dart';
import 'features/medication/providers/adherence_provider.dart';
import 'features/medication/services/adherence_service.dart';
import 'features/chat/providers/chat_provider.dart';
import 'features/chat/repository/chat_repository.dart';
import 'features/chat/services/chat_history_service.dart';
import 'features/chat/services/health_assistant_api_service.dart';
import 'features/care_chat/providers/care_chat_provider.dart';
import 'features/care_chat/repository/care_chat_repository.dart';
import 'features/care_chat/services/care_chat_service.dart';
import 'firebase_options.dart';
import 'shared/theme/app_theme.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestNotificationPermission();

  // Single instance after Firebase init; must match `setGlobalOptions({ region })` in `functions/index.js`.
  final functions = FirebaseFunctions.instanceFor(
    app: Firebase.app(),
    region: 'us-central1',
  );

  runApp(ElderAssistApp(
    notificationService: notificationService,
    functions: functions,
  ));
}

class ElderAssistApp extends StatelessWidget {
  const ElderAssistApp({
    super.key,
    required this.notificationService,
    required this.functions,
  });

  final NotificationService notificationService;
  final FirebaseFunctions functions;

  @override
  Widget build(BuildContext context) {
    final GoRouter router = AppRouter.createRouter();
    final pinService = PinService();
    final authService = AuthService();
    final authRepository = AuthRepository(
      authService: authService,
      pinService: pinService,
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            authRepository: authRepository,
          ),
        ),
        ChangeNotifierProvider<CaregiverDashboardProvider>(
          create: (_) => CaregiverDashboardProvider(
            caregiverDashboardRepository: CaregiverDashboardRepository(
              caregiverDashboardService: CaregiverDashboardService(),
            ),
          ),
        ),
        ChangeNotifierProvider<LinkingProvider>(
          create: (_) => LinkingProvider(
            linkingRepository: LinkingRepository(
              linkingService: LinkingService(),
            ),
          ),
        ),
        ChangeNotifierProvider<ProfileProvider>(
          create: (_) => ProfileProvider(
            profileRepository: ProfileRepository(
              profileService: ProfileService(),
            ),
          ),
        ),
        ChangeNotifierProvider<CheckInProvider>(
          create: (_) => CheckInProvider(
            checkInRepository: CheckInRepository(
              checkInService: CheckInService(),
            ),
            notificationService: notificationService,
          ),
        ),
        ChangeNotifierProvider<MedicationProvider>(
          create: (_) => MedicationProvider(
            medicationRepository: MedicationRepository(
              medicationService: MedicationService(),
            ),
            notificationService: notificationService,
          ),
        ),
        ChangeNotifierProvider<ChatProvider>(
          create: (context) => ChatProvider(
            chatRepository: ChatRepository(
              chatHistoryService: ChatHistoryService(),
              healthAssistantApiService: HealthAssistantApiService(
                functions: functions,
              ),
            ),
            medicationProvider: context.read<MedicationProvider>(),
          ),
        ),
        ChangeNotifierProvider<AdherenceProvider>(
          create: (_) => AdherenceProvider(
            adherenceService: AdherenceService(),
          ),
        ),
        ChangeNotifierProvider<CareChatProvider>(
          create: (_) => CareChatProvider(
            careChatRepository: CareChatRepository(
              careChatService: CareChatService(),
            ),
            medicationRepository: MedicationRepository(
              medicationService: MedicationService(),
            ),
          ),
        ),
      ],
      child: MaterialApp.router(
        title: 'ElderAssist',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
  }
}
