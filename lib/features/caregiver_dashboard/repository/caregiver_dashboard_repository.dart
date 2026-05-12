import '../models/dashboard_data.dart';
import '../models/senior_detail.dart';
import '../services/caregiver_dashboard_service.dart';

class CaregiverDashboardRepository {
  CaregiverDashboardRepository({
    required CaregiverDashboardService caregiverDashboardService,
  }) : _caregiverDashboardService = caregiverDashboardService;

  final CaregiverDashboardService _caregiverDashboardService;

  Future<DashboardData> fetchDashboardData(String caregiverUid) {
    return _caregiverDashboardService.fetchDashboardData(caregiverUid);
  }

  Future<SeniorDetail> fetchSeniorDetail(String seniorUid) {
    return _caregiverDashboardService.fetchSeniorDetail(seniorUid);
  }
}

