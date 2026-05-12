import 'dashboard_summary.dart';
import 'senior_summary.dart';

class DashboardData {
  const DashboardData({
    required this.summary,
    required this.seniors,
  });

  final DashboardSummary summary;
  final List<SeniorSummary> seniors;
}

