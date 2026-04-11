import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Watches the `nextRdv` field on a patient's Firestore document in real-time.
/// Returns null while loading or if the field is absent.
final nextRdvProvider = StreamProvider.family<String?, String>((ref, patientId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(patientId)
      .snapshots()
      .map((snap) {
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    final rdv = data['nextRdv'];
    if (rdv is String && rdv.isNotEmpty) return rdv;
    return null;
  });
});
