import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'tflite_service.dart';

/// Paramètres de baseline stockés dans users/{uid}.baselines Firestore.
class PatientBaseline {
  final double baselineHr;
  final double baselineGsr;
  final double stdHr;
  final double stdGsr;
  final int    nSamples;

  const PatientBaseline({
    this.baselineHr = 75.0,
    this.baselineGsr = 0.5,
    this.stdHr  = 15.0,
    this.stdGsr = 0.2,
    this.nSamples = 0,
  });

  factory PatientBaseline.fromMap(Map<String, dynamic> m) => PatientBaseline(
    baselineHr:  (m['baseline_hr']  as num?)?.toDouble() ?? 75.0,
    baselineGsr: (m['baseline_gsr'] as num?)?.toDouble() ?? 0.5,
    stdHr:       (m['std_hr']       as num?)?.toDouble() ?? 15.0,
    stdGsr:      (m['std_gsr']      as num?)?.toDouble() ?? 0.2,
    nSamples:    (m['n_samples']    as num?)?.toInt()    ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'baseline_hr':  baselineHr,
    'baseline_gsr': baselineGsr,
    'std_hr':       stdHr,
    'std_gsr':      stdGsr,
    'n_samples':    nSamples,
  };

  /// Mise à jour en ligne (Welford online algorithm).
  PatientBaseline update(double hr, double gsr) {
    final n   = nSamples + 1;
    final nf  = n.toDouble();
    final newHr  = baselineHr + (hr  - baselineHr)  / nf;
    final newGsr = baselineGsr + (gsr - baselineGsr) / nf;
    // Variance approchée : exponential moving variance
    const alpha = 0.05; // poids du passé
    final newStdHr  = stdHr  < 1.0 ? 15.0 :
        (1 - alpha) * stdHr  + alpha * (hr  - baselineHr).abs();
    final newStdGsr = stdGsr < 0.01 ? 0.2 :
        (1 - alpha) * stdGsr + alpha * (gsr - baselineGsr).abs();

    return PatientBaseline(
      baselineHr:  newHr,
      baselineGsr: newGsr,
      stdHr:       newStdHr.clamp(1.0, 50.0),
      stdGsr:      newStdGsr.clamp(0.01, 1.0),
      nSamples:    n > 10000 ? 10000 : n,
    );
  }
}

class PreventionService {
  PreventionService._();

  static Map<String, dynamic>? _scaler;

  static Future<void> _loadScaler() async {
    if (_scaler != null) return;
    final json = await rootBundle.loadString(
        'assets/models/scaler_prevention.json');
    _scaler = jsonDecode(json) as Map<String, dynamic>;
  }

  /// Calcule le score de prévention (0.0–1.0 = risque de crise).
  ///
  /// [habits] : {medicaments, alcool, sport, stress_level, sleep_hours, hydratation}
  /// [heartRate], [gsrValue] : valeurs BLE courantes
  /// [baseline] : baselines patient
  static Future<double> computeScore({
    required Map<String, dynamic> habits,
    required double heartRate,
    required double gsrValue,
    required PatientBaseline baseline,
  }) async {
    await _loadScaler();
    await TfliteInference.loadPrevention();

    final habitsScaler = _scaler!['habits'] as Map<String, dynamic>;
    final centers = (habitsScaler['center'] as List).cast<num>();
    final scales  = (habitsScaler['scale']  as List).cast<num>();

    // Valeurs brutes des habitudes (ordre du scaler)
    final rawHabits = [
      (habits['medicaments'] as num?)?.toDouble() ?? 1.0,
      (habits['alcool']      as num?)?.toDouble() ?? 0.0,
      (habits['sport']       as num?)?.toDouble() ?? 0.0,
      (habits['stress']      as num?)?.toDouble() ?? 2.0,
      (habits['sommeil']     as num?)?.toDouble() ?? 6.0,
      ((habits['hydratation'] as num?)?.toDouble() ?? 1.25) / 0.25,
    ];

    // RobustScaler : (x - center) / scale
    final scaledHabits = List.generate(6,
        (i) => (rawHabits[i] - centers[i].toDouble()) / scales[i].toDouble());

    // Normalisation FC et GSR avec baselines patient
    final hrNorm  = baseline.stdHr  > 0
        ? (heartRate - baseline.baselineHr)  / baseline.stdHr
        : 0.0;
    final gsrNorm = baseline.stdGsr > 0
        ? (gsrValue  - baseline.baselineGsr) / baseline.stdGsr
        : 0.0;

    final features = [...scaledHabits, hrNorm, gsrNorm];

    return TfliteInference.runPrevention(features);
  }
}
