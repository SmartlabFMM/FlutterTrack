import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'ble_provider.dart';

// Écoute bleProvider et écrit les vitaux dans Firestore pour que la famille puisse les lire
final vitalsSyncProvider = Provider<void>((ref) {
  final uid = ref.watch(authProvider).user?.uid;
  if (uid == null) return;

  ref.listen<BleState>(bleProvider, (prev, next) {
    final v = next.latestVitals;
    if (v == null) return;
    if (v == prev?.latestVitals) return;

    FirebaseFirestore.instance.collection('users').doc(uid).set({
      'vitals_live': {
        'heartRate':      v.heartRate,
        'accelMagnitude': v.accelMagnitude,
        'gsrValue':       v.gsrValue,
        'updatedAt':      FieldValue.serverTimestamp(),
      }
    }, SetOptions(merge: true));
  });
});
