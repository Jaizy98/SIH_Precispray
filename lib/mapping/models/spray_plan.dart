import 'field_model.dart';
import 'grid_cell.dart';

/// Created by SprayPlanningService.createPlan() before spraying begins.
/// Holds the field, chemical dosage parameters, and all the grid cells.
class SprayPlan {
  final FieldModel field;
  final String pesticideName;

  /// Dosage in mL per hectare (read from the pesticide bottle label).
  final double dosageMlPerHectare;

  /// Total recommended chemical = dosageMlPerHectare × field.hectares
  final double totalRecommendedMl;

  /// Expected chemical per cell = totalRecommendedMl / cells.length
  final double expectedMlPerCell;

  /// All grid cells inside the field polygon.
  /// Each cell has expectedChemicalMl already set.
  final List<GridCell> cells;

  const SprayPlan({
    required this.field,
    required this.pesticideName,
    required this.dosageMlPerHectare,
    required this.totalRecommendedMl,
    required this.expectedMlPerCell,
    required this.cells,
  });
}
