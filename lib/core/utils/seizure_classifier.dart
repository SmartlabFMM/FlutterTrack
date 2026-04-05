import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SeizureClassifier {
  SeizureClassifier._();

  static String severityLabel(double score) {
    if (score >= 0.92) return 'Sévère';
    if (score >= 0.85) return 'Modérée';
    return 'Légère';
  }

  static Color severityColor(double score) {
    if (score >= 0.92) return AppColors.seizureRed;
    if (score >= 0.85) return AppColors.warning;
    return AppColors.teal;
  }

  static bool isUrgent(double score) => score >= 0.90;

  static String durationFormatted(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return m > 0 ? '${m}min ${s}s' : '${s}s';
  }

  /// Interprétation locale simplifiée (sans réseau)
  static double estimateScore({
    required double maxAccel,
    required double gsrValue,
    required int heartRate,
  }) {
    double score = 0.0;
    if (maxAccel > 3.5) score += 0.50;
    else if (maxAccel > 2.0) score += 0.25;
    if (gsrValue > 0.7) score += 0.25;
    if (heartRate > 110) score += 0.20;
    else if (heartRate > 90) score += 0.10;
    return score.clamp(0.0, 1.0);
  }
}
