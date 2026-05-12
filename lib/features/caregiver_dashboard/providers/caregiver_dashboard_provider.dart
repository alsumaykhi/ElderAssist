import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/dashboard_summary.dart';
import '../models/senior_detail.dart';
import '../models/senior_summary.dart';
import '../repository/caregiver_dashboard_repository.dart';

class CaregiverDashboardProvider extends ChangeNotifier {
  CaregiverDashboardProvider({
    required CaregiverDashboardRepository caregiverDashboardRepository,
  }) : _caregiverDashboardRepository = caregiverDashboardRepository;

  final CaregiverDashboardRepository _caregiverDashboardRepository;

  List<SeniorSummary> _seniors = [];
  List<SeniorSummary> get seniors => List.unmodifiable(_seniors);
  DashboardSummary _summary = const DashboardSummary(
    totalSeniors: 0,
    checkedInCount: 0,
    missedCheckInCount: 0,
    missedMedicationCount: 0,
  );
  DashboardSummary get summary => _summary;

  SeniorDetail? _selectedSeniorDetail;
  SeniorDetail? get selectedSeniorDetail => _selectedSeniorDetail;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _isDetailLoading = false;
  bool get isDetailLoading => _isDetailLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  String? _detailErrorMessage;
  String? get detailErrorMessage => _detailErrorMessage;

  Future<void> loadDashboard() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _errorMessage = 'Please sign in to view seniors.';
      _seniors = [];
      _summary = const DashboardSummary(
        totalSeniors: 0,
        checkedInCount: 0,
        missedCheckInCount: 0,
        missedMedicationCount: 0,
      );
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final dashboard = await _caregiverDashboardRepository.fetchDashboardData(uid);
      _seniors = dashboard.seniors;
      _summary = dashboard.summary;
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Failed to load seniors. Please try again.';
      _seniors = [];
      _summary = const DashboardSummary(
        totalSeniors: 0,
        checkedInCount: 0,
        missedCheckInCount: 0,
        missedMedicationCount: 0,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSeniorDetail(String seniorUid) async {
    _isDetailLoading = true;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      _selectedSeniorDetail =
          await _caregiverDashboardRepository.fetchSeniorDetail(seniorUid);
      _detailErrorMessage = null;
    } catch (_) {
      _selectedSeniorDetail = null;
      _detailErrorMessage = 'Failed to load senior details. Please try again.';
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }
}

