import 'package:cloud_firestore/cloud_firestore.dart';

class CheckIn {
  const CheckIn({
    required this.date,
    required this.timestamp,
    required this.status,
  });

  /// Date in yyyy-MM-dd format.
  final String date;
  final DateTime timestamp;
  /// "confirmed" or "missed".
  final String status;

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
    };
  }

  factory CheckIn.fromMap(Map<String, dynamic> map) {
    final ts = map['timestamp'];
    return CheckIn(
      date: map['date'] as String? ?? '',
      timestamp: ts is Timestamp ? ts.toDate() : DateTime.now(),
      status: map['status'] as String? ?? 'missed',
    );
  }
}

