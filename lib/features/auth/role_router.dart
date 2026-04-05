import '../../models/user_model.dart';

class RoleRouter {
  static String redirectForRole(UserRole role) {
    return switch (role) {
      UserRole.patient => '/patient/dashboard',
      UserRole.family  => '/family/dashboard',
      UserRole.doctor  => '/doctor/patients',
    };
  }
}