import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

/// Represents a mapped agricultural field.
/// Created after Ramesh walks the boundary and taps "Close Field".
class FieldModel {
  final String id;
  final String fieldName;

  /// Closed polygon — last point equals first point.
  final List<LatLng> polygon;

  /// Total area in square metres (from shoelace formula).
  final double areaSqM;

  /// Total perimeter in metres (sum of haversine distances).
  final double perimeterM;

  final DateTime savedAt;

  const FieldModel({
    required this.id,
    required this.fieldName,
    required this.polygon,
    required this.areaSqM,
    required this.perimeterM,
    required this.savedAt,
  });

  double get hectares => areaSqM / 10000;
  double get acres => areaSqM / 4046.86;

  /// Factory — generates a UUID and stamps the current time automatically.
  factory FieldModel.create({
    required String fieldName,
    required List<LatLng> polygon,
    required double areaSqM,
    required double perimeterM,
  }) {
    return FieldModel(
      id: const Uuid().v4(),
      fieldName: fieldName.trim().isEmpty ? 'Unnamed Field' : fieldName.trim(),
      polygon: polygon,
      areaSqM: areaSqM,
      perimeterM: perimeterM,
      savedAt: DateTime.now(),
    );
  }
}
