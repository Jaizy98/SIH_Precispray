import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/field_model.dart';
import '../models/grid_cell.dart';
import '../models/spray_plan.dart';
import '../models/spray_session_result.dart';
import '../services/grid_computation_service.dart';
import '../services/spray_planning_service.dart';
import '../services/coverage_service.dart';
import '../sensors/sensor_provider.dart';
import '../sensors/mock_sensor_provider.dart';

/// All possible phases of the mapping + spraying workflow.
enum MappingPhase {
  idle,         // Nothing active — show "Start Mapping" button
  mapping,      // Walking field boundary — GPS collecting points
  fieldSaved,   // Field saved — show field list, "Start Spraying" button
  spraying,     // Live spray session active
  sprayDone,    // Session ended — show results, "View Report" button
}

/// Single source of truth for all mapping and spraying state.
///
/// MapScreen listens to this via addListener() and rebuilds on notifyListeners().
/// MapScreen NEVER computes anything — it only reads getters and calls methods.
///
/// Dependencies are injectable so tests can pass MockSensorProvider
/// and a custom SprayPlanningService without touching the UI.
class MappingController extends ChangeNotifier {
  final SprayPlanningService _planService;
  final SensorProvider _sensorProvider;

  MappingController({
    SprayPlanningService? planService,
    SensorProvider? sensorProvider,
  })  : _planService = planService ?? SprayPlanningService(),
        _sensorProvider = sensorProvider ?? MockSensorProvider();

  // ── Phase ─────────────────────────────────────────────────────────
  MappingPhase _phase = MappingPhase.idle;
  MappingPhase get phase => _phase;

  // ── GPS position ──────────────────────────────────────────────────
  LatLng _currentPos = const LatLng(18.5204, 73.8567); // default: Pune
  LatLng get currentPos => _currentPos;

  StreamSubscription<Position>? _posStream;
  StreamSubscription? _sensorStream;

  // ── Error state ───────────────────────────────────────────────────
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── Phase 1: Mapping state ────────────────────────────────────────
  final List<LatLng> _boundary = [];
  List<LatLng> get boundary => List.unmodifiable(_boundary);

  bool _canClose = false;
  bool get canClose => _canClose;

  double _closeDist = double.infinity;
  double get closeDist => _closeDist;

  // ── Saved fields ──────────────────────────────────────────────────
  final List<FieldModel> _fields = [];
  List<FieldModel> get fields => List.unmodifiable(_fields);

  FieldModel? _activeField;
  FieldModel? get activeField => _activeField;

  // ── Phase 3: Spray state ──────────────────────────────────────────
  SprayPlan? _plan;
  SprayPlan? get plan => _plan;

  final List<LatLng> _sprayPath = [];
  List<LatLng> get sprayPath => List.unmodifiable(_sprayPath);

  DateTime? _sprayStartTime;
  DateTime? _lastGpsTime;

  // ── Session result ────────────────────────────────────────────────
  SpraySessionResult? _sessionResult;
  SpraySessionResult? get sessionResult => _sessionResult;

  // ── Computed stat getters (derived from plan, no stored values) ───
  int get totalCells => _plan?.cells.length ?? 0;
  int get optimalCells =>
      _plan?.cells.where((c) => c.status == CoverageStatus.optimal).length ??
      0;
  int get underSprayedCells =>
      _plan?.cells
          .where((c) => c.status == CoverageStatus.underSprayed)
          .length ??
      0;
  int get overSprayedCells =>
      _plan?.cells
          .where((c) => c.status == CoverageStatus.overSprayed)
          .length ??
      0;
  int get untreatedCells =>
      _plan?.cells
          .where((c) => c.status == CoverageStatus.untreated)
          .length ??
      0;
  double get coveragePct => totalCells == 0
      ? 0.0
      : (optimalCells + underSprayedCells + overSprayedCells) /
          totalCells *
          100;

  // ── Sensor debug values (for UI debug panel) ──────────────────────
  String get sensorDebugString => _sensorProvider.latestReading.toString();

  // ══════════════════════════════════════════════════════════════════
  // PHASE 1 — FIELD MAPPING
  // ══════════════════════════════════════════════════════════════════

  /// Start recording GPS boundary. Clears any previous boundary.
  Future<void> startMapping() async {
    _boundary.clear();
    _canClose = false;
    _closeDist = double.infinity;
    _errorMessage = null;

    final hasPermission = await _ensureLocationPermission();
    if (!hasPermission) return;

    _phase = MappingPhase.mapping;
    notifyListeners();

    _posStream?.cancel();
    _posStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2, // new point every 2 metres moved
      ),
    ).listen(_onMappingPosition, onError: _onGpsError);
  }

  void _onMappingPosition(Position pos) {
    if (_phase != MappingPhase.mapping) return;

    // Discard noisy readings — accuracy > 15m is unreliable
    if (pos.accuracy > 15) return;

    final pt = LatLng(pos.latitude, pos.longitude);
    _currentPos = pt;
    _boundary.add(pt);

    // Check if close enough to first point to close the polygon
    if (_boundary.length >= 5) {
      _closeDist = GridComputationService.haversine(pt, _boundary.first);
      _canClose = _closeDist < 8.0;
    }

    notifyListeners();
  }

  /// Close the polygon, calculate area + perimeter, save the field.
  /// Returns the saved FieldModel so the UI can show its details.
  FieldModel finishMapping(String fieldName) {
    assert(_boundary.length >= 3, 'Need at least 3 boundary points');

    _posStream?.cancel();

    // Close the polygon — last point = first point
    final closed = [..._boundary, _boundary.first];
    final areaSqM = GridComputationService.calcArea(closed);
    final perimM = GridComputationService.calcPerimeter(closed);

    final field = FieldModel.create(
      fieldName: fieldName,
      polygon: closed,
      areaSqM: areaSqM,
      perimeterM: perimM,
    );

    _fields.add(field);
    _boundary.clear();
    _phase = MappingPhase.fieldSaved;
    notifyListeners();
    return field;
  }

  // ══════════════════════════════════════════════════════════════════
  // PHASE 2 — SPRAY PLANNING
  // ══════════════════════════════════════════════════════════════════

  /// Select which saved field to spray.
  void selectField(FieldModel? field) {
    _activeField = field;
    notifyListeners();
  }

  /// Create the spray plan and begin live spraying.
  /// Called by SprayPlanningSheet after user submits pesticide name + dosage.
  void beginSpraying({
    required FieldModel field,
    required String pesticideName,
    required double dosageMlPerHectare,
  }) {
    try {
      _plan = _planService.createPlan(
        field: field,
        pesticideName: pesticideName,
        dosageMlPerHectare: dosageMlPerHectare,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return;
    }

    _sprayPath.clear();
    _sprayStartTime = DateTime.now();
    _lastGpsTime = _sprayStartTime;
    _errorMessage = null;
    _phase = MappingPhase.spraying;
    notifyListeners();

    // Start sensor stream
    _sensorProvider.initialize();
    _sensorStream = _sensorProvider.readingStream.listen(
      (_) => notifyListeners(), // update UI on every sensor tick
    );

    // Start GPS stream (1m filter for fine coverage tracking)
    _posStream?.cancel();
    _posStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen(_onSprayPosition, onError: _onGpsError);
  }

  // ══════════════════════════════════════════════════════════════════
  // PHASE 3 — LIVE SPRAYING
  // ══════════════════════════════════════════════════════════════════

  void _onSprayPosition(Position pos) {
    if (_phase != MappingPhase.spraying || _plan == null) return;

    final pt = LatLng(pos.latitude, pos.longitude);
    _currentPos = pt;
    _sprayPath.add(pt);

    // Calculate elapsed time since last GPS update
    final now = DateTime.now();
    final elapsed = now.difference(_lastGpsTime!).inMilliseconds / 1000.0;
    _lastGpsTime = now;

    // Get latest sensor snapshot
    final reading = _sensorProvider.latestReading;

    // Find which grid cell the farmer is standing on
    final cell = _findCell(pt);

    if (cell != null) {
      if (!reading.isDriftCondition && reading.solenoidOpen) {
        // Normal spraying — add estimated chemical to this cell
        final ml = CoverageService.estimateChemical(
          reading: reading,
          elapsedSeconds: elapsed,
        );
        cell.actualChemicalMl += ml;
        CoverageService.classifyCell(cell);
      } else {
        // Drift or valve closed — this cell gets nothing this pass
        CoverageService.applyDriftGuard(cell);
      }
    }

    notifyListeners();
  }

  // ── Demo mode: manual spray trigger ──────────────────────────────

  /// Called every ~100ms while the user holds the "Spray" button.
  /// Simulates the solenoid valve being open at current GPS position.
  /// Each call applies [_demoFlowMlPerSec × 0.1 sec] of chemical to
  /// whichever grid cell the phone is currently standing on.
  ///
  /// This is the hackathon demo replacement for real ESP32/Arduino sensor data.
  static const double _demoFlowMlPerSec = 8.33; // ~0.5 L/min
  static const double _demoTickSeconds  = 0.1;  // how often the button fires

  void demoSprayTick() {
    if (_phase != MappingPhase.spraying || _plan == null) return;

    _sprayPath.add(_currentPos);

    final cell = _findCell(_currentPos);
    if (cell != null) {
      final ml = _demoFlowMlPerSec * _demoTickSeconds;
      cell.actualChemicalMl += ml;
      CoverageService.classifyCell(cell);
    }

    notifyListeners();
  }

  /// Linear scan to find which cell contains [pt].
  /// O(n) over ~800 cells — executes in < 1ms on modern phones.
  GridCell? _findCell(LatLng pt) {
    if (_plan == null) return null;
    for (final cell in _plan!.cells) {
      if (GridComputationService.pip(pt, cell.polygon)) return cell;
    }
    return null;
  }

  // ══════════════════════════════════════════════════════════════════
  // PHASE 4 — SPRAY COMPLETION
  // ══════════════════════════════════════════════════════════════════

  /// Stop spraying, build the session result, transition to sprayDone.
  void stopSpraying() {
    _posStream?.cancel();
    _sensorStream?.cancel();
    _sensorProvider.dispose();

    _sessionResult = _planService.buildSessionResult(
      plan: _plan!,
      sprayPath: _sprayPath,
      startTime: _sprayStartTime!,
      endTime: DateTime.now(),
    );

    _phase = MappingPhase.sprayDone;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════
  // RESET
  // ══════════════════════════════════════════════════════════════════

  void resetAll() {
    _posStream?.cancel();
    _sensorStream?.cancel();

    _boundary.clear();
    _sprayPath.clear();
    _plan = null;
    _activeField = null;
    _sessionResult = null;
    _canClose = false;
    _closeDist = double.infinity;
    _errorMessage = null;
    _phase = MappingPhase.idle;

    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════

  Future<bool> _ensureLocationPermission() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      _errorMessage =
          'Location permission denied. Please enable it in app settings.';
      notifyListeners();
      return false;
    }
    return true;
  }

  void _onGpsError(Object error) {
    _errorMessage = 'GPS error: $error';
    notifyListeners();
  }

  /// Initialize current position from a one-time GPS fix on app launch.
  Future<void> initCurrentPosition() async {
    final hasPermission = await _ensureLocationPermission();
    if (!hasPermission) return;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _currentPos = LatLng(pos.latitude, pos.longitude);
      notifyListeners();
    } catch (_) {
      // Keep default position if initial fix fails
    }
  }

  @override
  void dispose() {
    _posStream?.cancel();
    _sensorStream?.cancel();
    _sensorProvider.dispose();
    super.dispose();
  }
}
