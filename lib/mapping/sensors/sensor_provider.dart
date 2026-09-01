import '../models/sensor_reading.dart';

/// Abstract contract for all sensor backends.
///
/// Current implementation: MockSensorProvider (no hardware needed)
/// Future implementation:  ArduinoSensorProvider (Bluetooth serial)
///
/// MappingController always talks to this interface — never to a concrete class.
/// Swapping providers requires ZERO changes to the controller or any service.
abstract class SensorProvider {
  /// Initialize the sensor connection.
  /// For Mock: starts a timer.
  /// For Arduino: opens Bluetooth serial connection.
  Future<void> initialize();

  /// Most recent sensor snapshot.
  /// Returns SensorReading.idle() before the first real reading.
  SensorReading get latestReading;

  /// Continuous stream of sensor readings.
  /// Controller listens to this during active spraying.
  Stream<SensorReading> get readingStream;

  /// Clean up — cancel timers, close ports, release resources.
  Future<void> dispose();
}
