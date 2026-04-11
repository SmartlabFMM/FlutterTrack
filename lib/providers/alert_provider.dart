import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alert_model.dart';
import 'auth_provider.dart';

final alertListProvider = FutureProvider<List<AlertModel>>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];

  final snapshot = await FirebaseFirestore.instance
      .collection('alertes')
      .where('patientId', isEqualTo: user.linkedPatientId)
      .orderBy('timestamp', descending: true)
      .get();

  return snapshot.docs
      .map((doc) => AlertModel.fromFirestore(doc.id, doc.data()))
      .toList();
});

final unreadAlertCountProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(alertListProvider).whenData(
    (alerts) => alerts.where((a) => a.status == AlertStatus.unread).length,
  );
});