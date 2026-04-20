import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../firebase_options.dart';

final _db   = FirebaseFirestore.instance;
final _auth = FirebaseAuth.instance;

// ── Liste de tous les utilisateurs ──────────────────────────────
final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return _db.collection('users').snapshots().map(
    (snap) => snap.docs
      .map((d) => UserModel.fromFirestore(d.data()))
      .toList(),
  );
});

// ── Stats globales ───────────────────────────────────────────────
final adminStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final users    = await _db.collection('users').get();
  final seizures = await _db.collection('seizures').get();

  int patients = 0, doctors = 0, families = 0, active = 0;
  for (final d in users.docs) {
    final data = d.data();
    final role = data['role'] as String? ?? 'patient';
    final disabled = data['disabled'] as bool? ?? false;
    if (role == 'patient') { patients++; if (!disabled) active++; }
    else if (role == 'doctor')  doctors++;
    else if (role == 'family')  families++;
  }
  return {
    'patients':  patients,
    'doctors':   doctors,
    'families':  families,
    'seizures':  seizures.size,
    'active':    active,
  };
});

// ── Créer un compte sans déconnecter l'admin ─────────────────────
Future<String> createUserAsAdmin({
  required String name,
  required String email,
  required String password,
  required UserRole role,
  String? linkedPatientId,
  String? doctorId,
  Map<String, dynamic> extraData = const {},
}) async {
  // Instance Firebase secondaire pour ne pas déconnecter l'admin
  FirebaseApp? secondaryApp;
  try {
    secondaryApp = await Firebase.initializeApp(
      name: 'secondary_${DateTime.now().millisecondsSinceEpoch}',
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
    final cred = await secondaryAuth.createUserWithEmailAndPassword(
      email: email, password: password);
    final uid = cred.user!.uid;

    await _db.collection('users').doc(uid).set({
      'uid':       uid,
      'nom':       name,
      'email':     email,
      'role':      role.name,
      'patientId': linkedPatientId ?? uid,
      if (doctorId != null) 'doctorId': doctorId,
      'disabled':  false,
      'isActive':  true,
      'createdAt': FieldValue.serverTimestamp(),
      ...extraData,
    });
    await secondaryAuth.signOut();
    return uid;
  } finally {
    await secondaryApp?.delete();
  }
}

// ── Désactiver / réactiver un compte ─────────────────────────────
Future<void> setUserDisabled(String uid, bool disabled) async {
  await _db.collection('users').doc(uid).update({
    'disabled': disabled,
    'isActive': !disabled,
  });
}

// ── Supprimer un compte ───────────────────────────────────────────
Future<void> deleteUserAccount(String uid) async {
  await _db.collection('users').doc(uid).delete();
}

// ── Mettre à jour le rôle ────────────────────────────────────────
Future<void> updateUserRole(String uid, UserRole role) async {
  await _db.collection('users').doc(uid).update({'role': role.name});
}

// ── Lier un patient à un médecin ─────────────────────────────────
Future<void> linkPatientToDoctor(String patientId, String doctorId) async {
  await _db.collection('users').doc(patientId).update(
    {'doctorId': doctorId});
}

// ── Lier un membre famille à un patient ──────────────────────────
Future<void> linkFamilyToPatient(String familyId, String patientId) async {
  await _db.collection('users').doc(familyId)
    .update({'patientId': patientId});
}
