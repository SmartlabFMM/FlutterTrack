import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/seizure_model.dart';

final seizureListProvider =
    FutureProvider.family<List<SeizureModel>, String>((ref, patientId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('crises')
      .where('patientId', isEqualTo: patientId)
      .orderBy('dateDebut', descending: true)
      .get();

  return snapshot.docs
      .map((doc) => SeizureModel.fromFirestore(doc.id, doc.data()))
      .toList();
});

final latestSeizureProvider =
    FutureProvider.family<SeizureModel?, String>((ref, patientId) async {
  final list = await ref.watch(seizureListProvider(patientId).future);
  return list.isEmpty ? null : list.first;
});

final patientDataProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, patientId) async {
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(patientId)
      .get();
  return doc.exists ? doc.data()! : {};
});

/// Score de prévention en temps réel depuis users/{uid}.preventionScore
final preventionScoreProvider =
    StreamProvider.family.autoDispose<double?, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snap) =>
          (snap.data()?['preventionScore'] as num?)?.toDouble());
});