import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/notification_service.dart';
import '../models/medication.dart';
import '../models/medication_type.dart';
import '../repository/medication_repository.dart';

class MedicationProvider extends ChangeNotifier {
  MedicationProvider({
    required MedicationRepository medicationRepository,
    required NotificationService notificationService,
  })  : _medicationRepository = medicationRepository,
        _notificationService = notificationService;

  final MedicationRepository _medicationRepository;
  final NotificationService _notificationService;

  List<Medication> _medications = [];
  List<Medication> get medications => List.unmodifiable(_medications);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> loadMedications() async {
    final userId = _userId;
    if (userId == null) {
      _errorMessage = 'Please sign in to view medications.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _medications = await _medicationRepository.fetchMedications(userId);
      _errorMessage = null;
      await _notificationService.rehydrateScheduledReminders(_medications);
    } catch (_) {
      _errorMessage = 'Failed to load medications. Please try again.';
      _medications = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a supplement from the health assistant (default reminder time 09:00).
  Future<void> addSupplementFromAssistant({
    required String name,
    required String dosage,
  }) async {
    final trimmedName = name.trim();
    final trimmedDosage = dosage.trim();
    if (trimmedName.isEmpty) {
      _errorMessage = 'Supplement name is missing.';
      notifyListeners();
      return;
    }
    final med = Medication(
      id: '',
      name: trimmedName,
      dosage: trimmedDosage.isEmpty ? 'As directed' : trimmedDosage,
      times: const ['09:00'],
      startDate: DateTime.now(),
      endDate: null,
      isActive: true,
      createdAt: DateTime.now(),
      type: MedicationType.supplement,
    );
    await addMedication(med);
  }

  Future<void> addMedication(Medication medication) async {
    if (medication.name.trim().isEmpty) {
      _errorMessage = 'Please enter a medication name.';
      notifyListeners();
      return;
    }

    final userId = _userId;
    if (userId == null) {
      _errorMessage = 'Please sign in to add medications.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _medicationRepository.addMedication(userId, medication);
      await loadMedications();
      // Reminders are scheduled via rehydrateScheduledReminders in loadMedications
    } catch (_) {
      _errorMessage = 'Failed to add medication. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateMedication(Medication medication) async {
    final userId = _userId;
    if (userId == null) {
      _errorMessage = 'Please sign in to update medications.';
      notifyListeners();
      return;
    }

    Medication? existing;
    for (final m in _medications) {
      if (m.id == medication.id) { existing = m; break; }
    }
    if (existing == null) {
      _errorMessage = 'Medication not found.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _notificationService.cancelMedicationReminders(existing);
      await _medicationRepository.updateMedication(userId, medication);
      await loadMedications();
    } catch (_) {
      _errorMessage = 'Failed to update medication. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteMedication(String medicationId) async {
    final userId = _userId;
    if (userId == null) {
      _errorMessage = 'Please sign in to delete medications.';
      notifyListeners();
      return;
    }

    for (final m in _medications) {
      if (m.id == medicationId) {
        await _notificationService.cancelMedicationReminders(m);
        break;
      }
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _medicationRepository.deleteMedication(userId, medicationId);
      _medications = _medications.where((m) => m.id != medicationId).toList();
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Failed to delete medication. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
