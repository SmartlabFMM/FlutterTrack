import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'ble_provider.dart';

// Écoute bleProvider et écrit les vitaux + état crise dans Firestore
final vitalsSyncProvider = Provider<void>((ref) {
  final uid = ref.watch(authProvider).user?.uid;
  if (uid == null) return;

  // Transmet le uid au service BLE pour l'écriture dans 'signaux'
  ref.read(bleProvider.notifier).setPatientUid(uid);

  ref.listen<BleState>(bleProvider, (prev, next) {
    final v = next.latestVitals;

    // Sync vitaux live
    if (v != null && v != prev?.latestVitals) {
      FirebaseFirestore.instance.collection('users').doc(uid).set({
        'vitals_live': {
          'heartRate':      v.heartRate,
          'accelMagnitude': v.accelMagnitude,
          'gsrValue':       v.gsrValue,
          'updatedAt':      FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
    }

    // Sync état crise détectée (pour la famille)
    if (next.seizureDetected != prev?.seizureDetected) {
      FirebaseFirestore.instance.collection('users').doc(uid).set({
        'seizureDetected': next.seizureDetected,
        'riskScore':       next.seizureScore,
      }, SetOptions(merge: true));
    }
  });
});
