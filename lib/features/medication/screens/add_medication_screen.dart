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
import 'medication_list_screen.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  static const String routePath = '/medications/add';
  static const String routeName = 'add_medication';

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MedicationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add medication'),
      ),
      body: SafeArea(
        child: MedicationForm(
          isSubmitting: provider.isLoading,
          errorMessage: provider.errorMessage,
          submitLabel: 'Save medication',
          submitIcon: Icons.save_outlined,
          onSubmit: (draft) async {
            await provider.addMedication(draft);
            if (!context.mounted) return;
            if (provider.errorMessage == null) {
              GoRouter.of(context).go(MedicationListScreen.routePath);
            }
          },
        ),
      ),
    );
  }
}

class MedicationForm extends StatefulWidget {
  const MedicationForm({
    super.key,
    this.initialMedication,
    this.isSubmitting = false,
    this.errorMessage,
    this.extraSection,
    this.submitLabel = 'Save',
    this.submitIcon = Icons.save_outlined,
    required this.onSubmit,
  });

  final Medication? initialMedication;
  final bool isSubmitting;
  final String? errorMessage;
  final Widget? extraSection;
  final String submitLabel;
  final IconData submitIcon;
  final Future<void> Function(Medication draft) onSubmit;

  @override
  State<MedicationForm> createState() => _MedicationFormState();
}

class _MedicationFormState extends State<MedicationForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late DateTime _startDate;
  DateTime? _endDate;
  late List<String> _times;
  late MedicationType _type;

  @override
  void initState() {
    super.initState();
    final med = widget.initialMedication;
    _nameController = TextEditingController(text: med?.name ?? '');
    _dosageController = TextEditingController(text: med?.dosage ?? '');
    _startDate = med?.startDate ?? DateTime.now();
    _endDate = med?.endDate;
    _times = List<String>.from(med?.times ?? <String>[]);
    _times.sort();
    _type = med?.type ?? MedicationType.medication;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _addTime() async {
    final now = DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: now.hour,
        minute: (now.minute ~/ 5) * 5,
      ),
    );
    if (picked != null) {
      final timeStr =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      if (!_times.contains(timeStr)) {
        setState(() {
          _times.add(timeStr);
          _times.sort();
        });
      }
    }
  }

  Future<void> _submit() async {
    final draft = Medication(
      id: widget.initialMedication?.id ?? '',
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      times: List<String>.from(_times),
      startDate: _startDate,
      endDate: _endDate,
      isActive: widget.initialMedication?.isActive ?? true,
      createdAt: widget.initialMedication?.createdAt ?? DateTime.now(),
      type: _type,
    );
    await widget.onSubmit(draft);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space6,
        AppTheme.space5,
        AppTheme.space6,
        AppTheme.space9,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader('Type'),
          SegmentedButton<MedicationType>(
            segments: const [
              ButtonSegment(
                value: MedicationType.medication,
                label: Text('Medication'),
                icon: Icon(Icons.medication),
              ),
              ButtonSegment(
                value: MedicationType.supplement,
                label: Text('Supplement'),
                icon: Icon(Icons.eco_outlined),
              ),
            ],
            selected: {_type},
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppTheme.brandPrimary,
              selectedForegroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            onSelectionChanged: (s) {
              setState(() => _type = s.first);
            },
          ),
          const SizedBox(height: AppTheme.space7),
          const SectionHeader('Details'),
          TextField(
            controller: _nameController,
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.label_outline),
            ),
          ),
          const SizedBox(height: AppTheme.space5),
          TextField(
            controller: _dosageController,
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(
              labelText: 'Dosage',
              prefixIcon: Icon(Icons.straighten),
            ),
          ),
          const SizedBox(height: AppTheme.space7),
          const SectionHeader('Schedule'),
          _PickerTile(
            icon: Icons.event_outlined,
            label: 'Start date',
            value: formatDate(_startDate),
            onTap: _pickStartDate,
          ),
          const SizedBox(height: AppTheme.space3),
          _PickerTile(
            icon: Icons.event_busy_outlined,
            label: 'End date',
            value: _endDate != null ? formatDate(_endDate!) : 'Not set (optional)',
            onTap: _pickEndDate,
            isMuted: _endDate == null,
          ),
          const SizedBox(height: AppTheme.space5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Times',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: _addTime,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add time'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space3),
          if (_times.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppTheme.space5),
              decoration: BoxDecoration(
                color: AppTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.textSecondary),
                  SizedBox(width: AppTheme.space3),
                  Expanded(
                    child: Text(
                      'No times added. Tap "Add time" to set when to take this medication.',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _times.map((t) {
                return InputChip(
                  label: Text(
                    t,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onDeleted: () => setState(() => _times.remove(t)),
                  backgroundColor: AppTheme.brandPrimarySoft,
                  deleteIconColor: AppTheme.brandPrimaryDark,
                  labelStyle: const TextStyle(
                    color: AppTheme.brandPrimaryDark,
                  ),
                  side: BorderSide.none,
                  avatar: const Icon(
                    Icons.schedule,
                    size: 18,
                    color: AppTheme.brandPrimaryDark,
                  ),
                );
              }).toList(),
            ),
          if (widget.extraSection != null) ...[
            const SizedBox(height: AppTheme.space7),
            widget.extraSection!,
          ],
          const SizedBox(height: AppTheme.space7),
          if (widget.errorMessage != null) ...[
            ErrorBanner(message: widget.errorMessage!),
            const SizedBox(height: AppTheme.space5),
          ],
          PrimaryButton(
            label: widget.submitLabel,
            icon: widget.submitIcon,
            isLoading: widget.isSubmitting,
            onPressed: widget.isSubmitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.isMuted = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space5,
            vertical: AppTheme.space5,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.brandPrimary, size: 22),
              const SizedBox(width: AppTheme.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 17,
                        color: isMuted
                            ? AppTheme.textTertiary
                            : AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
