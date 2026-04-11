enum UserRole { patient, family, doctor, admin }

class UserModel {
  final String   uid;
  final String   name;
  final String   email;
  final UserRole role;
  final String?  linkedPatientId;
  final String?  doctorId;
  final bool     disabled;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.linkedPatientId,
    this.doctorId,
    this.disabled = false,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      uid:             data['uid']      as String? ?? '',
      name:            data['nom']      as String? ?? '',
      email:           data['email']    as String? ?? '',
      role:            _roleFromString(data['role'] as String? ?? 'patient'),
      linkedPatientId: data['patientId'] as String?,
      doctorId:        data['doctorId'] as String?,
      disabled:        data['disabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'uid':       uid,
    'nom':       name,
    'email':     email,
    'role':      role.name,
    'patientId': linkedPatientId ?? uid,
    if (doctorId != null) 'doctorId': doctorId,
    'disabled':  disabled,
  };

  static UserRole _roleFromString(String role) {
    switch (role) {
      case 'doctor':  return UserRole.doctor;
      case 'family':  return UserRole.family;
      case 'admin':   return UserRole.admin;
      default:        return UserRole.patient;
    }
  }
}