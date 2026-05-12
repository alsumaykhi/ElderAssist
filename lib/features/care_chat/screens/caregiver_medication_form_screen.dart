import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../medication/models/medication.dart';
import '../../medication/screens/add_medication_screen.dart';
import '../providers/care_chat_provider.dart';

class CaregiverMedicationFormScreen extends StatefulWidget {
  const CaregiverMedicationFormScreen({
    super.key,
    required this.peerUid,
    required this.mode,
    this.medicationId,
  });

  static const String routeName = 'caregiver_medication_form';

  final String peerUid;
  final String mode;
  final String? medicationId;

  @override
  State<CaregiverMedicationFormScreen> createState() =>
      _CaregiverMedicationFormScreenState();
}

class _CaregiverMedicationFormScreenState
    extends State<CaregiverMedicationFormScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  Medication? _initialMedication;
  final TextEditingController _notesController = TextEditingController();

  bool get _isEdit => widget.mode == 'edit';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    if (!_isEdit) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final provider = context.read<CareChatProvider>();
      final meds = await provider.fetchSeniorMedications();
      final medId = widget.medicationId ?? '';
      final match = meds.where((m) => m.id == medId).toList();
      if (match.isEmpty) {
        setState(() {
          _error = 'Medication not found for edit proposal.';
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _initialMedication = match.first;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _submit(Medication draft) async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final provider = context.read<CareChatProvider>();
      final primaryTime = draft.times.isNotEmpty ? draft.times.first : '09:00';
      final notes = _notesController.text.trim();
      if (_isEdit) {
        final medId = _initialMedication?.id ?? '';
        if (medId.isEmpty) {
          throw Exception('Medication ID missing.');
        }
        await provider.sendMedicationEditProposal(
          medicationId: medId,
          name: draft.name,
          dosage: draft.dosage,
          time: primaryTime,
          notes: notes,
        );
      } else {
        await provider.sendMedicationProposal(
          name: draft.name,
          dosage: draft.dosage,
          time: primaryTime,
          notes: notes,
        );
      }
      if (!mounted) return;
      context.pop();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Propose medication edit' : 'Propose medication'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const LoadingState(message: 'Loading form…')
            : MedicationForm(
                initialMedication: _initialMedication,
                isSubmitting: _isSubmitting,
                errorMessage: _error,
                submitLabel: _isEdit ? 'Send edit proposal' : 'Send proposal',
                submitIcon: Icons.send_outlined,
                extraSection: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader('Proposal note'),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'Reason, precautions, or instructions',
                      ),
                    ),
                    const SizedBox(height: AppTheme.space3),
                    const Text(
                      'Senior approval is required before changes are applied.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                onSubmit: _submit,
              ),
      ),
    );
  }
}
