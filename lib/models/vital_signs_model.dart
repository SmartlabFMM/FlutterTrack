import 'dart:math';
import 'dart:typed_data';

class VitalSignsModel {
  final double   accelX, accelY, accelZ;
  final double   gyroX,  gyroY,  gyroZ;
  final int      heartRate;
  final double   gsrValue;
  final double   spo2;
  final DateTime timestamp;

  const VitalSignsModel({
    required this.accelX, required this.accelY, required this.accelZ,
    required this.gyroX,  required this.gyroY,  required this.gyroZ,
    required this.heartRate,
    required this.gsrValue,
    this.spo2 = 0,
    required this.timestamp,
  });

  double get accelMagnitude =>
    sqrt(accelX * accelX + accelY * accelY + accelZ * accelZ);

  bool get isHeartRateElevated => heartRate > 100;
  bool get isGsrElevated       => gsrValue > 0.7;

  factory VitalSignsModel.fromBleBytes(List<int> bytes) {
    final buf = ByteData.sublistView(Uint8List.fromList(bytes));
    return VitalSignsModel(
      accelX:    buf.getFloat32(0,  Endian.little),
      accelY:    buf.getFloat32(4,  Endian.little),
      accelZ:    buf.getFloat32(8,  Endian.little),
      gyroX:     buf.getFloat32(12, Endian.little),
      gyroY:     buf.getFloat32(16, Endian.little),
      gyroZ:     buf.getFloat32(20, Endian.little),
      heartRate: buf.getUint16(24,  Endian.little),
      gsrValue:  buf.getFloat32(26, Endian.little),
      // SpO₂ : octet 30 (uint8, 0–100 %). Absent sur firmware ancien → 0.
      spo2:      bytes.length > 30 ? buf.getUint8(30).toDouble() : 0,
      timestamp: DateTime.now(),
    );
  }
}