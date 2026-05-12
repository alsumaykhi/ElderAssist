import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/pin_unlock_screen.dart';
import '../../checkin/providers/check_in_provider.dart';
import '../../linking/providers/linking_provider.dart';
import '../../linking/screens/link_caregiver_screen.dart';
import '../../medication/models/medication.dart';
import '../../medication/providers/adherence_provider.dart';
import '../../medication/providers/medication_provider.dart';
import '../../medication/screens/medication_list_screen.dart';
import '../../chat/screens/chat_screen.dart';
import '../../care_chat/screens/my_caregiver_screen.dart';

/// Home screen for seniors.
class SeniorHomeScreen extends StatefulWidget {
  const SeniorHomeScreen({super.key});

  static const String routePath = '/senior-home';
  static const String routeName = 'senior_home';

  @override
  State<SeniorHomeScreen> createState() => _SeniorHomeScreenState();
}

class _SeniorHomeScreenState extends State<SeniorHomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final medicationProvider = context.read<MedicationProvider>();
      await medicationProvider.loadMedications();
      if (!mounted) return;

      final adherenceProvider = context.read<AdherenceProvider>();
      await adherenceProvider.refreshForToday(medicationProvider.medications);
      if (!mounted) return;

      final auth = context.read<AuthProvider>();
      final profile = auth.state.userProfile;
      final cutoff = profile?['checkInCutoff'] as String?;
      final checkInProvider = context.read<CheckInProvider>();
      checkInProvider.loadTodayStatus();
      if (cutoff != null && cutoff.isNotEmpty) {
        checkInProvider.scheduleDailyReminders(cutoff);
        checkInProvider.runCutoffCheck(cutoff);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;

    final medicationProvider = context.read<MedicationProvider>();
    final adherenceProvider = context.read<AdherenceProvider>();
    adherenceProvider.refreshForToday(medicationProvider.medications);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkInProvider = context.watch<CheckInProvider>();
    final medicationProvider = context.watch<MedicationProvider>();
    final adherenceProvider = context.watch<AdherenceProvider>();
    final auth = context.watch<AuthProvider>();

    final firstName = (auth.state.userProfile?['firstName'] as String?) ?? '';
    final greeting = _greetingForNow();

    final todaysMedications = medicationProvider.medications
        .where(adherenceProvider.isMedicationActiveToday)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await medicationProvider.loadMedications();
            if (!mounted) return;
            await adherenceProvider
                .refreshForToday(medicationProvider.medications);
            checkInProvider.loadTodayStatus();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space6,
              AppTheme.space5,
              AppTheme.space6,
              AppTheme.space9,
            ),
            children: [
              _Greeting(greeting: greeting, firstName: firstName),
              const SizedBox(height: AppTheme.space6),
              _CheckInHero(provider: checkInProvider),
              const SizedBox(height: AppTheme.space7),
              if (todaysMedications.isNotEmpty) ...[
                SectionHeader(
                  'Today\'s medications',
                  action: TextButton(
                    onPressed: () =>
                        context.push(MedicationListScreen.routePath),
                    child: const Text('See all'),
                  ),
                ),
                ...todaysMedications.map((med) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppTheme.space4),
                      child: _MedicationTile(
                        medication: med,
                        adherence: adherenceProvider,
                      ),
                    )),
                const SizedBox(height: AppTheme.space7),
              ],
              const SectionHeader('Quick actions'),
              ActionTile(
                icon: Icons.medication_outlined,
                title: 'Medications',
                subtitle: 'Manage your medications and schedule',
                onTap: () => context.push(MedicationListScreen.routePath),
              ),
              const SizedBox(height: AppTheme.space4),
              ActionTile(
                icon: Icons.chat_bubble_outline,
                title: 'Health assistant',
                subtitle: 'Ask a question about your health',
                iconColor: AppTheme.info,
                iconBackground: AppTheme.infoSoft,
                onTap: () => context.push(ChatScreen.routePath),
              ),
              const SizedBox(height: AppTheme.space4),
              ActionTile(
                icon: Icons.people_outline,
                title: 'My caregiver',
                subtitle: 'Open secure chat and care coordination',
                iconColor: AppTheme.brandPrimary,
                iconBackground: AppTheme.brandPrimarySoft,
                onTap: () => context.push(MyCaregiverScreen.routePath),
              ),
              const SizedBox(height: AppTheme.space4),
              ActionTile(
                icon: Icons.link,
                title: 'Link caregiver',
                subtitle: 'Connect to a caregiver with a code',
                iconColor: AppTheme.warning,
                iconBackground: AppTheme.warningSoft,
                onTap: () {
                  context.read<LinkingProvider>().clearLinkResult();
                  context.push(LinkCaregiverScreen.routePath);
                },
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

class _Greeting extends StatelessWidget {
  const _Greeting({required this.greeting, required this.firstName});

  final String greeting;
  final String firstName;

  @override
  Widget build(BuildContext context) {
    final fullGreeting =
        firstName.isEmpty ? '$greeting!' : '$greeting, $firstName';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fullGreeting,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: AppTheme.space2),
        const Text(
          'Here is your day at a glance.',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _CheckInHero extends StatelessWidget {
  const _CheckInHero({required this.provider});

  final CheckInProvider provider;

  @override
  Widget build(BuildContext context) {
    final isCheckedIn = provider.isCheckedInToday;
    final isLoading = provider.isLoading;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(AppTheme.space6),
      decoration: BoxDecoration(
        color: isCheckedIn ? AppTheme.successSoft : AppTheme.brandPrimary,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isCheckedIn
                      ? AppTheme.success.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(
                  isCheckedIn ? Icons.check_circle : Icons.favorite,
                  color: isCheckedIn ? AppTheme.success : Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppTheme.space5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCheckedIn ? 'Checked in for today' : 'Daily check-in',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isCheckedIn ? AppTheme.success : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCheckedIn
                          ? 'Your caregiver has been notified.'
                          : 'Let your caregiver know you\u2019re okay.',
                      style: TextStyle(
                        fontSize: 15,
                        color: isCheckedIn
                            ? AppTheme.success
                            : Colors.white.withValues(alpha: 0.85),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isCheckedIn) ...[
            const SizedBox(height: AppTheme.space5),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    isLoading ? null : () => provider.confirmToday(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.brandPrimary,
                  disabledBackgroundColor:
                      Colors.white.withValues(alpha: 0.7),
                  disabledForegroundColor: AppTheme.brandPrimary,
                  minimumSize: const Size(double.infinity, 56),
                ),
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(
                              AppTheme.brandPrimary),
                        ),
                      )
                    : const Icon(Icons.favorite_outline, size: 22),
                label: Text(
                  isLoading ? 'Sending\u2026' : 'I\u2019m okay today',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MedicationTile extends StatelessWidget {
  const _MedicationTile({required this.medication, required this.adherence});

  final Medication medication;
  final AdherenceProvider adherence;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.brandPrimarySoft,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(
                  Icons.medication,
                  color: AppTheme.brandPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppTheme.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      medication.dosage,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space5),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: medication.times.map((time) {
              final isTaken = adherence.isDoseTaken(medication.id, time);
              final isMissed = adherence.isDoseMissed(medication.id, time);
              return _DoseButton(
                time: time,
                isTaken: isTaken,
                isMissed: isMissed,
                onPressed: isTaken || isMissed
                    ? null
                    : () => adherence.markTaken(medication.id, time),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _DoseButton extends StatelessWidget {
  const _DoseButton({
    required this.time,
    required this.isTaken,
    required this.isMissed,
    required this.onPressed,
  });

  final String time;
  final bool isTaken;
  final bool isMissed;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final Color fg;
    final Color bg;
    final Color border;
    final IconData icon;
    final String label;

    if (isTaken) {
      fg = AppTheme.success;
      bg = AppTheme.successSoft;
      border = AppTheme.success.withValues(alpha: 0.4);
      icon = Icons.check_circle;
      label = '$time \u00B7 Taken';
    } else if (isMissed) {
      fg = AppTheme.danger;
      bg = AppTheme.dangerSoft;
      border = AppTheme.danger.withValues(alpha: 0.4);
      icon = Icons.error_outline;
      label = '$time \u00B7 Missed';
    } else {
      fg = AppTheme.brandPrimary;
      bg = AppTheme.brandPrimarySoft;
      border = AppTheme.brandPrimary.withValues(alpha: 0.4);
      icon = Icons.schedule;
      label = 'Mark $time taken';
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space4,
            vertical: AppTheme.space3,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: fg, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
