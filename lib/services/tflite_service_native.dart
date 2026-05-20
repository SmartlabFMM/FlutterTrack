import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';

class DetectionResult {
  final int    label;
  final double confidence;
  const DetectionResult({required this.label, required this.confidence});
}

/// TFLite inference — plateformes natives uniquement (Android/iOS/Windows/Linux).
class TfliteInference {
  TfliteInference._();

  static Interpreter?            _detection;
  static Interpreter?            _prevention;
  static Map<String, dynamic>?   _detectionScaler;

  static Future<void> loadDetection() async {
    if (_detection != null) return;
    _detection = await Interpreter.fromAsset(
        'assets/models/detection_model.tflite');
    final raw = await rootBundle.loadString(
        'assets/models/scaler_detection.json');
    _detectionScaler = jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> loadPrevention() async {
    _prevention ??= await Interpreter.fromAsset(
        'assets/models/prevention_model.tflite');
  }

  // Applique StandardScaler : z = (x - mean) / std  sur chaque ligne [50][3].
  static List<List<double>> _scale(
      List<List<double>> window, List<num> mean, List<num> std) {
    return window.map((row) => List.generate(
        row.length,
        (i) => (row[i] - mean[i].toDouble()) / std[i].toDouble(),
    )).toList();
  }

  /// Inférence de détection multi-tenseurs.
  ///
  /// Chaque fenêtre doit contenir exactement 50 échantillons :
  ///   accel : [50][3]  — [accelX, accelY, accelZ] (g)
  ///   gyro  : [50][3]  — [gyroX,  gyroY,  gyroZ]  (rad/s)
  ///   bio   : [50][3]  — [heartRate (bpm), gsrValue (0-1), spo2 (0-100)]
  ///
  /// Retourne le label (argmax) et la confiance (prob max).
  static Future<DetectionResult> runDetection({
    required List<List<double>> accel,
    required List<List<double>> gyro,
    required List<List<double>> bio,
  }) async {
    if (_detection == null || _detectionScaler == null) {
      return const DetectionResult(label: 0, confidence: 0.0);
    }

    final accelScaler = _detectionScaler!['accel'] as Map<String, dynamic>;
    final gyroScaler  = _detectionScaler!['gyro']  as Map<String, dynamic>;
    final bioScaler   = _detectionScaler!['bio']   as Map<String, dynamic>;

    final sAccel = _scale(
        accel,
        (accelScaler['mean'] as List).cast<num>(),
        (accelScaler['std']  as List).cast<num>());
    final sGyro = _scale(
        gyro,
        (gyroScaler['mean'] as List).cast<num>(),
        (gyroScaler['std']  as List).cast<num>());
    final sBio = _scale(
        bio,
        (bioScaler['mean'] as List).cast<num>(),
        (bioScaler['std']  as List).cast<num>());

    // 3 tenseurs d'entrée, chacun de forme [1, 50, 3]
    final inputs = <Object>[[sAccel], [sGyro], [sBio]];

    final numClasses = _detection!.getOutputTensor(0).shape.last;
    final out = <int, Object>{
      0: [List<double>.filled(numClasses, 0.0)],
    };

    _detection!.runForMultipleInputs(inputs, out);

    final probs = (out[0]! as List)[0] as List<double>;
    int    lbl  = 0;
    double maxP = probs[0];
    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > maxP) { maxP = probs[i]; lbl = i; }
    }
    return DetectionResult(label: lbl, confidence: maxP);
  }

  static Future<double> runPrevention(List<double> input) async {
    if (_prevention == null) return 0.0;
    final inp = [input];
    final out = List.filled(1, [0.0]);
    _prevention!.run(inp, out);
    return (out[0][0] as num).toDouble().clamp(0.0, 1.0);
  }

  static void dispose() {
    _detection?.close();
    _prevention?.close();
    _detection       = null;
    _prevention      = null;
    _detectionScaler = null;
  }
}
