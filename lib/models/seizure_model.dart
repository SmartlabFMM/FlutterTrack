class SeizureModel {
  final int      id;
  final String   patientId;
  final String   patientName;
  final DateTime datetime;
  final int      durationSeconds;
  final double   mlScore;
  final bool     acknowledged;

  const SeizureModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.datetime,
    required this.durationSeconds,
    required this.mlScore,
    this.acknowledged = false,
  });

  String get durationFormatted {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return m > 0 ? '${m}min ${s}s' : '${s}s';
  }

  String get severityLabel {
    if (mlScore >= 0.92) return 'Sévère';
    if (mlScore >= 0.85) return 'Modérée';
    return 'Légère';
  }

  factory SeizureModel.fromOdoo(Map<String, dynamic> j) => SeizureModel(
    id:              j['id'] as int,
    patientId:       j['patient_id'][0].toString(),
    patientName:     j['patient_id'][1] as String,
    datetime:        DateTime.parse(j['seizure_date'] as String),
    durationSeconds: j['duration_seconds'] as int,
    mlScore:         (j['ml_score'] as num).toDouble(),
    acknowledged:    j['acknowledged'] as bool? ?? false,
  );
}