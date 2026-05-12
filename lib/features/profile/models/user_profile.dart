import 'package:cloud_firestore/cloud_firestore.dart';

/// User profile model with common and role-specific fields.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.role,
    required this.phoneNumber,
    this.email,
    required this.firstName,
    required this.lastName,
    required this.createdAt,
    this.age,
    this.gender,
    this.chronicConditions = const [],
    this.allergies = const [],
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.checkInCutoff,
  });

  final String uid;
  final String role;
  final String phoneNumber;
  /// Account email when the user signed in with email/password.
  final String? email;
  final String firstName;
  final String lastName;
  final DateTime createdAt;
  final int? age;
  final String? gender;
  final List<String> chronicConditions;
  final List<String> allergies;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? checkInCutoff;

  bool get isSenior => role == 'senior';
  bool get isCaregiver => role == 'caregiver';

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'uid': uid,
      'role': role,
      'phoneNumber': phoneNumber,
      'firstName': firstName,
      'lastName': lastName,
      'createdAt': Timestamp.fromDate(createdAt),
      'chronicConditions': chronicConditions,
      'allergies': allergies,
    };

    final accountEmail = email;
    if (accountEmail != null && accountEmail.isNotEmpty) {
      map['email'] = accountEmail;
    }
    if (age != null) map['age'] = age;
    if (gender != null) map['gender'] = gender;
    if (emergencyContactName != null) {
      map['emergencyContactName'] = emergencyContactName;
    }
    if (emergencyContactPhone != null) {
      map['emergencyContactPhone'] = emergencyContactPhone;
    }
    if (checkInCutoff != null) map['checkInCutoff'] = checkInCutoff;

    return map;
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final createdAt = map['createdAt'];
    return UserProfile(
      uid: map['uid'] as String? ?? '',
      role: map['role'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      email: map['email'] as String?,
      firstName: map['firstName'] as String? ?? '',
      lastName: map['lastName'] as String? ?? '',
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.now(),
      age: map['age'] as int?,
      gender: map['gender'] as String?,
      chronicConditions: (map['chronicConditions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      allergies:
          (map['allergies'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
              [],
      emergencyContactName: map['emergencyContactName'] as String?,
      emergencyContactPhone: map['emergencyContactPhone'] as String?,
      checkInCutoff: map['checkInCutoff'] as String?,
    );
  }

  UserProfile copyWith({
    String? uid,
    String? role,
    String? phoneNumber,
    String? email,
    String? firstName,
    String? lastName,
    DateTime? createdAt,
    int? age,
    String? gender,
    List<String>? chronicConditions,
    List<String>? allergies,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? checkInCutoff,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      createdAt: createdAt ?? this.createdAt,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      chronicConditions: chronicConditions ?? List.from(this.chronicConditions),
      allergies: allergies ?? List.from(this.allergies),
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      checkInCutoff: checkInCutoff ?? this.checkInCutoff,
    );
  }
}
