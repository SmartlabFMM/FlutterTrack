import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alert_model.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

final alertListProvider = FutureProvider<List<AlertModel>>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];

  String? filterPatientId;

  if (user.role == UserRole.family) {
    filterPatientId = user.linkedPatientId;
  } else if (user.role == UserRole.doctor) {
    final doctorDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    filterPatientId = doctorDoc.data()?['linkedPatientId'] as String?;
  }

  Query<Map<String, dynamic>> query = FirebaseFirestore.instance
      .collection('crises')
      .orderBy('dateDebut', descending: true);

  if (filterPatientId != null) {
    query = query.where('patientId', isEqualTo: filterPatientId);
  }

  final snapshot = await query.get();
  if (snapshot.docs.isEmpty) return [];

  // Résolution des noms depuis users/{patientId} pour éviter les données
  // dénormalisées incorrectes dans le champ patientNom des crises.
  final patientIds = snapshot.docs
      .map((d) => d.data()['patientId'] as String? ?? '')
      .where((id) => id.isNotEmpty)
      .toSet();

  final userDocs = await Future.wait(
      patientIds.map((id) =>
          FirebaseFirestore.instance.collection('users').doc(id).get()));

  final nameMap = <String, String>{};
  for (final u in userDocs) {
    if (u.exists) {
      final data = u.data()!;
      // N'utilise que les comptes dont le rôle est patient
      if (data['role'] == 'patient') {
        nameMap[u.id] = data['nom'] as String? ?? '';
      }
    }
  }

  final alerts = <AlertModel>[];
  for (final doc in snapshot.docs) {
    final data      = doc.data();
    final patientId = data['patientId'] as String? ?? '';

    // Ignore les crises dont le patientId ne correspond pas à un patient connu
    if (!nameMap.containsKey(patientId)) continue;

    final mlScore      = (data['niveauSeverite'] as num?)?.toDouble() ?? 0.0;
    final acknowledged = data['traitee'] as bool? ?? false;

    alerts.add(AlertModel(
      id:              doc.id,
      type:            AlertType.seizureDetected,
      status:          acknowledged
                         ? AlertStatus.acknowledged
                         : AlertStatus.unread,
      patientId:       patientId,
      patientName:     nameMap[patientId]!,
      datetime:        (data['dateDebut'] as Timestamp).toDate(),
      mlScore:         mlScore,
      durationSeconds: data['duree'] as int?,
    ));
  }
  return alerts;
});

final unreadAlertCountProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(alertListProvider).whenData(
    (alerts) => alerts.where((a) => a.status == AlertStatus.unread).length,
  );
});
