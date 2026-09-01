import '../models/grid_cell.dart';
import '../models/sensor_reading.dart';

/// Real-time chemical estimation and cell classification.
/// Pure static methods — no state, no dependencies.
///
/// Called by MappingController on every GPS update during live spraying.
class CoverageService {
  // ── 1. Chemical estimation ────────────────────────────────────────

  /// Estimate how many mL of chemical landed on a cell during [elapsedSeconds].
  ///
  /// Formula: mL = effectiveFlowMlPerSec × elapsedSeconds
  ///
  /// effectiveFlowMlPerSec is already 0 when:
  ///   - solenoid is closed (valve shut)
  ///   - drift condition (wind > 15 km/h or reverse air pressure)
  ///
  /// So drift protection is handled automatically — no special case needed here.
  static double estimateChemical({
    required SensorReading reading,
    required double elapsedSeconds,
  }) {
    assert(elapsedSeconds >= 0, 'elapsedSeconds must be non-negative');
    return reading.effectiveFlowMlPerSec * elapsedSeconds;
  }

  // ── 2. Coverage classification ────────────────────────────────────

  /// Assign CoverageStatus to [cell] based on actual vs expected chemical.
  ///
  /// Thresholds (from Ramesh Blueprint):
  ///   actual == 0                               → untreated  (gray)
  ///   actual < 0.80 × expected                  → underSprayed (yellow)
  ///   0.80 × expected ≤ actual ≤ 1.20 × expected → optimal    (green)
  ///   actual > 1.20 × expected                  → overSprayed  (red)
  ///
  /// Mutates cell.status directly — returns nothing.
  static void classifyCell(GridCell cell) {
    final actual = cell.actualChemicalMl;
    final expected = cell.expectedChemicalMl;

    if (actual == 0.0) {
      cell.status = CoverageStatus.untreated;
    } else if (actual < 0.80 * expected) {
      cell.status = CoverageStatus.underSprayed;
    } else if (actual <= 1.20 * expected) {
      cell.status = CoverageStatus.optimal;
    } else {
      cell.status = CoverageStatus.overSprayed;
    }
  }

  // ── 3. Drift guard ────────────────────────────────────────────────

  /// Force a cell to UNTREATED when drift condition is active.
  ///
  /// Called when SensorReading.isDriftCondition is true.
  /// The cell retains any chemical accumulated before drift started —
  /// only the status is forced to untreated to reflect current pass.
  ///
  /// Note: On the next GPS pass (after drift clears), classifyCell()
  /// will re-evaluate based on total accumulated chemical.
  static void applyDriftGuard(GridCell cell) {
    cell.status = CoverageStatus.untreated;
  }
}
