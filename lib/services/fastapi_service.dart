/// Service FastAPI — mock pour le prototype.
/// Remplacer l'implémentation par de vrais appels HTTP quand le serveur est prêt.
class FastApiService {
  FastApiService._();

  static const String _baseUrl = 'http://YOUR_FASTAPI_SERVER:8000';

  /// Prédit le score de crise à partir des données capteurs.
  /// Version mock : analyse locale simplifiée.
  static Future<double> predictSeizure({
    required List<double> accelData,
    required List<double> gsrData,
    required List<int>    heartRateData,
  }) async {
    await Future.delayed(const Duration(milliseconds: 80));

    if (accelData.isEmpty) return 0.0;

    final maxAccel   = accelData.reduce((a, b) => a > b ? a : b);
    final avgGsr     = gsrData.isEmpty ? 0.0
        : gsrData.reduce((a, b) => a + b) / gsrData.length;
    final avgHr      = heartRateData.isEmpty ? 0
        : heartRateData.reduce((a, b) => a + b) ~/ heartRateData.length;

    double score = 0.0;
    if (maxAccel > 3.5) score += 0.50;
    else if (maxAccel > 2.0) score += 0.25;
    if (avgGsr > 0.7) score += 0.25;
    if (avgHr > 110)  score += 0.20;
    else if (avgHr > 90) score += 0.10;

    return score.clamp(0.0, 1.0);
  }
}
