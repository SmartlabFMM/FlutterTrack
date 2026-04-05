enum UserRole { patient, family, doctor }

class UserModel {
  final int      uid;
  final String   name;
  final String   email;
  final UserRole role;
  final String   sessionId;
  final String?  linkedPatientId;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.sessionId,
    this.linkedPatientId,
  });

  factory UserModel.fromOdoo(Map<String, dynamic> json, String sessionId) {
    final groups = (json['groups_id'] as List).cast<int>();
    return UserModel(
      uid:             json['uid'] as int,
      name:            json['name'] as String,
      email:           json['login'] as String,
      role:            _roleFromGroups(groups, json),
      sessionId:       sessionId,
      linkedPatientId: json['patient_id']?.toString(),
    );
  }

  static UserRole _roleFromGroups(List<int> groups, Map json) {
    if (json['is_doctor'] == true)  return UserRole.doctor;
    if (json['is_family'] == true)  return UserRole.family;
    return UserRole.patient;
  }
}