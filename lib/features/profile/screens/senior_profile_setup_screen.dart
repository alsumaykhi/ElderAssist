import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/set_pin_screen.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';

class SeniorProfileSetupScreen extends StatefulWidget {
  const SeniorProfileSetupScreen({super.key});

  static const String routePath = '/profile/senior';
  static const String routeName = 'senior_profile_setup';

  @override
  State<SeniorProfileSetupScreen> createState() =>
      _SeniorProfileSetupScreenState();
}

class _SeniorProfileSetupScreenState extends State<SeniorProfileSetupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();
  final _chronicConditionController = TextEditingController();
  final _allergyController = TextEditingController();

  String? _gender;
  TimeOfDay _checkInCutoff = const TimeOfDay(hour: 22, minute: 0);
  final List<String> _chronicConditions = [];
  final List<String> _allergies = [];

  static const List<String> _genders = ['Male', 'Female'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _chronicConditionController.dispose();
    _allergyController.dispose();
    super.dispose();
  }

  Future<void> _pickCheckInCutoff() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _checkInCutoff,
    );
    if (picked != null) {
      setState(() => _checkInCutoff = picked);
    }
  }

  void _addChronicCondition() {
    final text = _chronicConditionController.text.trim();
    if (text.isNotEmpty && !_chronicConditions.contains(text)) {
      setState(() {
        _chronicConditions.add(text);
        _chronicConditionController.clear();
      });
    }
  }

  void _addAllergy() {
    final text = _allergyController.text.trim();
    if (text.isNotEmpty && !_allergies.contains(text)) {
      setState(() {
        _allergies.add(text);
        _allergyController.clear();
      });
    }
  }

  Future<void> _onSave(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final router = GoRouter.of(context);

    final user = authProvider.state.firebaseUser;
    if (user == null) return;
    final hasPhone = user.phoneNumber != null && user.phoneNumber!.isNotEmpty;
    final hasEmail = user.email != null && user.email!.isNotEmpty;
    if (!hasPhone && !hasEmail) return;

    final checkInStr =
        '${_checkInCutoff.hour.toString().padLeft(2, '0')}:${_checkInCutoff.minute.toString().padLeft(2, '0')}';

    final profile = UserProfile(
      uid: user.uid,
      role: 'senior',
      phoneNumber: user.phoneNumber ?? '',
      email: user.email,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      createdAt: DateTime.now(),
      age: int.tryParse(_ageController.text.trim()),
      gender: _gender,
      chronicConditions: List.from(_chronicConditions),
      allergies: List.from(_allergies),
      emergencyContactName: _emergencyContactNameController.text.trim(),
      emergencyContactPhone: _emergencyContactPhoneController.text.trim(),
      checkInCutoff: checkInStr,
    );

    await profileProvider.saveProfile(profile);

    if (!context.mounted) return;

    if (profileProvider.errorMessage == null) {
      router.push(SetPinScreen.routePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space6,
            AppTheme.space5,
            AppTheme.space6,
            AppTheme.space9,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tell us about yourself',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.space3),
              const Text(
                'This helps us personalize your experience and your caregiver\u2019s view.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppTheme.space7),
              const SectionHeader('About you'),
              _LabeledField(
                controller: _firstNameController,
                label: 'First name',
                required: true,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: AppTheme.space4),
              _LabeledField(
                controller: _lastNameController,
                label: 'Last name',
                required: true,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: AppTheme.space4),
              _LabeledField(
                controller: _ageController,
                label: 'Age',
                required: true,
                icon: Icons.cake_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppTheme.space4),
              _LabeledDropdown<String>(
                label: 'Gender',
                icon: Icons.wc_outlined,
                value: _gender,
                items: _genders,
                onChanged: (v) => setState(() => _gender = v),
              ),
              const SizedBox(height: AppTheme.space7),
              const SectionHeader('Health'),
              _ChipListField(
                label: 'Chronic conditions',
                controller: _chronicConditionController,
                items: _chronicConditions,
                onAdd: _addChronicCondition,
                onRemove: (item) =>
                    setState(() => _chronicConditions.remove(item)),
              ),
              const SizedBox(height: AppTheme.space5),
              _ChipListField(
                label: 'Allergies',
                controller: _allergyController,
                items: _allergies,
                onAdd: _addAllergy,
                onRemove: (item) => setState(() => _allergies.remove(item)),
              ),
              const SizedBox(height: AppTheme.space7),
              const SectionHeader('Emergency contact'),
              _LabeledField(
                controller: _emergencyContactNameController,
                label: 'Contact name',
                required: true,
                icon: Icons.contact_emergency_outlined,
              ),
              const SizedBox(height: AppTheme.space4),
              _LabeledField(
                controller: _emergencyContactPhoneController,
                label: 'Contact phone',
                required: true,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppTheme.space7),
              const SectionHeader('Daily check-in'),
              _PickerRow(
                icon: Icons.access_time,
                label: 'Cutoff time',
                value: _checkInCutoff.format(context),
                onTap: _pickCheckInCutoff,
              ),
              const SizedBox(height: AppTheme.space7),
              if (profileProvider.errorMessage != null) ...[
                ErrorBanner(message: profileProvider.errorMessage!),
                const SizedBox(height: AppTheme.space5),
              ],
              PrimaryButton(
                label: 'Continue',
                icon: Icons.arrow_forward,
                isLoading: profileProvider.isLoading,
                onPressed: profileProvider.isLoading
                    ? null
                    : () => _onSave(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.controller,
    required this.label,
    required this.icon,
    this.required = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool required;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        prefixIcon: Icon(icon),
      ),
    );
  }
}

class _LabeledDropdown<T> extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      style: const TextStyle(
        fontSize: 18,
        color: AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      hint: const Text(
        'Select',
        style: TextStyle(color: AppTheme.textTertiary, fontSize: 17),
      ),
      items: items
          .map((v) => DropdownMenuItem<T>(
                value: v,
                child: Text(v.toString()),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _ChipListField extends StatelessWidget {
  const _ChipListField({
    required this.label,
    required this.controller,
    required this.items,
    required this.onAdd,
    required this.onRemove,
  });

  final String label;
  final TextEditingController controller;
  final List<String> items;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.space3),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(fontSize: 17),
                decoration: const InputDecoration(),
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: AppTheme.space3),
            SizedBox(
              height: 56,
              width: 56,
              child: IconButton.filled(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 24),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.brandPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: AppTheme.space3),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((t) {
              return InputChip(
                label: Text(
                  t,
                  style: const TextStyle(fontSize: 15),
                ),
                onDeleted: () => onRemove(t),
                backgroundColor: AppTheme.brandPrimarySoft,
                deleteIconColor: AppTheme.brandPrimaryDark,
                labelStyle: const TextStyle(
                  color: AppTheme.brandPrimaryDark,
                ),
                side: BorderSide.none,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

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
              Icon(icon, color: AppTheme.brandPrimary),
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
                      style: const TextStyle(
                        fontSize: 17,
                        color: AppTheme.textPrimary,
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
