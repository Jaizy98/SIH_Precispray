import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';

import '../mapping/controllers/mapping_controller.dart';
import '../mapping/widgets/spray_planning_sheet.dart';
import 'spray_report_screen.dart';

// ── Design tokens — unchanged from original ───────────────────────
class _C {
  static const forestDeep = Color(0xFF06241A);
  static const orange     = Color(0xFFFF8C42);
  static const green      = Color(0xFF4ADE80);
  static const cyan       = Color(0xFF2DD4FF);
  static const yellow     = Color(0xFFFFD23F);
  static const red        = Color(0xFFFF4D4D);
  static const glass      = Color(0x0FFFFFFF);
  static const glassBorder= Color(0x1FFFFFFF);
  static const textBody   = Color(0xFFCDEBD8);
  static const textMuted  = Color(0xFFA9D9C2);
}

TextStyle _heading({double size = 20, Color color = Colors.white}) =>
    GoogleFonts.spaceGrotesk(fontSize: size, fontWeight: FontWeight.w700, color: color);
TextStyle _body({double size = 14, Color color = _C.textBody}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: FontWeight.w500, color: color);
TextStyle _mono({double size = 24, Color color = _C.yellow}) =>
    GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: FontWeight.w600, color: color);

// ══════════════════════════════════════════════════════════════════
// MAP SCREEN — thin UI shell driven by MappingController
// ══════════════════════════════════════════════════════════════════
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapCtrl = MapController();
  late final MappingController _ctrl;

  // GPS pulse animation
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  // Demo spray — fires every 100ms while button is held
  Timer? _sprayTimer;
  bool _isHoldingSpraying = false;

  @override
  void initState() {
    super.initState();
    _ctrl = MappingController();
    _ctrl.addListener(_onControllerUpdate);
    _ctrl.initCurrentPosition();

    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerUpdate);
    _ctrl.dispose();
    _pulseCtrl.dispose();
    _sprayTimer?.cancel();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    // Pan map to follow current GPS position
    try {
      _mapCtrl.move(_ctrl.currentPos, _mapCtrl.camera.zoom);
    } catch (_) {}
    setState(() {});
  }

  // ══════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.forestDeep,
      body: Stack(children: [
        _buildMap(),

        // Top gradient fade
        Positioned(
          top: 0, left: 0, right: 0, height: 140,
          child: IgnorePointer(child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xD0061C14), Colors.transparent],
              ),
            ),
          )),
        ),

        // Bottom gradient fade
        Positioned(
          bottom: 0, left: 0, right: 0, height: 200,
          child: IgnorePointer(child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter, end: Alignment.topCenter,
                colors: [Color(0xD0061C14), Colors.transparent],
              ),
            ),
          )),
        ),

        SafeArea(child: Column(children: [
          _topBar(),
          _statsBar(),
          const Spacer(),
          if (_ctrl.phase == MappingPhase.idle ||
              _ctrl.phase == MappingPhase.fieldSaved) _fieldsList(),
          _bottomControls(),
        ])),

        // Close-polygon snap indicator
        if (_ctrl.phase == MappingPhase.mapping && _ctrl.canClose)
          _closeSnapIndicator(),

        // Spray legend overlay
        if (_ctrl.phase == MappingPhase.spraying ||
            _ctrl.phase == MappingPhase.sprayDone)
          _sprayLegend(),

        // Error banner
        if (_ctrl.errorMessage != null) _errorBanner(),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════
  // MAP WIDGET
  // ══════════════════════════════════════════════════════
  Widget _buildMap() {
    final layers = <Widget>[
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.precispray.app',
      ),
    ];

    // Saved field polygons
    for (final f in _ctrl.fields) {
      final isActive = _ctrl.activeField == f;
      layers.add(PolygonLayer(polygons: [
        Polygon(
          points: f.polygon,
          color: (isActive ? _C.cyan : _C.green).withValues(alpha: 0.10),
          borderColor: isActive ? _C.cyan : _C.green.withValues(alpha: 0.6),
          borderStrokeWidth: 2,
        ),
      ]));
    }

    // Boundary being drawn
    if (_ctrl.boundary.length >= 2) {
      layers.add(PolylineLayer(polylines: [
        Polyline(points: _ctrl.boundary, strokeWidth: 3, color: _C.yellow),
      ]));
      if (_ctrl.boundary.length >= 3) {
        layers.add(PolylineLayer(polylines: [
          Polyline(
            points: [_ctrl.boundary.last, _ctrl.boundary.first],
            strokeWidth: 2,
            color: _C.yellow.withValues(alpha: 0.4),
            pattern: const StrokePattern.dotted(),
          ),
        ]));
      }
      // First-point snap target marker
      layers.add(MarkerLayer(markers: [
        Marker(
          point: _ctrl.boundary.first, width: 18, height: 18,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: _C.yellow,
              boxShadow: [BoxShadow(color: _C.yellow.withValues(alpha: 0.6), blurRadius: 10)],
            ),
          ),
        ),
      ]));
    }

    // Coverage grid cells heatmap
    if (_ctrl.plan != null && _ctrl.plan!.cells.isNotEmpty) {
      layers.add(PolygonLayer(
        polygons: _ctrl.plan!.cells.map((cell) => Polygon(
          points: cell.polygon,
          color: cell.displayColor,
          borderColor: cell.borderColor,
          borderStrokeWidth: 0.3,
        )).toList(),
      ));
    }

    // Spray trail
    if (_ctrl.sprayPath.length >= 2) {
      layers.add(PolylineLayer(polylines: [
        Polyline(
          points: _ctrl.sprayPath, strokeWidth: 3,
          color: _C.cyan.withValues(alpha: 0.8),
        ),
      ]));
    }

    // Current GPS marker with pulse animation
    layers.add(AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => MarkerLayer(markers: [
        Marker(
          point: _ctrl.currentPos, width: 48, height: 48,
          child: Stack(alignment: Alignment.center, children: [
            Container(
              width: 48 * (0.6 + _pulse.value * 0.4),
              height: 48 * (0.6 + _pulse.value * 0.4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (_ctrl.phase == MappingPhase.spraying ? _C.cyan : _C.orange)
                    .withValues(alpha: 0.25 * (1 - _pulse.value * 0.5)),
              ),
            ),
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _ctrl.phase == MappingPhase.spraying ? _C.cyan : _C.orange,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(
                  color: (_ctrl.phase == MappingPhase.spraying ? _C.cyan : _C.orange)
                      .withValues(alpha: 0.6),
                  blurRadius: 10,
                )],
              ),
            ),
          ]),
        ),
      ]),
    ));

    return FlutterMap(
      mapController: _mapCtrl,
      options: MapOptions(initialCenter: _ctrl.currentPos, initialZoom: 18),
      children: layers,
    );
  }

  // ══════════════════════════════════════════════════════
  // TOP BAR
  // ══════════════════════════════════════════════════════
  Widget _topBar() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _C.glassBorder),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_phaseTitle(), style: _heading(size: 18)),
        Text(_phaseSubtitle(), style: _body(size: 11, color: _C.textMuted)),
      ])),
      if (_ctrl.phase != MappingPhase.idle)
        GestureDetector(
          onTap: _ctrl.resetAll,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _C.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.red.withValues(alpha: 0.35)),
            ),
            child: const Icon(Icons.refresh_rounded, color: _C.red, size: 20),
          ),
        ),
    ]),
  );

  String _phaseTitle() {
    switch (_ctrl.phase) {
      case MappingPhase.idle:      return 'Field Mapping';
      case MappingPhase.mapping:   return 'Drawing Boundary';
      case MappingPhase.fieldSaved:return 'Field Saved';
      case MappingPhase.spraying:  return 'Spraying…';
      case MappingPhase.sprayDone: return 'Spray Complete';
    }
  }

  String _phaseSubtitle() {
    switch (_ctrl.phase) {
      case MappingPhase.idle:
        return _ctrl.fields.isEmpty
            ? 'Start mapping to define your field'
            : '${_ctrl.fields.length} field(s) saved — tap to spray';
      case MappingPhase.mapping:
        return _ctrl.boundary.isEmpty
            ? 'Walk the field boundary'
            : '${_ctrl.boundary.length} pts · ${_ctrl.canClose ? "Tap ✓ to close!" : "${_ctrl.closeDist.toStringAsFixed(0)} m to close"}';
      case MappingPhase.fieldSaved:
        return '${_ctrl.fields.length} field(s) saved — select one to spray';
      case MappingPhase.spraying:
        return '${_ctrl.coveragePct.toStringAsFixed(1)}% covered · ${_ctrl.overSprayedCells} over-spray cells';
      case MappingPhase.sprayDone:
        return 'Coverage: ${_ctrl.coveragePct.toStringAsFixed(1)}% · Untreated: ${_ctrl.untreatedCells} cells';
    }
  }

  // ══════════════════════════════════════════════════════
  // STATS BAR
  // ══════════════════════════════════════════════════════
  Widget _statsBar() {
    if (_ctrl.phase == MappingPhase.idle && _ctrl.fields.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.glassBorder),
        ),
        child: _ctrl.phase == MappingPhase.mapping
          ? Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _stat('Points', '${_ctrl.boundary.length}', _C.yellow),
              _vDiv(),
              _stat('Dist', _ctrl.boundary.length >= 2
                  ? '${_livePerimeter().toStringAsFixed(0)} m' : '—', _C.cyan),
              _vDiv(),
              _stat('To Close', _ctrl.boundary.length >= 5
                  ? '${_ctrl.closeDist.toStringAsFixed(0)} m' : '—',
                  _ctrl.canClose ? _C.green : _C.textMuted),
            ])
          : (_ctrl.phase == MappingPhase.spraying || _ctrl.phase == MappingPhase.sprayDone)
          ? Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _stat('✅ Optimal', '${_ctrl.optimalCells}', _C.green),
              _vDiv(),
              _stat('🟨 Under', '${_ctrl.underSprayedCells}', _C.yellow),
              _vDiv(),
              _stat('🔴 Over', '${_ctrl.overSprayedCells}', _C.orange),
              _vDiv(),
              _stat('⬜ None', '${_ctrl.untreatedCells}', _C.textMuted),
            ])
          : Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _stat('Fields', '${_ctrl.fields.length}', _C.cyan),
              _vDiv(),
              _stat('Total Area',
                  '${_ctrl.fields.fold(0.0, (s, f) => s + f.acres).toStringAsFixed(2)} ac',
                  _C.green),
            ]),
      ),
    );
  }

  double _livePerimeter() {
    double d = 0;
    final b = _ctrl.boundary;
    for (int i = 0; i < b.length - 1; i++) {
      final dLat = (b[i + 1].latitude - b[i].latitude) * 111320;
      final dLon = (b[i + 1].longitude - b[i].longitude) * 111320;
      d += (dLat * dLat + dLon * dLon) > 0
          ? (dLat * dLat + dLon * dLon)
          : 0;
    }
    return d; // rough estimate for display only
  }

  Widget _stat(String lbl, String val, Color c) => Column(children: [
    Text(val, style: _mono(size: 13, color: c)),
    const SizedBox(height: 1),
    Text(lbl, style: _body(size: 9, color: _C.textMuted)),
  ]);
  Widget _vDiv() => Container(width: 1, height: 26, color: _C.glassBorder);

  // ══════════════════════════════════════════════════════
  // FIELDS LIST
  // ══════════════════════════════════════════════════════
  Widget _fieldsList() {
    if (_ctrl.fields.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 76,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: _ctrl.fields.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final f = _ctrl.fields[i];
            final isActive = _ctrl.activeField == f;
            return GestureDetector(
              onTap: () => _ctrl.selectField(isActive ? null : f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? _C.cyan.withValues(alpha: 0.18)
                      : Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive ? _C.cyan : _C.glassBorder,
                    width: isActive ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.crop_square_rounded, size: 12,
                          color: isActive ? _C.cyan : _C.green),
                      const SizedBox(width: 5),
                      Text(f.fieldName,
                          style: _body(size: 12, color: Colors.white)
                              .copyWith(fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 3),
                    Text(
                      '${f.acres.toStringAsFixed(3)} ac · ${f.polygon.length - 1} pts',
                      style: _body(size: 10, color: _C.textMuted),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // BOTTOM CONTROLS
  // ══════════════════════════════════════════════════════
  Widget _bottomControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        // ── idle ─────────────────────────────────────────
        if (_ctrl.phase == MappingPhase.idle) Row(children: [
          Expanded(child: _btn('Start Mapping', Icons.timeline_rounded,
              _C.green, _ctrl.startMapping)),
          if (_ctrl.activeField != null) ...[
            const SizedBox(width: 12),
            Expanded(child: _btn('Start Spraying', Icons.local_florist_rounded,
                _C.cyan, _showSprayPlanningSheet)),
          ],
        ]),

        // ── mapping ───────────────────────────────────────
        if (_ctrl.phase == MappingPhase.mapping) Row(children: [
          if (_ctrl.canClose)
            Expanded(child: _btn('✓ Close Field', Icons.check_circle_outline,
                _C.green, _onCloseField)),
          if (!_ctrl.canClose)
            Expanded(child: _btn('Walk boundary…', Icons.directions_walk,
                _C.yellow, null)),
          const SizedBox(width: 12),
          Expanded(child: _btn('Cancel', Icons.close_rounded,
              _C.red, _ctrl.resetAll)),
        ]),

        // ── fieldSaved ────────────────────────────────────
        if (_ctrl.phase == MappingPhase.fieldSaved) Row(children: [
          Expanded(child: _btn('Map Another', Icons.add_location_alt_outlined,
              _C.yellow, _ctrl.startMapping)),
          if (_ctrl.activeField != null) ...[
            const SizedBox(width: 12),
            Expanded(child: _btn('Start Spraying', Icons.local_florist_rounded,
                _C.cyan, _showSprayPlanningSheet)),
          ],
        ]),

      // ── spraying ──────────────────────────────────────
        if (_ctrl.phase == MappingPhase.spraying)
          _sprayingControls(),

        // ── sprayDone ─────────────────────────────────────
        if (_ctrl.phase == MappingPhase.sprayDone) ...[
          _sprayResultBanner(),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _btn('View Report', Icons.summarize_outlined,
                _C.green, _openReport)),
            const SizedBox(width: 12),
            Expanded(child: _btn('Done', Icons.check_rounded,
                _C.cyan, _ctrl.resetAll)),
          ]),
        ],
      ]),
    );
  }

  void _onCloseField() {
    if (_ctrl.boundary.length < 3) return;
    final ctrl = TextEditingController(
        text: 'Field ${_ctrl.fields.length + 1}');
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D3526),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Name this field', style: _heading(size: 18)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${_ctrl.boundary.length} boundary points collected',
              style: _body(size: 12, color: _C.textMuted)),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: _C.glass,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.glassBorder),
            ),
            child: TextField(
              controller: ctrl,
              style: _body(size: 15, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. North Plot A',
                hintStyle: _body(size: 15, color: _C.textMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: _body(size: 14, color: _C.textMuted)),
          ),
          GestureDetector(
            onTap: () {
              final field = _ctrl.finishMapping(ctrl.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: const Color(0xFF0D3526),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                behavior: SnackBarBehavior.floating,
                content: Text(
                  '${field.fieldName} saved · ${field.acres.toStringAsFixed(3)} ac',
                  style: _body(size: 13, color: _C.green),
                ),
                duration: const Duration(seconds: 3),
              ));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_C.green, _C.cyan]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Save',
                  style: _body(size: 14, color: _C.forestDeep)
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSprayPlanningSheet() {
    if (_ctrl.activeField == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SprayPlanningSheet(
        field: _ctrl.activeField!,
        controller: _ctrl,
      ),
    );
  }

  // ── Demo spray controls (shown during spraying phase) ─────────────
  Widget _sprayingControls() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Hold-to-spray button
      GestureDetector(
        onTapDown: (_) => _startSprayHold(),
        onTapUp: (_) => _stopSprayHold(),
        onTapCancel: () => _stopSprayHold(),
        onLongPressStart: (_) => _startSprayHold(),
        onLongPressEnd: (_) => _stopSprayHold(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: _isHoldingSpraying
                ? const LinearGradient(
                    colors: [Color(0xFF4ADE80), Color(0xFF2DD4FF)])
                : LinearGradient(colors: [
                    _C.cyan.withValues(alpha: 0.3),
                    _C.cyan.withValues(alpha: 0.15),
                  ]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHoldingSpraying ? _C.green : _C.cyan,
              width: _isHoldingSpraying ? 2 : 1,
            ),
            boxShadow: _isHoldingSpraying
                ? [BoxShadow(
                    color: _C.green.withValues(alpha: 0.45),
                    blurRadius: 24,
                    spreadRadius: 2,
                  )]
                : [],
          ),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(
                _isHoldingSpraying
                    ? Icons.water_drop
                    : Icons.water_drop_outlined,
                size: 22,
                color: _isHoldingSpraying ? _C.forestDeep : _C.cyan,
              ),
              const SizedBox(width: 10),
              Text(
                _isHoldingSpraying ? 'Spraying…' : 'Hold to Spray',
                style: _body(
                  size: 16,
                  color: _isHoldingSpraying ? _C.forestDeep : _C.cyan,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ]),
            if (!_isHoldingSpraying) ...[
              const SizedBox(height: 4),
              Text(
                'Press and hold while walking over the field',
                style: _body(size: 10, color: _C.textMuted),
              ),
            ],
          ]),
        ),
      ),
      const SizedBox(height: 10),
      // Stop session button
      _btn('Stop Spraying', Icons.stop_circle_outlined,
          _C.orange, () { _stopSprayHold(); _ctrl.stopSpraying(); }),
    ]);
  }

  void _startSprayHold() {
    if (_isHoldingSpraying) return;
    setState(() => _isHoldingSpraying = true);
    _sprayTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _ctrl.demoSprayTick(),
    );
  }

  void _stopSprayHold() {
    _sprayTimer?.cancel();
    _sprayTimer = null;
    if (mounted) setState(() => _isHoldingSpraying = false);
  }

  void _openReport() {
    if (_ctrl.sessionResult == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SprayReportScreen(liveResult: _ctrl.sessionResult),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // OVERLAY WIDGETS
  // ══════════════════════════════════════════════════════
  Widget _sprayResultBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.glassBorder),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _resultStat('✅ Optimal', '${_ctrl.optimalCells}', _C.green),
        _resultStat('🟨 Under', '${_ctrl.underSprayedCells}', _C.yellow),
        _resultStat('🔴 Over', '${_ctrl.overSprayedCells}', _C.orange),
        _resultStat('⬜ None', '${_ctrl.untreatedCells}', _C.textMuted),
      ]),
    );
  }

  Widget _resultStat(String lbl, String val, Color c) => Column(children: [
    Text(val, style: _mono(size: 15, color: c)),
    Text(lbl, style: _body(size: 9, color: _C.textMuted)),
  ]);

  Widget _closeSnapIndicator() {
    return Positioned(
      top: 100, left: 0, right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: _C.green.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _C.green.withValues(alpha: 0.50)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_outline, color: _C.green, size: 16),
            const SizedBox(width: 8),
            Text('Close enough — tap ✓ to close!',
                style: _body(size: 13, color: _C.green)),
          ]),
        ),
      ),
    );
  }

  Widget _sprayLegend() {
    return Positioned(
      top: 100, right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.60),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _legendRow(_C.green, 'Optimal'),
            const SizedBox(height: 5),
            _legendRow(_C.yellow, 'Under'),
            const SizedBox(height: 5),
            _legendRow(_C.red, 'Over'),
            const SizedBox(height: 5),
            _legendRow(Colors.white38, 'Untreated'),
          ],
        ),
      ),
    );
  }

  Widget _legendRow(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12, height: 12,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: _body(size: 11, color: _C.textMuted)),
    ],
  );

  Widget _errorBanner() {
    return Positioned(
      top: 100, left: 16, right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _C.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.red.withValues(alpha: 0.40)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline, color: _C.red, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(_ctrl.errorMessage!,
              style: _body(size: 12, color: _C.red))),
          GestureDetector(
            onTap: _ctrl.resetAll,
            child: const Icon(Icons.close, color: _C.red, size: 16),
          ),
        ]),
      ),
    );
  }

  Widget _btn(String label, IconData icon, Color color, VoidCallback? onTap) {
    final active = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(colors: [color, color.withValues(alpha: 0.7)])
              : null,
          color: active ? null : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? color : _C.glassBorder),
          boxShadow: active
              ? [BoxShadow(color: color.withValues(alpha: 0.30), blurRadius: 16)]
              : [],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18,
              color: active ? _C.forestDeep : _C.textMuted),
          const SizedBox(width: 8),
          Text(label,
              style: _body(size: 13,
                      color: active ? _C.forestDeep : _C.textMuted)
                  .copyWith(fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}
