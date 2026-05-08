import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

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
    AuthStatus? status,
    UserModel?  user,
    String?     errorMessage,
    bool?       isNewAccount,
  }) => AuthState(
    status:       status       ?? this.status,
    user:         user         ?? this.user,
    errorMessage: errorMessage ?? this.errorMessage,
    isNewAccount: isNewAccount ?? this.isNewAccount,
  );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth     _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db  = FirebaseFirestore.instance;

  AuthNotifier() : super(const AuthState(status: AuthStatus.initial)) {
    // Écouter l'état de connexion Firebase au démarrage
    _auth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser == null) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      } else {
        await _loadUserFromFirestore(firebaseUser.uid);
      }
    });
  }

  Future<void> _loadUserFromFirestore(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final user = UserModel.fromFirestore(doc.data()!);
        if (user.disabled) {
          await _auth.signOut();
          state = state.copyWith(
            status:       AuthStatus.error,
            errorMessage: 'Ce compte a été désactivé. Contactez l\'administrateur.',
          );
          return;
        }
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user:   user,
        );
      } else {
        // Compte supprimé par l'admin → déconnecter + message
        await _auth.signOut();
        state = state.copyWith(
          status:       AuthStatus.error,
          errorMessage: 'Ce compte n\'existe plus. Contactez l\'administrateur.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status:       AuthStatus.error,
        errorMessage: 'Erreur de chargement du profil.',
      );
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
      await _loadUserFromFirestore(cred.user!.uid);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status:       AuthStatus.error,
        errorMessage: _authErrorMessage(e.code),
      );
    }
  }

  Future<void> register({
    required String   name,
    required String   email,
    required String   password,
    required UserRole role,
    String?           linkedPatientId,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);

      final uid  = cred.user!.uid;
      final user = UserModel(
        uid:             uid,
        name:            name,
        email:           email,
        role:            role,
        linkedPatientId: linkedPatientId ?? uid,
      );

      await _db.collection('users').doc(uid).set({
        ...user.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'fcmToken':  '',
      });

      state = state.copyWith(
        status:      AuthStatus.authenticated,
        user:        user,
        isNewAccount: true,
      );
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status:       AuthStatus.error,
        errorMessage: _authErrorMessage(e.code),
      );
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = AuthState(
      status: AuthStatus.unauthenticated,
      user: state.user,
    );
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé.';
      case 'weak-password':
        return 'Mot de passe trop faible (6 caractères minimum).';
      case 'invalid-email':
        return 'Adresse email invalide.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      default:
        return 'Une erreur est survenue. Réessayez.';
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);