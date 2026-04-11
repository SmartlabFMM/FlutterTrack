import 'package:cloud_firestore/cloud_firestore.dart';

class SeizureModel {
  final String   id;
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

  factory SeizureModel.fromFirestore(String id, Map<String, dynamic> data) =>
      SeizureModel(
        id:              id,
        patientId:       data['patientId']  as String,
        patientName:     data['patientNom'] as String? ?? '',
        datetime:        (data['dateDebut'] as Timestamp).toDate(),
        durationSeconds: data['duree']      as int? ?? 0,
        mlScore:         (data['niveauSeverite'] as num?)?.toDouble() ?? 0.0,
        acknowledged:    data['traitee']    as bool? ?? false,
      );

  Map<String, dynamic> toFirestore() => {
    'patientId':       patientId,
    'patientNom':      patientName,
    'dateDebut':       Timestamp.fromDate(datetime),
    'duree':           durationSeconds,
    'niveauSeverite':  mlScore,
    'traitee':         acknowledged,
  };
}