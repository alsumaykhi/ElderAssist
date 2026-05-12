import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../models/senior_detail.dart';
import '../providers/caregiver_dashboard_provider.dart';

class SeniorDetailScreen extends StatefulWidget {
  const SeniorDetailScreen({super.key, required this.seniorUid});

  static const String routePath = '/caregiver-dashboard/senior';
  static const String routeName = 'senior_detail';

  final String seniorUid;

  @override
  State<SeniorDetailScreen> createState() => _SeniorDetailScreenState();
}

class _SeniorDetailScreenState extends State<SeniorDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<CaregiverDashboardProvider>()
          .loadSeniorDetail(widget.seniorUid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CaregiverDashboardProvider>();
    final detail = provider.selectedSeniorDetail;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Senior details'),
      ),
      body: SafeArea(
        child: provider.isDetailLoading && detail == null
            ? const LoadingState(message: 'Loading senior details…')
            : provider.detailErrorMessage != null && detail == null
                ? Padding(
                    padding: const EdgeInsets.all(AppTheme.space7),
                    child: ErrorBanner(message: provider.detailErrorMessage!),
                  )
                : detail == null
                    ? const EmptyState(
                        icon: Icons.person_outline,
                        title: 'No details available',
                        message: 'Try again later.',
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppTheme.space6,
                          AppTheme.space5,
                          AppTheme.space6,
                          AppTheme.space9,
                        ),
                        children: [
                          _ProfileHeader(detail: detail),
                          const SizedBox(height: AppTheme.space7),
                          const SectionHeader('Profile'),
                          _ProfileSection(detail: detail),
                          const SizedBox(height: AppTheme.space7),
                          const SectionHeader('Check-in history (7 days)'),
                          _CheckInHistorySection(detail: detail),
                          const SizedBox(height: AppTheme.space7),
                          const SectionHeader('Today\'s medication'),
                          _TodayMedicationSection(detail: detail),
                          const SizedBox(height: AppTheme.space7),
                          const SectionHeader('Weekly adherence'),
                          _WeeklyAdherenceSection(detail: detail),
                        ],
                      ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.detail});

  final SeniorDetail detail;

  @override
  Widget build(BuildContext context) {
    final initials = _initialsOf(detail.fullName);
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppTheme.brandPrimarySoft,
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.brandPrimaryDark,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.space5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.fullName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Age ${detail.age?.toString() ?? '—'} \u00B7 ${detail.gender ?? '—'}',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _initialsOf(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.detail});

  final SeniorDetail detail;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Row(
            label: 'Conditions',
            value: detail.conditions.isEmpty
                ? 'None'
                : detail.conditions.join(', '),
          ),
          const Divider(height: AppTheme.space5),
          _Row(
            label: 'Allergies',
            value:
                detail.allergies.isEmpty ? 'None' : detail.allergies.join(', '),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textPrimary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _CheckInHistorySection extends StatelessWidget {
  const _CheckInHistorySection({required this.detail});

  final SeniorDetail detail;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.space5),
      child: SizedBox(
        height: 96,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: detail.last7DaysCheckIns.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppTheme.space3),
          itemBuilder: (context, index) {
            final checkIn = detail.last7DaysCheckIns[index];
            final confirmed = checkIn.status == 'confirmed';
            final color = confirmed ? AppTheme.success : AppTheme.danger;
            final soft =
                confirmed ? AppTheme.successSoft : AppTheme.dangerSoft;

            return Container(
              width: 88,
              padding: const EdgeInsets.all(AppTheme.space3),
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    checkIn.date.length >= 5
                        ? checkIn.date.substring(5)
                        : checkIn.date,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    confirmed ? Icons.check_circle : Icons.cancel,
                    color: color,
                    size: 26,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    confirmed ? 'OK' : 'Missed',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TodayMedicationSection extends StatelessWidget {
  const _TodayMedicationSection({required this.detail});

  final SeniorDetail detail;

  @override
  Widget build(BuildContext context) {
    if (detail.todaysMedication.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppTheme.space6),
        child: Row(
          children: const [
            Icon(Icons.info_outline, color: AppTheme.textSecondary),
            SizedBox(width: AppTheme.space3),
            Expanded(
              child: Text(
                'No medication scheduled for today.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: detail.todaysMedication.map((med) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.space3),
          child: AppCard(
            padding: const EdgeInsets.all(AppTheme.space5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.medicationName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.space3),
                ...med.scheduledTimes.map((time) {
                  final status = med.statusByTime[time] ?? 'pending';
                  final (icon, color, label) = switch (status) {
                    'taken' => (
                        Icons.check_circle,
                        AppTheme.success,
                        'Taken'
                      ),
                    'missed' => (
                        Icons.cancel,
                        AppTheme.danger,
                        'Missed'
                      ),
                    _ => (
                        Icons.schedule,
                        AppTheme.warning,
                        'Pending'
                      ),
                  };
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(icon, color: color, size: 18),
                        const SizedBox(width: AppTheme.space3),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space3),
                        StatusPill(label: label, color: color),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _WeeklyAdherenceSection extends StatelessWidget {
  const _WeeklyAdherenceSection({required this.detail});

  final SeniorDetail detail;

  @override
  Widget build(BuildContext context) {
    final percent = detail.weeklyAdherencePercentage;
    final progress = (percent / 100).clamp(0.0, 1.0);
    final color = progress >= 0.85
        ? AppTheme.success
        : progress >= 0.5
            ? AppTheme.warning
            : AppTheme.danger;

    return AppCard(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                percent.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -1.5,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '%',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const Spacer(),
              StatusPill(
                label: progress >= 0.85
                    ? 'On track'
                    : progress >= 0.5
                        ? 'Needs attention'
                        : 'At risk',
                color: color,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space5),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: AppTheme.border,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
