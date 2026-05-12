import 'package:cloud_firestore/cloud_firestore.dart';

class DoseLog {
  const DoseLog({
    required this.id,
    required this.scheduledTime,
    required this.status,
    required this.timestamp,
  });

  final String id;
  final String scheduledTime;
  final String status;
  final DateTime timestamp;

  Map<String, dynamic> toMap() {
    return {
      'scheduledTime': scheduledTime,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory DoseLog.fromMap(Map<String, dynamic> map, {required String id}) {
    final ts = map['timestamp'];

    return DoseLog(
      id: id,
      scheduledTime: map['scheduledTime'] as String? ?? '',
      status: map['status'] as String? ?? 'taken',
      timestamp: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}

