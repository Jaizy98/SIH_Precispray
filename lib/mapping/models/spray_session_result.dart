import 'package:latlong2/latlong.dart';
import 'field_model.dart';
import 'grid_cell.dart';

/// The final report card created when Ramesh presses "Stop Spraying".
///
/// This object is passed to SprayReportScreen — it contains everything
/// needed to display a full spray session analysis.
///
/// All fields are immutable. All stats are derived getters — no duplication.
class SpraySessionResult {
  final FieldModel field;
  final String pesticideName;
  final DateTime startTime;
  final DateTime endTime;

  /// Dosage used during planning (mL/hectare).
  final double dosageMlPerHectare;

  /// Total chemical the plan recommended for the whole field.
  final double totalRecommendedMl;

  /// Sum of actualChemicalMl across all cells — what was actually applied.
  final double totalActualMl;

  /// GPS points recorded during the spray walk.
  final List<LatLng> sprayPath;

  /// All grid cells with their final statuses and chemical values.
  final List<GridCell> cells;

  const SpraySessionResult({
    required this.field,
    required this.pesticideName,
    required this.startTime,
    required this.endTime,
    required this.dosageMlPerHectare,
    required this.totalRecommendedMl,
    required this.totalActualMl,
    required this.sprayPath,
    required this.cells,
  });

  // ── Cell count stats ─────────────────────────────────────────────

  int get totalCells => cells.length;

  int get optimalCells =>
      cells.where((c) => c.status == CoverageStatus.optimal).length;

  int get underSprayedCells =>
      cells.where((c) => c.status == CoverageStatus.underSprayed).length;

  int get overSprayedCells =>
      cells.where((c) => c.status == CoverageStatus.overSprayed).length;

  int get untreatedCells =>
      cells.where((c) => c.status == CoverageStatus.untreated).length;

  // ── Coverage stats ───────────────────────────────────────────────

  /// Percentage of field that received any chemical (optimal + under + over).
  double get coveragePct {
    if (totalCells == 0) return 0.0;
    return (optimalCells + underSprayedCells + overSprayedCells) /
        totalCells *
        100;
  }

  /// Duration of the spray session.
  Duration get duration => endTime.difference(startTime);

  /// Duration in minutes (decimal).
  double get durationMin => duration.inSeconds / 60.0;

  /// Hectares of field that received any chemical.
  double get coveredHectares => field.hectares * coveragePct / 100;

  /// Chemical saved compared to total recommended (clamped to 0 minimum).
  double get savedMl =>
      (totalRecommendedMl - totalActualMl).clamp(0.0, double.infinity);

  /// Chemical per hectare actually applied (for SprayReport efficiency card).
  double get actualMlPerHectare {
    if (coveredHectares <= 0) return 0.0;
    return totalActualMl / coveredHectares;
  }
}
