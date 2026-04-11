import 'package:cloud_firestore/cloud_firestore.dart';

enum AlertType   { seizureDetected, sosManual, braceletDisconnected }
enum AlertStatus { unread, read, acknowledged }

class AlertModel {
  final String      id;
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

  factory AlertModel.fromFirestore(String id, Map<String, dynamic> data) =>
      AlertModel(
        id:              id,
        type:            _typeFromString(data['type'] as String? ?? ''),
        status:          _statusFromString(data['status'] as String? ?? ''),
        patientId:       data['patientId']   as String,
        patientName:     data['patientNom']  as String? ?? '',
        datetime:        (data['timestamp']  as Timestamp).toDate(),
        mlScore:         (data['mlScore']    as num?)?.toDouble(),
        durationSeconds: data['duree']       as int?,
      );

  Map<String, dynamic> toFirestore() => {
    'patientId':  patientId,
    'patientNom': patientName,
    'type':       type.name,
    'status':     status.name,
    'timestamp':  Timestamp.fromDate(datetime),
    'mlScore':    mlScore,
    'duree':      durationSeconds,
  };

  static AlertType _typeFromString(String s) => switch (s) {
    'sosManual'            => AlertType.sosManual,
    'braceletDisconnected' => AlertType.braceletDisconnected,
    _                      => AlertType.seizureDetected,
  };

  static AlertStatus _statusFromString(String s) => switch (s) {
    'read'         => AlertStatus.read,
    'acknowledged' => AlertStatus.acknowledged,
    _              => AlertStatus.unread,
  };
}