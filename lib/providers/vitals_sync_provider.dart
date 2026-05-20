import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'ble_provider.dart';
import 'location_provider.dart';
import '../models/seizure_model.dart';
import '../services/prevention_service.dart';

// Écoute bleProvider et écrit les vitaux + état crise + prevention dans Firestore
final vitalsSyncProvider = Provider<void>((ref) {
  final uid = ref.watch(authProvider).user?.uid;
  if (uid == null) return;

  ref.read(bleProvider.notifier).setPatientUid(uid);

  // Démarrage immédiat du partage de localisation (continu, toujours actif)
  ref.read(locationSharingProvider.notifier)
      .startSharing(uid, LocationTrigger.always);

  // Baselines en mémoire (chargées depuis Firestore au premier tick)
  PatientBaseline baseline = const PatientBaseline();
  bool  baselineLoaded  = false;
  Timer? preventionTimer;

  // Charge les baselines depuis Firestore une seule fois
  Future<void> loadBaselines() async {
    if (baselineLoaded) return;
    baselineLoaded = true;
    final snap = await FirebaseFirestore.instance
        .collection('users').doc(uid).get();
    final raw = snap.data()?['baselines'] as Map<String, dynamic>?;
    if (raw != null) baseline = PatientBaseline.fromMap(raw);
  }

  loadBaselines();

  ref.listen<BleState>(bleProvider, (prev, next) {
    final v = next.latestVitals;

    // Sync vitaux live
    if (v != null && v != prev?.latestVitals) {
      FirebaseFirestore.instance.collection('users').doc(uid).set({
        'vitals_live': {
          'heartRate':      v.heartRate,
          'accelMagnitude': v.accelMagnitude,
          'gsrValue':       v.gsrValue,
          'spo2':           v.spo2,
          'updatedAt':      FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));

      // Mise à jour des baselines
      baseline = baseline.update(v.heartRate.toDouble(), v.gsrValue);

      // Calcul du score de prévention toutes les 5 minutes (throttle)
      preventionTimer ??= Timer(const Duration(minutes: 5), () async {
        preventionTimer = null;
        try {
          final now        = DateTime.now();
          final startOfDay = DateTime(now.year, now.month, now.day);
          final habitsSnap = await FirebaseFirestore.instance
              .collection('habitudes_patient')
              .where('patient_id', isEqualTo: uid)
              .where('timestamp',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

          final habits = habitsSnap.docs.isNotEmpty
              ? habitsSnap.docs.first.data()
              : <String, dynamic>{};

          final score = await PreventionService.computeScore(
            habits:    habits,
            heartRate: v.heartRate.toDouble(),
            gsrValue:  v.gsrValue,
            baseline:  baseline,
          );

          await FirebaseFirestore.instance
              .collection('users').doc(uid).set({
            'baselines':       baseline.toMap(),
            'preventionScore': score,
          }, SetOptions(merge: true));
        } catch (_) {}
      });
    }

    // Sync état crise détectée (pour la famille)
    final wasDetected = prev?.seizureDetected ?? false;
    if (next.seizureDetected != wasDetected) {
      FirebaseFirestore.instance.collection('users').doc(uid).set({
        'seizureDetected': next.seizureDetected,
        'riskScore':       next.seizureScore,
      }, SetOptions(merge: true));

      // Écriture du document crises lors du déclenchement
      if (next.seizureDetected && !wasDetected) {
        _createCrisisDocument(
          uid:         uid,
          score:       next.seizureScore,
          mlLabel:     next.mlLabel,
          mlLabelName: next.mlLabelName,
        );
      }
    }
  });

  ref.onDispose(() {
    preventionTimer?.cancel();
  });
});

Future<void> _createCrisisDocument({
  required String uid,
  required double score,
  required int    mlLabel,
  required String mlLabelName,
}) async {
  try {
    // Récupère le nom du patient pour l'enregistrement
    final userSnap = await FirebaseFirestore.instance
        .collection('users').doc(uid).get();
    final nom = userSnap.data()?['nom'] as String? ?? '';

    await FirebaseFirestore.instance.collection('crises').add({
      'patientId':      uid,
      'patientNom':     nom,
      'dateDebut':      FieldValue.serverTimestamp(),
      'duree':          0,
      'niveauSeverite': score,
      'mlLabel':        mlLabel,
      'mlLabelName':    mlLabelName.isEmpty
          ? SeizureModel.labelName(mlLabel)
          : mlLabelName,
      'traitee':        false,
    });
  } catch (_) {}
}
