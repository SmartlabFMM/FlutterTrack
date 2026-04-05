import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/odoo_service.dart';

enum AuthStatus { initial, loading, authenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String?    errorMessage;
  final bool       isNewAccount;
  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.isNewAccount = false,
  });
  AuthState copyWith({
    AuthStatus? status, UserModel? user,
    String? errorMessage, bool? isNewAccount}) =>
    AuthState(
      status:       status       ?? this.status,
      user:         user         ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      isNewAccount: isNewAccount ?? this.isNewAccount,
    );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final OdooService _odoo;
  AuthNotifier(this._odoo) : super(const AuthState(status: AuthStatus.initial));

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, isNewAccount: false);
    try {
      final user = await _odoo.authenticate(email, password);
      state = state.copyWith(
        status: AuthStatus.authenticated, user: user, isNewAccount: false);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Identifiants incorrects. Veuillez réessayer.');
    }
  }

  Future<void> register({
    required String   name,
    required String   email,
    required String   password,
    required UserRole role,
    String?           linkedPatientId,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, isNewAccount: false);
    try {
      final user = await _odoo.register(
        name: name, email: email, password: password,
        role: role, linkedPatientId: linkedPatientId);
      state = state.copyWith(
        status: AuthStatus.authenticated, user: user, isNewAccount: true);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void logout() {
    _odoo.logout();
    state = const AuthState(status: AuthStatus.initial);
  }
}

final odooServiceProvider = Provider((_) => OdooService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(odooServiceProvider)));