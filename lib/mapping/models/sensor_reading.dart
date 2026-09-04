/// A single snapshot of what the spray equipment is doing right now.
///
/// During development (no hardware): values come from MockSensorProvider.
/// In production (Arduino connected): values come from ArduinoSensorProvider.
///
/// The controller and services ONLY interact with this model —
/// they never care where the data came from.
class SensorReading {
  /// Liquid flow rate in mL per second.
  /// 0.0 when solenoid is closed.
  final double flowRateMlPerSec;

  /// Wind speed in km/h.
  final double windSpeedKmh;

  /// True when reverse air pressure (blowback) is detected at the nozzle.
  final bool reverseAirPressure;

  /// True when the solenoid valve is open (spray is coming out).
  final bool solenoidOpen;

  const SensorReading({
    required this.flowRateMlPerSec,
    required this.windSpeedKmh,
    required this.reverseAirPressure,
    required this.solenoidOpen,
  });

  /// Drift condition is true when:
  ///   - Wind exceeds 15 km/h (chemical blows away)
  ///   - OR reverse air pressure detected (blowback)
  /// When drift is true, NO chemical reaches the crop.
  bool get isDriftCondition => windSpeedKmh > 15.0 || reverseAirPressure;

  /// Effective flow rate accounts for solenoid state AND drift.
  /// This is the value CoverageService uses to estimate actual chemical applied.
  double get effectiveFlowMlPerSec {
    if (!solenoidOpen || isDriftCondition) return 0.0;
    return flowRateMlPerSec;
  }

  /// Used before the first real sensor reading arrives.
  factory SensorReading.idle() => const SensorReading(
        flowRateMlPerSec: 0.0,
        windSpeedKmh: 0.0,
        reverseAirPressure: false,
        solenoidOpen: false,
      );

  @override
  String toString() =>
      'SensorReading(flow: ${flowRateMlPerSec.toStringAsFixed(2)} mL/s, '
      'wind: ${windSpeedKmh.toStringAsFixed(1)} km/h, '
      'reverseAir: $reverseAirPressure, '
      'solenoid: ${solenoidOpen ? "OPEN" : "CLOSED"}, '
      'drift: $isDriftCondition)';
}
