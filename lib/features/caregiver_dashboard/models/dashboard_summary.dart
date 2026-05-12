class DashboardSummary {
  const DashboardSummary({
    required this.totalSeniors,
    required this.checkedInCount,
    required this.missedCheckInCount,
    required this.missedMedicationCount,
  });

  final int totalSeniors;
  final int checkedInCount;
  final int missedCheckInCount;
  final int missedMedicationCount;
}

