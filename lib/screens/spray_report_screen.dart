import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../mapping/models/spray_session_result.dart';

// ── Design tokens ─────────────────────────────────────────
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

TextStyle _heading({double size = 22, Color color = Colors.white}) =>
    GoogleFonts.spaceGrotesk(fontSize: size, fontWeight: FontWeight.w700, color: color, height: 1.1);

TextStyle _body({double size = 14, Color color = _C.textBody}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: FontWeight.w500, color: color);

TextStyle _mono({double size = 28, Color color = _C.yellow}) =>
    GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: FontWeight.w600, color: color);

// ── Data model ────────────────────────────────────────────
class SpraySession {
  final String date;
  final String field;
  final String crop;
  final double areaCovered;       // acres
  final double pesticideUsed;     // litres
  final double duration;          // minutes
  final String weatherCondition;
  final double windSpeed;         // km/h
  final double humidity;          // %
  final double temp;              // °C
  final double coverageQuality;   // % of field actually covered
  final double recommendedDose;   // L/acre recommended
  final double traditionSavingL;  // litres saved vs manual
  final double traditionSavingRs; // rupees saved vs manual
  final int    nextSprayDays;     // days until next spray
  final Color  accent;

  const SpraySession({
    required this.date, required this.field, required this.crop,
    required this.areaCovered, required this.pesticideUsed, required this.duration,
    required this.weatherCondition, required this.windSpeed, required this.humidity,
    required this.temp, required this.coverageQuality, required this.recommendedDose,
    required this.traditionSavingL, required this.traditionSavingRs,
    required this.nextSprayDays, required this.accent,
  });

  // Derived metrics
  double get efficiency => (coverageQuality * 0.6 + _windScore * 0.4).clamp(0, 100);
  double get _windScore => windSpeed < 5 ? 100 : windSpeed < 10 ? 80 : windSpeed < 15 ? 50 : 20;
  double get driftRisk  => windSpeed < 5 ? 8 : windSpeed < 10 ? 30 : windSpeed < 15 ? 65 : 90;
  double get lPerAcre   => pesticideUsed / areaCovered;
  int    get score {
    double s = 0;
    s += (coverageQuality / 100) * 35;
    s += (_windScore / 100) * 25;
    s += (lPerAcre <= recommendedDose ? 1.0 : (recommendedDose / lPerAcre).clamp(0.4, 1.0)) * 25;
    s += ((duration / (areaCovered * 30)).clamp(0.5, 1.0)) * 15;
    return s.round();
  }
  String get grade => score >= 90 ? 'A+' : score >= 80 ? 'A' : score >= 70 ? 'B' : score >= 60 ? 'C' : 'D';
  Color  get gradeColor => score >= 80 ? _C.green : score >= 60 ? _C.yellow : _C.red;
}

// ── Hardcoded sessions ────────────────────────────────────
const List<SpraySession> kSessions = [
  SpraySession(
    date: "Jul 2, 2026 · 7:14 AM", field: "North Plot A", crop: "Grapes",
    areaCovered: 1.4, pesticideUsed: 12.6, duration: 38,
    weatherCondition: "Partly Cloudy", windSpeed: 6.2, humidity: 68, temp: 24.0,
    coverageQuality: 94, recommendedDose: 9.0,
    traditionSavingL: 4.2, traditionSavingRs: 2100, nextSprayDays: 14,
    accent: Color(0xFF4ADE80),
  ),
  SpraySession(
    date: "Jun 29, 2026 · 6:50 AM", field: "South Plot B", crop: "Wheat",
    areaCovered: 2.1, pesticideUsed: 18.9, duration: 54,
    weatherCondition: "Clear Sky", windSpeed: 4.8, humidity: 55, temp: 22.5,
    coverageQuality: 97, recommendedDose: 9.0,
    traditionSavingL: 6.3, traditionSavingRs: 3150, nextSprayDays: 10,
    accent: Color(0xFF2DD4FF),
  ),
  SpraySession(
    date: "Jun 25, 2026 · 8:05 AM", field: "East Plot C", crop: "Cotton",
    areaCovered: 0.8, pesticideUsed: 8.4, duration: 22,
    weatherCondition: "Windy", windSpeed: 14.1, humidity: 72, temp: 27.3,
    coverageQuality: 71, recommendedDose: 9.0,
    traditionSavingL: 1.8, traditionSavingRs: 900, nextSprayDays: 7,
    accent: Color(0xFFFFD23F),
  ),
];

// ══════════════════════════════════════════════════════════
// LIST SCREEN
// ══════════════════════════════════════════════════════════
class SprayReportScreen extends StatelessWidget {
  /// When non-null, a live result from a just-completed spray session
  /// is prepended to the top of the list.
  /// When null, only the hardcoded mock sessions are shown (backward-compatible).
  final SpraySessionResult? liveResult;

  const SprayReportScreen({super.key, this.liveResult});

  @override
  Widget build(BuildContext context) {
    // Convert liveResult to a SpraySession for display if present
    final liveSessions = liveResult != null
        ? [_sessionFromResult(liveResult!)]
        : <SpraySession>[];
    final allSessions = [...liveSessions, ...kSessions];

    final totalArea  = allSessions.fold(0.0, (s, e) => s + e.areaCovered);
    final totalPest  = allSessions.fold(0.0, (s, e) => s + e.pesticideUsed);
    final avgScore   = allSessions.isEmpty ? 0.0
        : allSessions.fold(0.0, (s, e) => s + e.score) / allSessions.length;

    return Scaffold(
      backgroundColor: _C.forestDeep,
      body: Stack(children: [
        _bg(),
        _blob(top: -80,   right: -80,  size: 300, color: _C.green,  opacity: 0.20),
        _blob(bottom: 40, left:  -100, size: 280, color: _C.orange, opacity: 0.18),
        SafeArea(child: Column(children: [
          _topBar(context),
          Expanded(child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            itemCount: allSessions.length + 1,
            itemBuilder: (ctx, i) {
              if (i == 0) return _overviewStrip(totalArea, totalPest, avgScore);
              final s = allSessions[i - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _SessionTile(session: s),
              );
            },
          )),
        ])),
      ]),
    );
  }

  /// Convert a live SpraySessionResult into the existing SpraySession display model.
  static SpraySession _sessionFromResult(SpraySessionResult r) {
    final now = r.startTime;
    final dateStr =
        '${_monthName(now.month)} ${now.day}, ${now.year} · ${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')} ${now.hour < 12 ? 'AM' : 'PM'}';
    return SpraySession(
      date: dateStr,
      field: r.field.fieldName,
      crop: r.pesticideName,
      areaCovered: r.coveredHectares * 2.471,       // hectares → acres
      pesticideUsed: r.totalActualMl / 1000,        // mL → litres
      duration: r.durationMin,
      weatherCondition: 'Live Session',
      windSpeed: 0.0,
      humidity: 0.0,
      temp: 0.0,
      coverageQuality: r.coveragePct,
      recommendedDose: r.dosageMlPerHectare / 1000, // mL/ha → L/ha (approx)
      traditionSavingL: r.savedMl / 1000,
      traditionSavingRs: (r.savedMl / 1000) * 500, // ₹500/litre assumption
      nextSprayDays: 14,
      accent: const Color(0xFF4ADE80),
    );
  }

  static String _monthName(int m) => const [
    '', 'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ][m];

  Widget _topBar(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 46, height: 46,
          decoration: BoxDecoration(color: _C.glass, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.glassBorder)),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
      ),
      const SizedBox(width: 16),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Spray Report", style: _heading(size: 24)),
        Text("Tap a session for full details", style: _body(size: 12, color: _C.textMuted)),
      ]),
    ]),
  );

  Widget _overviewStrip(double area, double pest, double avgScore) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0x26FFFFFF), Color(0x14FFFFFF)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.glassBorder),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _oStat("${kSessions.length}", "Sessions", _C.cyan),
          _vDiv(), _oStat("${area.toStringAsFixed(1)} ac", "Area", _C.green),
          _vDiv(), _oStat("${pest.toStringAsFixed(1)} L",  "Pesticide", _C.orange),
          _vDiv(), _oStat("${avgScore.toStringAsFixed(0)}/100", "Avg Score", _C.yellow),
        ]),
      ),
    );
  }

  Widget _oStat(String val, String lbl, Color c) => Column(children: [
    Text(val, style: _mono(size: 14, color: c)),
    const SizedBox(height: 2),
    Text(lbl, style: _body(size: 10, color: _C.textMuted)),
  ]);

  Widget _vDiv() => Container(width: 1, height: 28, color: _C.glassBorder);
}

// ── Tappable session tile ─────────────────────────────────
class _SessionTile extends StatefulWidget {
  final SpraySession session;
  const _SessionTile({required this.session});
  @override State<_SessionTile> createState() => _SessionTileState();
}

class _SessionTileState extends State<_SessionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        Navigator.push(context, MaterialPageRoute(builder: (_) => SessionDetailScreen(session: s)));
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Colors.white.withValues(alpha: 0.14), s.accent.withValues(alpha: 0.06)]),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: s.accent.withValues(alpha: 0.28)),
                boxShadow: [BoxShadow(color: s.accent.withValues(alpha: 0.10), blurRadius: 18)],
              ),
              child: Row(children: [
                // Score ring
                SizedBox(width: 56, height: 56,
                  child: CustomPaint(painter: _ScoreRingPainter(s.score / 100, s.gradeColor),
                    child: Center(child: Text(s.grade,
                      style: _mono(size: 16, color: s.gradeColor))))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.field, style: _body(size: 15, color: Colors.white).copyWith(fontWeight: FontWeight.w700)),
                  Text("${s.crop}  ·  ${s.date}", style: _body(size: 11, color: _C.textMuted)),
                  const SizedBox(height: 8),
                  Row(children: [
                    _chip(Icons.map_outlined,       "${s.areaCovered} ac",          _C.cyan),
                    const SizedBox(width: 6),
                    _chip(Icons.science_outlined,   "${s.pesticideUsed} L",         _C.orange),
                    const SizedBox(width: 6),
                    _chip(Icons.air,                "${s.windSpeed} km/h",          s.driftRisk > 50 ? _C.red : _C.green),
                  ]),
                ])),
                Icon(Icons.chevron_right_rounded, color: s.accent, size: 22),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String lbl, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8), border: Border.all(color: c.withValues(alpha: 0.25))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 10, color: c), const SizedBox(width: 4),
      Text(lbl, style: _body(size: 9, color: c)),
    ]),
  );
}

// ══════════════════════════════════════════════════════════
// DETAIL SCREEN — full visual report, opened on tile tap
// ══════════════════════════════════════════════════════════
class SessionDetailScreen extends StatefulWidget {
  final SpraySession session;
  const SessionDetailScreen({super.key, required this.session});
  @override State<SessionDetailScreen> createState() => _SessionDetailState();
}

class _SessionDetailState extends State<SessionDetailScreen> with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final Animation<double>    _enterCurve;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _enterCurve = CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);
    _enter.forward();
  }

  @override
  void dispose() { _enter.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    return Scaffold(
      backgroundColor: _C.forestDeep,
      body: Stack(children: [
        _bg(),
        _blob(top: -60,   right: -60,  size: 280, color: s.accent,   opacity: 0.18),
        _blob(bottom: 60, left:  -80,  size: 260, color: _C.orange,  opacity: 0.14),
        SafeArea(child: Column(children: [
          _topBar(context, s),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: AnimatedBuilder(
              animation: _enterCurve,
              builder: (_, __) => Opacity(
                opacity: _enterCurve.value,
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - _enterCurve.value)),
                  child: Column(children: [
                    _scoreHero(s),
                    const SizedBox(height: 20),
                    _weatherCard(s),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: _driftCard(s)),
                      const SizedBox(width: 14),
                      Expanded(child: _coverageCard(s)),
                    ]),
                    const SizedBox(height: 16),
                    _chemUtilCard(s),
                    const SizedBox(height: 16),
                    _savingsCard(s),
                    const SizedBox(height: 16),
                    _nextSprayCard(s),
                  ]),
                ),
              ),
            ),
          )),
        ])),
      ]),
    );
  }

  Widget _topBar(BuildContext context, SpraySession s) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(width: 46, height: 46,
          decoration: BoxDecoration(color: _C.glass, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.glassBorder)),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20)),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(s.field, style: _heading(size: 20)),
        Text("${s.crop}  ·  ${s.date}", style: _body(size: 11, color: _C.textMuted)),
      ])),
    ]),
  );

  // ── 1. Score Hero ─────────────────────────────────────────
  Widget _scoreHero(SpraySession s) {
    return _glassCard(accent: s.accent, child: Row(children: [
      // Large score dial
      SizedBox(width: 110, height: 110,
        child: CustomPaint(
          painter: _ScoreRingPainter(s.score / 100, s.gradeColor, strokeWidth: 9),
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(s.grade, style: _mono(size: 26, color: s.gradeColor)),
            Text("${s.score}/100", style: _body(size: 10, color: _C.textMuted)),
          ])),
        ),
      ),
      const SizedBox(width: 20),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Session Score", style: _body(size: 12, color: _C.textMuted).copyWith(letterSpacing: 1.1)),
        const SizedBox(height: 4),
        Text(_scoreLabel(s.score), style: _heading(size: 18, color: s.gradeColor)),
        const SizedBox(height: 10),
        // Mini stats row
        Wrap(spacing: 8, runSpacing: 6, children: [
          _pill("${s.areaCovered} ac",        _C.cyan),
          _pill("${s.pesticideUsed} L",        _C.orange),
          _pill("${s.duration.toInt()} min",   _C.yellow),
          _pill(s.crop,                         _C.green),
        ]),
      ])),
    ]));
  }

  String _scoreLabel(int score) =>
    score >= 90 ? "Excellent 🌟" : score >= 80 ? "Great spray!" :
    score >= 70 ? "Good session" : score >= 60 ? "Needs work" : "Poor — review";

  // ── 2. Weather Card ───────────────────────────────────────
  Widget _weatherCard(SpraySession s) {
    return _glassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel("Weather at Spray Time"),
      const SizedBox(height: 14),
      Row(children: [
        _weatherDial("Temp", "${s.temp.toStringAsFixed(1)}°C", s.temp / 50, _C.orange),
        const SizedBox(width: 12),
        _weatherDial("Humidity", "${s.humidity.toStringAsFixed(0)}%", s.humidity / 100, _C.cyan),
        const SizedBox(width: 12),
        _weatherDial("Wind", "${s.windSpeed} km/h", (s.windSpeed / 30).clamp(0, 1), s.driftRisk > 50 ? _C.red : _C.green),
      ]),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(Icons.wb_cloudy_outlined, size: 16, color: _C.textMuted),
          const SizedBox(width: 8),
          Text(s.weatherCondition, style: _body(size: 13, color: Colors.white)),
        ]),
      ),
    ]));
  }

  Widget _weatherDial(String label, String value, double fill, Color color) {
    return Expanded(child: Column(children: [
      SizedBox(width: 60, height: 60,
        child: CustomPaint(
          painter: _ArcGaugePainter(fill, color, startAngle: math.pi * 0.75, sweep: math.pi * 1.5),
          child: Center(child: Text(value, style: _body(size: 9, color: Colors.white).copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center)),
        ),
      ),
      const SizedBox(height: 4),
      Text(label, style: _body(size: 10, color: _C.textMuted)),
    ]));
  }

  // ── 3. Drift Risk Card ────────────────────────────────────
  Widget _driftCard(SpraySession s) {
    final risk = s.driftRisk;
    final color = risk < 30 ? _C.green : risk < 60 ? _C.yellow : _C.red;
    final label = risk < 30 ? "Low Risk" : risk < 60 ? "Moderate" : "High Risk";
    return _glassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel("Drift Risk"),
      const SizedBox(height: 12),
      Center(child: SizedBox(width: 80, height: 80,
        child: CustomPaint(
          painter: _ArcGaugePainter(risk / 100, color, startAngle: math.pi * 0.75, sweep: math.pi * 1.5),
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text("${risk.toStringAsFixed(0)}%", style: _mono(size: 16, color: color)),
            Text(label, style: _body(size: 8, color: color), textAlign: TextAlign.center),
          ])),
        ),
      )),
      const SizedBox(height: 10),
      Text(
        risk < 30 ? "Wind was calm. Minimal chemical waste." :
        risk < 60 ? "Moderate wind. Some drift expected." :
        "High wind! Significant chemical loss.",
        style: _body(size: 10, color: _C.textMuted),
        textAlign: TextAlign.center,
      ),
    ]));
  }

  // ── 4. Coverage Quality Card ──────────────────────────────
  Widget _coverageCard(SpraySession s) {
    final color = s.coverageQuality >= 90 ? _C.green : s.coverageQuality >= 75 ? _C.yellow : _C.red;
    return _glassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel("Coverage"),
      const SizedBox(height: 12),
      Center(child: SizedBox(width: 80, height: 80,
        child: CustomPaint(
          painter: _CoverageHexPainter(s.coverageQuality / 100, color),
          child: Center(child: Text("${s.coverageQuality.toStringAsFixed(0)}%",
            style: _mono(size: 16, color: color))),
        ),
      )),
      const SizedBox(height: 10),
      Text(
        s.coverageQuality >= 90 ? "Excellent field coverage." :
        s.coverageQuality >= 75 ? "Good, minor gaps noted." :
        "Low coverage — check path.",
        style: _body(size: 10, color: _C.textMuted),
        textAlign: TextAlign.center,
      ),
    ]));
  }

  // ── 5. Chemical Utilisation Card ─────────────────────────
  Widget _chemUtilCard(SpraySession s) {
    final actual    = s.lPerAcre;
    final recommend = s.recommendedDose;
    final over = actual > recommend;
    final ratio = (actual / recommend).clamp(0.0, 2.0);
    final barColor = over ? _C.red : _C.green;

    return _glassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel("Chemical Utilisation"),
      const SizedBox(height: 14),
      // Side-by-side bar
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Recommended", style: _body(size: 10, color: _C.textMuted)),
          const SizedBox(height: 4),
          _horizBar(1.0, recommend / (recommend * 1.5), _C.cyan, "${recommend.toStringAsFixed(1)} L/ac"),
        ])),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("You used", style: _body(size: 10, color: _C.textMuted)),
          const SizedBox(height: 4),
          _horizBar(ratio.clamp(0.0, 1.0), (actual / (recommend * 1.5)).clamp(0.0, 1.0),
              barColor, "${actual.toStringAsFixed(1)} L/ac"),
        ])),
      ]),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: barColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: barColor.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Icon(over ? Icons.warning_amber_rounded : Icons.check_circle_outline,
              size: 16, color: barColor),
          const SizedBox(width: 8),
          Expanded(child: Text(
            over
              ? "Used ${(actual - recommend).toStringAsFixed(1)} L/ac more than needed. Reduce dose next time."
              : "Within recommended range. Great chemical discipline!",
            style: _body(size: 11, color: barColor),
          )),
        ]),
      ),
    ]));
  }

  Widget _horizBar(double logicalFill, double visualFill, Color color, String label) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: visualFill.clamp(0.0, 1.0),
          minHeight: 12,
          backgroundColor: Colors.white.withValues(alpha: 0.07),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
      const SizedBox(height: 4),
      Text(label, style: _mono(size: 12, color: color)),
    ]);
  }

  // ── 6. Savings Card ───────────────────────────────────────
  Widget _savingsCard(SpraySession s) {
    return _glassCard(accent: _C.green, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel("Savings vs Traditional Spraying"),
      const SizedBox(height: 16),
      Row(children: [
        _savingsBubble("Pesticide\nSaved", "${s.traditionSavingL.toStringAsFixed(1)} L", _C.green, Icons.science_outlined),
        const SizedBox(width: 14),
        _savingsBubble("Money\nSaved", "₹${s.traditionSavingRs.toStringAsFixed(0)}", _C.yellow, Icons.currency_rupee),
        const SizedBox(width: 14),
        _savingsBubble("Drift\nAvoided", "${(s.traditionSavingL * 0.4).toStringAsFixed(1)} L", _C.cyan, Icons.shield_outlined),
      ]),
      const SizedBox(height: 14),
      // Comparison bars
      _compareBar("Traditional", 1.0,        _C.red.withValues(alpha: 0.7), "${(s.pesticideUsed + s.traditionSavingL).toStringAsFixed(1)} L"),
      const SizedBox(height: 8),
      _compareBar("PreciSpray",  s.pesticideUsed / (s.pesticideUsed + s.traditionSavingL), _C.green, "${s.pesticideUsed} L"),
    ]));
  }

  Widget _savingsBubble(String label, String value, Color color, IconData icon) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(value, style: _mono(size: 14, color: color), textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text(label, style: _body(size: 9, color: _C.textMuted), textAlign: TextAlign.center),
      ]),
    ));
  }

  Widget _compareBar(String label, double fill, Color color, String valueLabel) {
    return Row(children: [
      SizedBox(width: 90, child: Text(label, style: _body(size: 11, color: _C.textMuted))),
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: fill.clamp(0.0, 1.0),
          minHeight: 14,
          backgroundColor: Colors.white.withValues(alpha: 0.07),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      )),
      const SizedBox(width: 8),
      Text(valueLabel, style: _body(size: 10, color: color)),
    ]);
  }

  // ── 7. Next Spray Recommendation ─────────────────────────
  Widget _nextSprayCard(SpraySession s) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [s.accent.withValues(alpha: 0.18), s.accent.withValues(alpha: 0.06)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: s.accent.withValues(alpha: 0.4)),
        boxShadow: [BoxShadow(color: s.accent.withValues(alpha: 0.15), blurRadius: 20)],
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: s.accent.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: s.accent.withValues(alpha: 0.4)),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.calendar_today_outlined, color: s.accent, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Next Spray", style: _body(size: 12, color: _C.textMuted).copyWith(letterSpacing: 1)),
          const SizedBox(height: 2),
          Text("Recommended in ${s.nextSprayDays} days", style: _heading(size: 17, color: s.accent)),
          Text("Based on crop cycle & last session", style: _body(size: 11, color: _C.textMuted)),
        ])),
      ]),
    );
  }

  // ── Shared helpers ────────────────────────────────────────
  Widget _sectionLabel(String label) => Text(label,
    style: _body(size: 11, color: _C.textMuted).copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700));

  Widget _glassCard({required Widget child, Color? accent}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0x26FFFFFF), Color(0x14FFFFFF)]),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: accent?.withValues(alpha: 0.25) ?? _C.glassBorder),
    ),
    child: child,
  );

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.25))),
    child: Text(label, style: _body(size: 10, color: color)),
  );
}

// ══════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ══════════════════════════════════════════════════════════

// Circular score ring (used on list tile + hero)
class _ScoreRingPainter extends CustomPainter {
  final double fill;   // 0.0–1.0
  final Color  color;
  final double strokeWidth;
  const _ScoreRingPainter(this.fill, this.color, {this.strokeWidth = 5});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r  = (size.shortestSide - strokeWidth) / 2;
    final bg = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final fg = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(cx, cy), r, bg);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -math.pi / 2,
      2 * math.pi * fill,
      false, fg,
    );
  }

  @override bool shouldRepaint(covariant _ScoreRingPainter o) =>
      o.fill != fill || o.color != color;
}

// Generic arc gauge (temperature, humidity, wind, drift)
class _ArcGaugePainter extends CustomPainter {
  final double fill;
  final Color  color;
  final double startAngle;
  final double sweep;
  const _ArcGaugePainter(this.fill, this.color,
      {this.startAngle = -math.pi / 2, this.sweep = 2 * math.pi});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    const sw = 6.0;
    final r  = (size.shortestSide - sw) / 2;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      startAngle, sweep, false,
      Paint()..color = Colors.white.withValues(alpha: 0.07)
             ..strokeWidth = sw..style = PaintingStyle.stroke,
    );

    if (fill > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle, sweep * fill.clamp(0.0, 1.0), false,
        Paint()..color = color..strokeWidth = sw
               ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round
               ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  @override bool shouldRepaint(covariant _ArcGaugePainter o) =>
      o.fill != fill || o.color != color;
}

// Hexagonal fill for coverage quality
class _CoverageHexPainter extends CustomPainter {
  final double fill;   // 0.0–1.0
  final Color  color;
  const _CoverageHexPainter(this.fill, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r  = size.shortestSide / 2 - 4;

    Path _hexPath(double radius) {
      final path = Path();
      for (int i = 0; i < 6; i++) {
        final angle = (math.pi / 180) * (60 * i - 30);
        final x = cx + radius * math.cos(angle);
        final y = cy + radius * math.sin(angle);
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      path.close();
      return path;
    }

    // Background hex
    canvas.drawPath(_hexPath(r), Paint()..color = Colors.white.withValues(alpha: 0.06)..style = PaintingStyle.fill);
    canvas.drawPath(_hexPath(r), Paint()..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Filled hex (clip to fraction of radius)
    canvas.save();
    canvas.clipPath(_hexPath(r * fill.clamp(0.0, 1.0)));
    canvas.drawPath(_hexPath(r),
      Paint()..color = color.withValues(alpha: 0.35)..style = PaintingStyle.fill);
    canvas.restore();

    // Border
    canvas.drawPath(_hexPath(r), Paint()..color = color.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  @override bool shouldRepaint(covariant _CoverageHexPainter o) =>
      o.fill != fill || o.color != color;
}

// ── Shared background helpers ─────────────────────────────
Widget _bg() => Container(decoration: const BoxDecoration(
  gradient: RadialGradient(
    center: Alignment(-0.6, -1.0), radius: 1.4,
    colors: [Color(0xFF103D2C), Color(0xFF07261C), Color(0xFF051A13)],
    stops: [0.0, 0.45, 1.0],
  )));

Widget _blob({double? top, double? bottom, double? left, double? right,
    required double size, required Color color, required double opacity}) =>
  Positioned(top: top, bottom: bottom, left: left, right: right,
    child: IgnorePointer(child: Container(width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
        boxShadow: [BoxShadow(color: color.withValues(alpha: opacity), blurRadius: 80, spreadRadius: 40)]))));
