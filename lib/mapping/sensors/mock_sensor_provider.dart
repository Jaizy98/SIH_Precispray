import 'dart:async';
import 'sensor_provider.dart';
import '../models/sensor_reading.dart';

/// Simulates Arduino sensor data at 2 Hz (every 500ms).
/// Used during development when no hardware is connected.
///
/// All values are mutable public fields so you can simulate different
/// scenarios on the fly — e.g., change simulatedWindKmh to 20.0 in
/// the debug panel to test drift guard behaviour.
class MockSensorProvider implements SensorProvider {
  /// Flow rate in mL/sec. Default ≈ 0.5 L/min, typical knapsack sprayer.
  double simulatedFlowMlPerSec;

  /// Wind speed in km/h. Keep below 15 for normal spraying.
  double simulatedWindKmh;

  /// Set to true to simulate reverse air pressure (blowback from nozzle).
  bool simulatedReverseAir;

  /// Whether the solenoid valve is open (spraying active).
  bool simulatedSolenoidOpen;

  MockSensorProvider({
    this.simulatedFlowMlPerSec = 8.33,
    this.simulatedWindKmh = 5.0,
    this.simulatedReverseAir = false,
    this.simulatedSolenoidOpen = true,
  });

  final StreamController<SensorReading> _ctrl =
      StreamController<SensorReading>.broadcast();

  Timer? _ticker;
  SensorReading _latest = SensorReading.idle();

  @override
  SensorReading get latestReading => _latest;

  @override
  Stream<SensorReading> get readingStream => _ctrl.stream;

  @override
  Future<void> initialize() async {
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _latest = SensorReading(
        flowRateMlPerSec:
            simulatedSolenoidOpen ? simulatedFlowMlPerSec : 0.0,
        windSpeedKmh: simulatedWindKmh,
        reverseAirPressure: simulatedReverseAir,
        solenoidOpen: simulatedSolenoidOpen,
      );
      if (!_ctrl.isClosed) _ctrl.add(_latest);
    });
  }

  @override
  Future<void> dispose() async {
    _ticker?.cancel();
    if (!_ctrl.isClosed) await _ctrl.close();
  }
}
