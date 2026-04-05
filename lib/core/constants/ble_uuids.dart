class BleUuids {
  BleUuids._();

  // Service principal EpiTrack ESP32
  static const String service         = '12345678-1234-1234-1234-123456789012';

  // Caractéristiques
  static const String seizureChar     = '12345678-1234-1234-1234-000000000001'; // NOTIFY
  static const String vitalsChar      = '12345678-1234-1234-1234-000000000002'; // NOTIFY
  static const String batteryChar     = '12345678-1234-1234-1234-000000000003'; // READ
  static const String commandChar     = '12345678-1234-1234-1234-000000000004'; // WRITE

  // Nom BLE du bracelet
  static const String deviceName      = 'EpiTrack-Bracelet';

  // Commandes ESP32
  static const int    cmdStartMonitor = 0x01;
  static const int    cmdStopMonitor  = 0x02;
  static const int    cmdCalibrate    = 0x03;
}