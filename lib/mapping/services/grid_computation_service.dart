import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../models/grid_cell.dart';

/// Pure geometry service — no state, all methods static.
///
/// Provides:
///   - Field grid subdivision (bounding box scan + PIP filter)
///   - Point-in-polygon (ray casting)
///   - Shoelace area
///   - Haversine distance
///   - Perimeter calculation
///
/// These algorithms were originally in map_screen.dart as private functions.
/// They are moved here so they can be reused by both the controller and services.
class GridComputationService {
  static const _uuid = Uuid();

  // ── 1. Grid Builder ───────────────────────────────────────────────

  /// Divide [polygon] into a regular lat/lon grid.
  /// Each cell is approximately [cellSizeMetres] × [cellSizeMetres].
  /// Only cells whose centre lies INSIDE the polygon are returned.
  ///
  /// [expectedMlPerCell] is assigned to every GridCell.expectedChemicalMl.
  /// Pass 0.0 on the first call (to count cells), then pass the real value.
  static List<GridCell> buildGrid(
    List<LatLng> polygon,
    double expectedMlPerCell, {
    double cellSizeMetres = 3.0,
  }) {
    assert(polygon.length >= 3, 'Polygon must have at least 3 points');

    final cellDeg = _metresToDeg(cellSizeMetres);
    final bbox = _boundingBox(polygon);
    final cells = <GridCell>[];

    for (double lat = bbox.minLat; lat < bbox.maxLat; lat += cellDeg) {
      for (double lon = bbox.minLon; lon < bbox.maxLon; lon += cellDeg) {
        final center = LatLng(lat + cellDeg / 2, lon + cellDeg / 2);

        // Only keep cells whose centre is inside the field polygon
        if (!pip(center, polygon)) continue;

        cells.add(GridCell(
          id: _uuid.v4(),
          center: center,
          polygon: [
            LatLng(lat, lon),
            LatLng(lat, lon + cellDeg),
            LatLng(lat + cellDeg, lon + cellDeg),
            LatLng(lat + cellDeg, lon),
          ],
          expectedChemicalMl: expectedMlPerCell,
        ));
      }
    }
    return cells;
  }

  // ── 2. Point-in-polygon (ray casting) ────────────────────────────

  /// Returns true if [pt] is inside [poly].
  /// Uses ray-casting algorithm (even-odd rule).
  static bool pip(LatLng pt, List<LatLng> poly) {
    bool inside = false;
    final n = poly.length;
    for (int i = 0, j = n - 1; i < n; j = i++) {
      final xi = poly[i].longitude;
      final yi = poly[i].latitude;
      final xj = poly[j].longitude;
      final yj = poly[j].latitude;

      final intersect = ((yi > pt.latitude) != (yj > pt.latitude)) &&
          (pt.longitude <
              (xj - xi) * (pt.latitude - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  // ── 3. Shoelace area ─────────────────────────────────────────────

  /// Calculate field area in square metres using the shoelace formula.
  /// Works on geographic coordinates — scaled by the Earth-surface factor.
  static double calcArea(List<LatLng> pts) {
    if (pts.length < 3) return 0.0;
    double area = 0;
    for (int i = 0; i < pts.length; i++) {
      final j = (i + 1) % pts.length;
      area += pts[i].latitude * pts[j].longitude;
      area -= pts[j].latitude * pts[i].longitude;
    }
    return area.abs() / 2 * 1.2365e10;
  }

  // ── 4. Haversine distance ─────────────────────────────────────────

  /// Distance in metres between two GPS points using the Haversine formula.
  static double haversine(LatLng a, LatLng b) {
    const r = 6371000.0; // Earth radius in metres
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLon = (b.longitude - a.longitude) * math.pi / 180;
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(a.latitude * math.pi / 180) *
            math.cos(b.latitude * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * r * math.asin(math.sqrt(h));
  }

  // ── 5. Perimeter ─────────────────────────────────────────────────

  /// Total perimeter in metres — sum of haversine distances along the polygon.
  static double calcPerimeter(List<LatLng> pts) {
    double total = 0;
    for (int i = 0; i < pts.length - 1; i++) {
      total += haversine(pts[i], pts[i + 1]);
    }
    return total;
  }

  // ── Private helpers ───────────────────────────────────────────────

  static ({
    double minLat,
    double maxLat,
    double minLon,
    double maxLon
  }) _boundingBox(List<LatLng> pts) {
    return (
      minLat: pts.map((p) => p.latitude).reduce(math.min),
      maxLat: pts.map((p) => p.latitude).reduce(math.max),
      minLon: pts.map((p) => p.longitude).reduce(math.min),
      maxLon: pts.map((p) => p.longitude).reduce(math.max),
    );
  }

  /// Convert metres to degrees of latitude.
  /// 1 degree latitude ≈ 111,320 metres (consistent everywhere on Earth).
  static double _metresToDeg(double metres) => metres / 111320.0;
}
