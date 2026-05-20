import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vital_signs_model.dart';
import '../models/seizure_model.dart';
import '../services/ble_service.dart';
import '../services/tflite_service.dart';

enum BleStatus { disconnected, scanning, connecting, connected, error }

class BleState {
  final BleStatus        status;
  final int              batteryLevel;
  final VitalSignsModel? latestVitals;
  final bool             seizureDetected;
  final double           seizureScore;
  final int              mlLabel;
  final String           mlLabelName;

  const BleState({
    this.status          = BleStatus.disconnected,
    this.batteryLevel    = 0,
    this.latestVitals,
    this.seizureDetected = false,
    this.seizureScore    = 0.0,
    this.mlLabel         = 0,
    this.mlLabelName     = '',
  });

  BleState copyWith({
    BleStatus?        status,
    int?              batteryLevel,
    VitalSignsModel?  latestVitals,
    bool?             seizureDetected,
    double?           seizureScore,
    int?              mlLabel,
    String?           mlLabelName,
  }) => BleState(
    status:          status          ?? this.status,
    batteryLevel:    batteryLevel    ?? this.batteryLevel,
    latestVitals:    latestVitals    ?? this.latestVitals,
    seizureDetected: seizureDetected ?? this.seizureDetected,
    seizureScore:    seizureScore    ?? this.seizureScore,
    mlLabel:         mlLabel         ?? this.mlLabel,
    mlLabelName:     mlLabelName     ?? this.mlLabelName,
  );
}

class BleNotifier extends StateNotifier<BleState> {
  final BleService _ble;

  // Fenêtre glissante de 50 échantillons pour l'inférence de détection
  static const _windowSize = 50;
  final _window = <VitalSignsModel>[];
  bool _detecting = false;

  BleNotifier(this._ble) : super(const BleState()) {
    _ble.vitalsStream.listen((v) {
      state = state.copyWith(latestVitals: v);
      _addToWindow(v);
    });
    _ble.seizureStream.listen((event) => state = state.copyWith(
        seizureDetected: true, seizureScore: event.score));
    _ble.batteryStream.listen((b) => state = state.copyWith(batteryLevel: b));
  }

  void _addToWindow(VitalSignsModel v) {
    _window.add(v);
    if (_window.length >= _windowSize && !_detecting) {
      _runDetection();
    }
  }

  Future<void> _runDetection() async {
    if (_detecting || _window.length < _windowSize) return;
    _detecting = true;
    try {
      await TfliteInference.loadDetection();

      final samples = _window.take(_windowSize).toList();
      final accel = samples.map((v) =>
          [v.accelX, v.accelY, v.accelZ]).toList();
      final gyro  = samples.map((v) =>
          [v.gyroX,  v.gyroY,  v.gyroZ]).toList();
      final bio   = samples.map((v) =>
          [v.heartRate.toDouble(), v.gsrValue, v.spo2]).toList();

      final result = await TfliteInference.runDetection(
          accel: accel, gyro: gyro, bio: bio);

      // Seuil d'alerte : classe crise (>=2) et confiance suffisante (>=0.85)
      if (result.label >= 2 && result.confidence >= 0.85) {
        state = state.copyWith(
          seizureDetected: true,
          seizureScore:    result.confidence,
          mlLabel:         result.label,
          mlLabelName:     SeizureModel.labelName(result.label),
        );
      }

      // Fenêtre glissante : décalage de 50% (25 échantillons)
      if (_window.length >= _windowSize) {
        _window.removeRange(0, _windowSize ~/ 2);
      }
    } finally {
      _detecting = false;
    }
  }

  Future<void> connect() async {
    state = state.copyWith(status: BleStatus.scanning);
    await _ble.connectToEpiTrack();
    state = state.copyWith(status: BleStatus.connected);
  }

  void setPatientUid(String uid) => _ble.setPatientUid(uid);

  void clearSeizureAlert() => state = state.copyWith(
      seizureDetected: false,
      seizureScore:    0.0,
      mlLabel:         0,
      mlLabelName:     '');
}

final bleServiceProvider = Provider((_) => BleService());
final bleProvider = StateNotifierProvider<BleNotifier, BleState>(
    (ref) => BleNotifier(ref.read(bleServiceProvider)));
