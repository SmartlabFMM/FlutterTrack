/// Stub web — TFLite non disponible sur navigateur.
/// Retourne toujours des valeurs neutres pour ne pas bloquer la compilation web.
class DetectionResult {
  final int    label;
  final double confidence;
  const DetectionResult({required this.label, required this.confidence});
}

class TfliteInference {
  TfliteInference._();

  static Future<void> loadDetection() async {}
  static Future<void> loadPrevention() async {}

  static Future<DetectionResult> runDetection({
    required List<List<double>> accel,
    required List<List<double>> gyro,
    required List<List<double>> bio,
  }) async =>
      const DetectionResult(label: 0, confidence: 0.0);

  static Future<double> runPrevention(List<double> input) async => 0.0;

  static void dispose() {}
}
