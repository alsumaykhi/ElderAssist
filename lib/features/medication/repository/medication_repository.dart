import '../models/medication.dart';
import '../services/medication_service.dart';

class MedicationRepository {
  MedicationRepository({required MedicationService medicationService})
      : _medicationService = medicationService;

  final MedicationService _medicationService;

  Future<void> addMedication(String userId, Medication medication) =>
      _medicationService.addMedication(userId, medication);

  Future<void> updateMedication(String userId, Medication medication) =>
      _medicationService.updateMedication(userId, medication);

  Future<List<Medication>> fetchMedications(String userId) =>
      _medicationService.fetchMedications(userId);

  Future<void> deleteMedication(String userId, String medicationId) =>
      _medicationService.deleteMedication(userId, medicationId);
}
