import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/date_format.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/primary_button.dart';
import '../models/medication.dart';
import '../models/medication_type.dart';
import '../providers/medication_provider.dart';
import 'add_medication_screen.dart';

class MedicationListScreen extends StatefulWidget {
  const MedicationListScreen({super.key});

  static const String routePath = '/medications';
  static const String routeName = 'medications';

  @override
  State<MedicationListScreen> createState() => _MedicationListScreenState();
}

class _MedicationListScreenState extends State<MedicationListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicationProvider>().loadMedications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MedicationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My medications'),
      ),
      body: SafeArea(
        child: _buildBody(provider),
      ),
      floatingActionButton: provider.medications.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.go(AddMedicationScreen.routePath),
              icon: const Icon(Icons.add, size: 24),
              label: const Text(
                'Add medication',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppTheme.brandPrimary,
              foregroundColor: Colors.white,
            ),
    );
  }

  Widget _buildBody(MedicationProvider provider) {
    if (provider.isLoading && provider.medications.isEmpty) {
      return const LoadingState(message: 'Loading your medications…');
    }

    if (provider.errorMessage != null && provider.medications.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppTheme.space7),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ErrorBanner(message: provider.errorMessage!),
            const SizedBox(height: AppTheme.space6),
            PrimaryButton(
              label: 'Retry',
              icon: Icons.refresh,
              onPressed: () => provider.loadMedications(),
            ),
          ],
        ),
      );
    }

    if (provider.medications.isEmpty) {
      return EmptyState(
        icon: Icons.medication_outlined,
        title: 'No medications yet',
        message:
            'Add your first medication to start tracking what to take and when.',
        action: SizedBox(
          width: 260,
          child: PrimaryButton(
            label: 'Add medication',
            icon: Icons.add,
            onPressed: () => context.go(AddMedicationScreen.routePath),
          ),
        ),
      );
    }

    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space6,
            AppTheme.space5,
            AppTheme.space6,
            96,
          ),
          itemCount: provider.medications.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppTheme.space4),
          itemBuilder: (context, index) {
            final medication = provider.medications[index];
            return _MedicationCard(
              medication: medication,
              onDelete: () => _confirmDelete(context, provider, medication),
            );
          },
        ),
        if (provider.isLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }

  void _confirmDelete(
    BuildContext context,
    MedicationProvider provider,
    Medication medication,
  ) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete medication?'),
        content: Text('Remove ${medication.name} from your list?'),
        actionsPadding: const EdgeInsets.fromLTRB(8, 0, 12, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.danger,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        provider.deleteMedication(medication.id);
      }
    });
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({
    required this.medication,
    required this.onDelete,
  });

  final Medication medication;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isInactive = !medication.isActive;
    final isSupplement = medication.type == MedicationType.supplement;
    final times = medication.times;

    final accent = isInactive
        ? AppTheme.textTertiary
        : isSupplement
            ? AppTheme.brandAccent
            : AppTheme.brandPrimary;
    final accentSoft = isInactive
        ? AppTheme.surfaceMuted
        : isSupplement
            ? const Color(0xFFE6F4EE)
            : AppTheme.brandPrimarySoft;

    return AppCard(
      padding: const EdgeInsets.all(AppTheme.space6),
      accentColor: isInactive ? AppTheme.textTertiary : accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentSoft,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(
                  isSupplement ? Icons.eco_outlined : Icons.medication,
                  color: accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isSupplement || isInactive)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Wrap(
                          spacing: 6,
                          children: [
                            if (isSupplement)
                              StatusPill(
                                label: 'Supplement',
                                color: AppTheme.brandAccent,
                                icon: Icons.eco_outlined,
                              ),
                            if (isInactive)
                              const StatusPill(
                                label: 'Inactive',
                                color: AppTheme.textSecondary,
                              ),
                          ],
                        ),
                      ),
                    Text(
                      medication.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isInactive
                            ? AppTheme.textTertiary
                            : AppTheme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      medication.dosage,
                      style: TextStyle(
                        fontSize: 17,
                        color: isInactive
                            ? AppTheme.textTertiary
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                color: AppTheme.danger,
                tooltip: 'Delete',
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
              ),
            ],
          ),
          if (times.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space5),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: times
                  .map(
                    (t) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space4,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceMuted,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule,
                              size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            t,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: AppTheme.space5),
          const Divider(height: 1),
          const SizedBox(height: AppTheme.space4),
          _DateRow(
            icon: Icons.calendar_today_outlined,
            label: 'Started',
            value: formatDate(medication.startDate),
            isInactive: isInactive,
          ),
          if (medication.endDate != null) ...[
            const SizedBox(height: AppTheme.space3),
            _DateRow(
              icon: Icons.event_outlined,
              label: 'Ends',
              value: formatDate(medication.endDate!),
              isInactive: isInactive,
            ),
          ],
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isInactive,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isInactive;

  @override
  Widget build(BuildContext context) {
    final color =
        isInactive ? AppTheme.textTertiary : AppTheme.textSecondary;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppTheme.space3),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 15,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            color: isInactive ? AppTheme.textTertiary : AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
