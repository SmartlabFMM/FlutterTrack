import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vital_signs_model.dart';
import '../services/ble_service.dart';

enum BleStatus { disconnected, scanning, connecting, connected, error }

class BleState {
  final BleStatus       status;
  final int             batteryLevel;
  final VitalSignsModel? latestVitals;
  final bool            seizureDetected;
  final double          seizureScore;
  const BleState({
    this.status = BleStatus.disconnected,
    this.batteryLevel = 0,
    this.latestVitals,
    this.seizureDetected = false,
    this.seizureScore = 0.0,
  });
  BleState copyWith({BleStatus? status, int? batteryLevel,
    VitalSignsModel? latestVitals, bool? seizureDetected, double? seizureScore}) =>
    BleState(
      status:          status ?? this.status,
      batteryLevel:    batteryLevel ?? this.batteryLevel,
      latestVitals:    latestVitals ?? this.latestVitals,
      seizureDetected: seizureDetected ?? this.seizureDetected,
      seizureScore:    seizureScore ?? this.seizureScore,
    );
}

class BleNotifier extends StateNotifier<BleState> {
  final BleService _ble;
  BleNotifier(this._ble) : super(const BleState()) {
    _ble.vitalsStream.listen((v) =>
      state = state.copyWith(latestVitals: v));
    _ble.seizureStream.listen((event) =>
      state = state.copyWith(
        seizureDetected: true, seizureScore: event.score));
    _ble.batteryStream.listen((b) =>
      state = state.copyWith(batteryLevel: b));
  }

  Future<void> connect() async {
    state = state.copyWith(status: BleStatus.scanning);
    await _ble.connectToEpiTrack();
    state = state.copyWith(status: BleStatus.connected);
  }

  void clearSeizureAlert() =>
    state = state.copyWith(seizureDetected: false, seizureScore: 0.0);
}

final bleServiceProvider  = Provider((_) => BleService());
final bleProvider = StateNotifierProvider<BleNotifier, BleState>(
  (ref) => BleNotifier(ref.read(bleServiceProvider)));