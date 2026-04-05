import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/vital_signs_model.dart';
import '../core/constants/ble_uuids.dart';

class SeizureEvent {
  final double   score;
  final DateTime timestamp;
  SeizureEvent({required this.score, required this.timestamp});
}

class BleService {
  BluetoothDevice? _device;

  final _vitalsController  = StreamController<VitalSignsModel>.broadcast();
  final _seizureController = StreamController<SeizureEvent>.broadcast();
  final _batteryController = StreamController<int>.broadcast();

  Stream<VitalSignsModel> get vitalsStream  => _vitalsController.stream;
  Stream<SeizureEvent>    get seizureStream => _seizureController.stream;
  Stream<int>             get batteryStream => _batteryController.stream;

  Future<void> connectToEpiTrack() async {
    // Scan pour le bracelet EpiTrack
    FlutterBluePlus.startScan(
      withServices: [Guid(BleUuids.service)],
      timeout: const Duration(seconds: 10),
    );

    await FlutterBluePlus.scanResults.firstWhere((results) {
      final found = results.any(
        (r) => r.device.platformName == BleUuids.deviceName);
      if (found) {
        _device = results
          .firstWhere((r) => r.device.platformName == BleUuids.deviceName)
          .device;
      }
      return found;
    });

    FlutterBluePlus.stopScan();

    if (_device == null) throw Exception('Bracelet EpiTrack introuvable');

    await _device!.connect(autoConnect: true);
    await _subscribeToNotifications();
  }

  Future<void> _subscribeToNotifications() async {
    final services = await _device!.discoverServices();
    for (final s in services) {
      if (s.serviceUuid == Guid(BleUuids.service)) {
        for (final c in s.characteristics) {
          if (c.characteristicUuid == Guid(BleUuids.seizureChar)) {
            await c.setNotifyValue(true);
            c.lastValueStream.listen(_onSeizureNotification);
          }
          if (c.characteristicUuid == Guid(BleUuids.vitalsChar)) {
            await c.setNotifyValue(true);
            c.lastValueStream.listen(_onVitalsUpdate);
          }
          if (c.characteristicUuid == Guid(BleUuids.batteryChar)) {
            await c.setNotifyValue(true);
            c.lastValueStream.listen((data) {
              if (data.isNotEmpty) _batteryController.add(data[0]);
            });
          }
        }
      }
    }
  }

  void _onSeizureNotification(List<int> data) {
    if (data.isEmpty) return;
    if (data[0] == 1) {
      final score = data.length > 2
        ? (data[1] << 8 | data[2]) / 100.0
        : 0.9;
      _seizureController.add(
        SeizureEvent(score: score, timestamp: DateTime.now()));
    }
  }

  void _onVitalsUpdate(List<int> data) {
    if (data.length < 30) return;
    try {
      _vitalsController.add(VitalSignsModel.fromBleBytes(data));
    } catch (_) {}
  }

  Future<void> disconnect() async {
    await _device?.disconnect();
    _device = null;
  }

  void dispose() {
    _vitalsController.close();
    _seizureController.close();
    _batteryController.close();
  }
}