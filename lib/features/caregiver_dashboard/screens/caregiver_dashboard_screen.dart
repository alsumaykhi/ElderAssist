import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../home/screens/caregiver_home_screen.dart';
import '../models/dashboard_summary.dart';
import '../models/senior_summary.dart';
import '../models/status_models.dart';
import '../providers/caregiver_dashboard_provider.dart';
import 'senior_detail_screen.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  static const String routePath = '/caregiver-dashboard';
  static const String routeName = 'caregiver_dashboard';

  @override
  State<CaregiverDashboardScreen> createState() =>
      _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CaregiverDashboardProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CaregiverDashboardProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () => context.go(CaregiverHomeScreen.routePath),
          tooltip: 'Caregiver home',
        ),
        title: const Text('My seniors'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => provider.loadDashboard(),
          child: _buildBody(provider),
        ),
      ),
    );
  }

  Widget _buildBody(CaregiverDashboardProvider provider) {
    if (provider.isLoading && provider.seniors.isEmpty) {
      return const LoadingState(message: 'Loading dashboard…');
    }

    if (provider.errorMessage != null && provider.seniors.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.space7),
        children: [
          ErrorBanner(message: provider.errorMessage!),
        ],
      );
    }

    if (provider.seniors.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: AppTheme.space9),
          EmptyState(
            icon: Icons.people_outline,
            title: 'No seniors linked yet',
            message:
                'Generate a link code from your home screen and share it with your senior to connect.',
          ),
        ],
      );
    }

    final summary = provider.summary;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space6,
        AppTheme.space5,
        AppTheme.space6,
        AppTheme.space9,
      ),
      children: [
        const SectionHeader('Overview'),
        _OverviewGrid(summary: summary),
        const SizedBox(height: AppTheme.space7),
        SectionHeader('Seniors (${summary.totalSeniors})'),
        ...provider.seniors.map(
          (senior) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.space4),
            child: _SeniorCard(
              senior: senior,
              onTap: () {
                context.push('${SeniorDetailScreen.routePath}/${senior.uid}');
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppTheme.space3,
      crossAxisSpacing: AppTheme.space3,
      childAspectRatio: 1.55,
      children: [
        MetricTile(
          label: 'Total seniors',
          value: summary.totalSeniors.toString(),
          color: AppTheme.info,
          icon: Icons.people_outline,
        ),
        MetricTile(
          label: 'Checked in today',
          value: summary.checkedInCount.toString(),
          color: AppTheme.success,
          icon: Icons.check_circle_outline,
        ),
        MetricTile(
          label: 'Missed check-in',
          value: summary.missedCheckInCount.toString(),
          color: AppTheme.danger,
          icon: Icons.error_outline,
        ),
        MetricTile(
          label: 'Missed meds',
          value: summary.missedMedicationCount.toString(),
          color: AppTheme.warning,
          icon: Icons.medication_outlined,
        ),
      ],
    );
  }
}

class _SeniorCard extends StatelessWidget {
  const _SeniorCard({required this.senior, required this.onTap});

  final SeniorSummary senior;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lastCheckInStr =
        senior.lastCheckIn != null ? _formatDateTime(senior.lastCheckIn!) : '—';
    final nextMedStr = senior.nextMedicationTime != null
        ? _formatTime(senior.nextMedicationTime!)
        : 'None';

    final (statusLabel, statusColor) = switch (senior.checkInStatusToday) {
      CheckInStatus.confirmed => ('Checked in', AppTheme.success),
      CheckInStatus.missed => ('Missed', AppTheme.danger),
      _ => ('Pending', AppTheme.warning),
    };

    final accent = switch (senior.alertLevel) {
      AlertLevel.critical => AppTheme.danger,
      AlertLevel.warning => AppTheme.warning,
      _ => AppTheme.success,
    };

    final initials = _initialsOf(senior.fullName);

    return AppCard(
      onTap: onTap,
      accentColor: accent,
      padding: const EdgeInsets.all(AppTheme.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.brandPrimarySoft,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.brandPrimaryDark,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      senior.fullName,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Age ${senior.age?.toString() ?? '—'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(label: statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: AppTheme.space5),
          _AdherenceBar(percent: senior.adherencePercentage),
          const SizedBox(height: AppTheme.space5),
          _Stat(
            icon: Icons.schedule,
            label: 'Next medication',
            value: nextMedStr,
          ),
          const SizedBox(height: AppTheme.space2),
          _Stat(
            icon: Icons.event_available_outlined,
            label: 'Last check-in',
            value: lastCheckInStr,
          ),
          const SizedBox(height: AppTheme.space3),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space4,
              vertical: AppTheme.space3,
            ),
            decoration: BoxDecoration(
              color: senior.dosesMissedToday > 0
                  ? AppTheme.warningSoft
                  : AppTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Text(
              'Doses today: ${senior.dosesTakenToday}/${senior.totalDosesScheduledToday} taken \u00B7 ${senior.dosesMissedToday} missed',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: senior.dosesMissedToday > 0
                    ? AppTheme.warning
                    : AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                context.push('/care-chat/${senior.uid}');
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Open chat'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime d) {
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$month/$day ${d.year} $hour:$minute';
  }

  String _formatTime(DateTime d) {
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _initialsOf(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class _AdherenceBar extends StatelessWidget {
  const _AdherenceBar({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    final value = (percent / 100).clamp(0.0, 1.0);
    final color = value >= 0.85
        ? AppTheme.success
        : value >= 0.5
            ? AppTheme.warning
            : AppTheme.danger;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Today\'s adherence',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            Text(
              '${percent.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: AppTheme.border,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: AppTheme.space3),
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
