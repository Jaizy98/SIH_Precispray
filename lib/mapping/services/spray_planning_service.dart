import 'package:latlong2/latlong.dart';
import '../models/field_model.dart';
import '../models/spray_plan.dart';
import '../models/spray_session_result.dart';
import 'grid_computation_service.dart';

/// Chemical planning and session result aggregation.
///
/// Two responsibilities:
///   1. createPlan()        — divide field into grid, assign expected chemical per cell
///   2. buildSessionResult() — aggregate final stats after spraying is done
class SprayPlanningService {
  /// Default cell size in metres. Can be overridden for large fields.
  static const double defaultCellSizeMetres = 3.0;

  // ── 1. Create spray plan ──────────────────────────────────────────

  /// Build a SprayPlan for [field] using the given [dosageMlPerHectare].
  ///
  /// Steps:
  ///   1. Calculate totalRecommendedMl = dosage × field.hectares
  ///   2. Build grid with placeholder expectedMl = 0 (to count cells first)
  ///   3. expectedMlPerCell = totalRecommendedMl / cells.length
  ///   4. Rebuild grid with correct expectedMlPerCell
  ///   5. Return SprayPlan
  SprayPlan createPlan({
    required FieldModel field,
    required String pesticideName,
    required double dosageMlPerHectare,
    double cellSizeMetres = defaultCellSizeMetres,
  }) {
    assert(dosageMlPerHectare > 0, 'Dosage must be greater than 0');
    assert(field.hectares > 0, 'Field area must be greater than 0');

    final totalMl = dosageMlPerHectare * field.hectares;

    // First pass — count cells only (expectedMl = 0 placeholder)
    final countCells = GridComputationService.buildGrid(
      field.polygon,
      0.0,
      cellSizeMetres: cellSizeMetres,
    );

    if (countCells.isEmpty) {
      throw ArgumentError(
          'Field "${field.fieldName}" is too small — no grid cells generated. '
          'Try mapping a larger area.');
    }

    final expectedPerCell = totalMl / countCells.length;

    // Second pass — build real cells with correct expectedChemicalMl
    final finalCells = GridComputationService.buildGrid(
      field.polygon,
      expectedPerCell,
      cellSizeMetres: cellSizeMetres,
    );

    return SprayPlan(
      field: field,
      pesticideName: pesticideName,
      dosageMlPerHectare: dosageMlPerHectare,
      totalRecommendedMl: totalMl,
      expectedMlPerCell: expectedPerCell,
      cells: finalCells,
    );
  }

  // ── 2. Build session result ───────────────────────────────────────

  /// Aggregate a SpraySessionResult after spraying stops.
  ///
  /// Sums up all actualChemicalMl across cells,
  /// packages everything into the immutable result object.
  SpraySessionResult buildSessionResult({
    required SprayPlan plan,
    required List<LatLng> sprayPath,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    assert(
        !endTime.isBefore(startTime), 'endTime must not be before startTime');

    final totalActual = plan.cells
        .fold(0.0, (sum, cell) => sum + cell.actualChemicalMl);

    return SpraySessionResult(
      field: plan.field,
      pesticideName: plan.pesticideName,
      startTime: startTime,
      endTime: endTime,
      dosageMlPerHectare: plan.dosageMlPerHectare,
      totalRecommendedMl: plan.totalRecommendedMl,
      totalActualMl: totalActual,
      sprayPath: List.unmodifiable(sprayPath),
      cells: List.unmodifiable(plan.cells),
    );
  }
}
