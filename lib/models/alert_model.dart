enum AlertType { seizureDetected, sosManual, braceletDisconnected }
enum AlertStatus { unread, read, acknowledged }

class AlertModel {
  final int         id;
  final AlertType   type;
  final AlertStatus status;
  final String      patientId;
  final String      patientName;
  final DateTime    datetime;
  final double?     mlScore;
  final int?        durationSeconds;

  const AlertModel({
    required this.id,
    required this.type,
    required this.status,
    required this.patientId,
    required this.patientName,
    required this.datetime,
    this.mlScore,
    this.durationSeconds,
  });

  bool get isUrgent =>
    type == AlertType.seizureDetected && (mlScore ?? 0) >= 0.90;

  factory AlertModel.fromOdoo(Map<String, dynamic> j) => AlertModel(
    id:              j['id'] as int,
    type:            AlertType.seizureDetected,
    status:          j['acknowledged'] == true
                      ? AlertStatus.acknowledged : AlertStatus.unread,
    patientId:       j['patient_id'][0].toString(),
    patientName:     j['patient_id'][1] as String,
    datetime:        DateTime.parse(j['seizure_date'] as String),
    mlScore:         (j['ml_score'] as num?)?.toDouble(),
    durationSeconds: j['duration_seconds'] as int?,
  );
}