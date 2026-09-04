import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// The four possible spray coverage states for a single grid cell.
enum CoverageStatus { untreated, underSprayed, optimal, overSprayed }

/// One ~3m × 3m square of the field.
/// expectedChemicalMl is set at plan creation and never changes.
/// actualChemicalMl accumulates during live spraying.
/// status is updated by CoverageService after every chemical addition.
class GridCell {
  final String id;

  /// GPS coordinates of the centre of this cell.
  final LatLng center;

  /// Four corner points: [SW, SE, NE, NW]
  final List<LatLng> polygon;

  /// How much chemical this cell should receive (mL).
  /// Set once during SprayPlan creation — never changes after that.
  final double expectedChemicalMl;

  /// Accumulated actual chemical applied (mL).
  /// Starts at 0, increases on every GPS pass while solenoid is open.
  double actualChemicalMl = 0.0;

  /// Current coverage status. Updated by CoverageService.classifyCell().
  CoverageStatus status = CoverageStatus.untreated;

  GridCell({
    required this.id,
    required this.center,
    required this.polygon,
    required this.expectedChemicalMl,
  });

  /// Color used by FlutterMap PolygonLayer — matches existing app color tokens.
  Color get displayColor {
    switch (status) {
      case CoverageStatus.untreated:
        return Colors.white.withValues(alpha: 0.08); // gray
      case CoverageStatus.underSprayed:
        return const Color(0xFFFFD23F).withValues(alpha: 0.45); // yellow
      case CoverageStatus.optimal:
        return const Color(0xFF4ADE80).withValues(alpha: 0.50); // green
      case CoverageStatus.overSprayed:
        return const Color(0xFFFF4D4D).withValues(alpha: 0.55); // red
    }
  }

  /// Border color — slightly more opaque than fill for definition.
  Color get borderColor {
    switch (status) {
      case CoverageStatus.untreated:
        return Colors.white.withValues(alpha: 0.04);
      case CoverageStatus.underSprayed:
        return const Color(0xFFFFD23F).withValues(alpha: 0.60);
      case CoverageStatus.optimal:
        return const Color(0xFF4ADE80).withValues(alpha: 0.65);
      case CoverageStatus.overSprayed:
        return const Color(0xFFFF4D4D).withValues(alpha: 0.70);
    }
  }
}
