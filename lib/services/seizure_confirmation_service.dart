import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class SeizureConfirmationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<int> confirmSeizure(String uid) => confirm(uid);

  Future<int> confirm(String uid) async {
    final now = DateTime.now();

    // ── 1. Signaux BLE des 30 dernières minutes ───────────────
    final signalsSnap = await _db
        .collection('signaux')
        .where('patient_id', isEqualTo: uid)
        .where('timestamp',
            isGreaterThanOrEqualTo:
                Timestamp.fromDate(now.subtract(const Duration(minutes: 30))))
        .get();

    final fcValues  = <double>[];
    final gsrValues = <double>[];

    for (final doc in signalsSnap.docs) {
      final d = doc.data();
      final fc  = (d['fc_bpm']        as num?)?.toDouble();
      final gsr = (d['gsr_normalise'] as num?)?.toDouble();
      if (fc  != null) fcValues .add(fc);
      if (gsr != null) gsrValues.add(gsr);
    }

    final fcMoyenne     = _mean(fcValues);
    final fcVariabilite = _stdDev(fcValues, fcMoyenne);
    final gsrMoyen      = _mean(gsrValues);

    // ── 2. Habitudes du jour ──────────────────────────────────
    final startOfDay = DateTime(now.year, now.month, now.day);
    final habitsSnap = await _db
        .collection('habitudes_patient')
        .where('patient_id', isEqualTo: uid)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    int    medicaments = 0;
    int    alcool      = 0;
    int    sport       = 0;
    double stress      = 0.0;
    double sommeil     = 0.0;
    double hydratation = 0.0;

    if (habitsSnap.docs.isNotEmpty) {
      final h = habitsSnap.docs.first.data();
      medicaments = (h['medicaments'] as num?)?.toInt() ?? 0;
      alcool      = (h['alcool']      as num?)?.toInt() ?? 0;
      sport       = (h['sport']       as num?)?.toInt() ?? 0;
      stress      = (h['stress']      as num?)?.toDouble() ?? 0.0;
      sommeil     = (h['sommeil']     as num?)?.toDouble() ?? 0.0;
      hydratation = (h['hydratation'] as num?)?.toDouble() ?? 0.0;
    }

    // ── 3. Écriture confirmation ──────────────────────────────
    await _db.collection('confirmations_patient').add({
      'patient_id':      uid,
      'timestamp':       FieldValue.serverTimestamp(),
      'label':           2,
      'fc_moyenne':      fcMoyenne,
      'fc_variabilite':  fcVariabilite,
      'gsr_moyen':       gsrMoyen,
      'medicaments':     medicaments,
      'alcool':          alcool,
      'sport':           sport,
      'stress':          stress,
      'sommeil':         sommeil,
      'hydratation':     hydratation,
    });

    // ── 4. Nombre total de confirmations ─────────────────────
    final countSnap = await _db
        .collection('confirmations_patient')
        .where('patient_id', isEqualTo: uid)
        .count()
        .get();

    return countSnap.count ?? 0;
  }

  double _mean(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double _stdDev(List<double> values, double mean) {
    if (values.length < 2) return 0.0;
    final variance = values
        .map((v) => (v - mean) * (v - mean))
        .reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }
}
