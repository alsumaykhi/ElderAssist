enum CheckInStatus {
  confirmed,
  pending,
  missed,
}

enum AlertLevel {
  normal,
  warning,
  critical,
}

extension CheckInStatusParsing on CheckInStatus {
  static CheckInStatus fromFirestore(String? raw) {
    switch (raw) {
      case 'confirmed':
        return CheckInStatus.confirmed;
      case 'missed':
        return CheckInStatus.missed;
      default:
        return CheckInStatus.pending;
    }
  }
}

