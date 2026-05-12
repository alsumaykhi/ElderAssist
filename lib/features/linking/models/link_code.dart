import 'package:cloud_firestore/cloud_firestore.dart';

class LinkCode {
  const LinkCode({
    required this.code,
    required this.caregiverId,
    required this.createdAt,
    required this.isUsed,
    this.usedBy,
    this.usedAt,
  });

  final String code;
  final String caregiverId;
  final DateTime createdAt;
  final bool isUsed;
  final String? usedBy;
  final DateTime? usedAt;

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'caregiverId': caregiverId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isUsed': isUsed,
      'usedBy': usedBy,
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
    };
  }

  factory LinkCode.fromMap(Map<String, dynamic> map, {String? code}) {
    final createdAt = map['createdAt'];
    final usedAt = map['usedAt'];
    return LinkCode(
      code: code ?? map['code'] as String? ?? '',
      caregiverId: map['caregiverId'] as String? ?? '',
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.now(),
      isUsed: map['isUsed'] as bool? ?? false,
      usedBy: map['usedBy'] as String?,
      usedAt: usedAt is Timestamp ? usedAt.toDate() : null,
    );
  }
}
