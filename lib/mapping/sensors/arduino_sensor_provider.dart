import 'sensor_provider.dart';
import '../models/sensor_reading.dart';

/// Stub for future Arduino Bluetooth serial integration.
///
/// When the Arduino hardware is ready:
/// 1. Add flutter_bluetooth_serial (or similar) to pubspec.yaml
/// 2. Implement initialize() to scan + connect to Arduino
/// 3. Implement readingStream to parse incoming serial bytes into SensorReading
/// 4. No changes needed anywhere else — the controller uses SensorProvider interface
///
/// Expected Arduino serial protocol (to define with hardware team):
///   JSON line: {"flow":8.33,"wind":5.2,"reverseAir":false,"solenoid":true}\n
///   Or byte frame: [0xAA, flowHigh, flowLow, wind, flags, 0xBB]
class ArduinoSensorProvider implements SensorProvider {
  // TODO: inject flutter_bluetooth_serial BluetoothConnection instance here

  @override
  Future<void> initialize() async {
    // TODO: scan for Arduino device, establish serial connection
    throw UnimplementedError(
        'ArduinoSensorProvider.initialize() — hardware not connected yet');
  }

  @override
  SensorReading get latestReading => SensorReading.idle();

  @override
  Stream<SensorReading> get readingStream => const Stream.empty();

  @override
  Future<void> dispose() async {
    // TODO: close Bluetooth connection
  }
}
