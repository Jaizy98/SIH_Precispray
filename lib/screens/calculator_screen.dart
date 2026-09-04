import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── B's design tokens ────────────────────────────────────
class _C {
  static const forestDeep = Color(0xFF06241A);
  static const orange     = Color(0xFFFF8C42);
  static const green      = Color(0xFF4ADE80);
  static const cyan       = Color(0xFF2DD4FF);
  static const yellow     = Color(0xFFFFD23F);
  static const glass      = Color(0x0FFFFFFF);
  static const glassBorder= Color(0x1FFFFFFF);
  static const textBody   = Color(0xFFCDEBD8);
  static const textMuted  = Color(0xFFA9D9C2);
}

TextStyle _heading({double size = 20, Color color = Colors.white}) =>
    GoogleFonts.spaceGrotesk(fontSize: size, fontWeight: FontWeight.w700, color: color);

TextStyle _body({double size = 14, Color color = _C.textBody}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: FontWeight.w500, color: color);

TextStyle _mono({double size = 28, Color color = _C.yellow}) =>
    GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: FontWeight.w600, color: color);
// ─────────────────────────────────────────────────────────

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _costCtrl          = TextEditingController();
  final _sprayRateCtrl     = TextEditingController();
  final _driftEventsCtrl   = TextEditingController();
  final _closureTimeCtrl   = TextEditingController();
  final _pesticideUsedCtrl = TextEditingController();

  double pesticideSaved  = 0;
  double moneySaved      = 0;
  double efficiency      = 0;
  double driftPrevented  = 0;
  double potentialWaste  = 0;
  double actualWaste     = 0;
  double withoutPesticide= 0;
  double withPesticide   = 0;
  double withoutCost     = 0;
  double withCost        = 0;
  double totalPesticide  = 0;
  String envImpact       = "";
  bool reportGenerated   = false;

  @override
  void dispose() {
    _costCtrl.dispose();
    _sprayRateCtrl.dispose();
    _driftEventsCtrl.dispose();
    _closureTimeCtrl.dispose();
    _pesticideUsedCtrl.dispose();
    super.dispose();
  }

  void _generate() {
    final sprayRate    = double.tryParse(_sprayRateCtrl.text)     ?? 0;
    final pesticideCost= double.tryParse(_costCtrl.text)          ?? 0;
    totalPesticide     = double.tryParse(_pesticideUsedCtrl.text) ?? 0;
    final closureTime  = double.tryParse(_closureTimeCtrl.text)   ?? 0;
    final driftEvents  = int.tryParse(_driftEventsCtrl.text)      ?? 0;

    pesticideSaved  = (sprayRate / 60) * closureTime * driftEvents;
    moneySaved      = pesticideSaved * pesticideCost;
    efficiency      = totalPesticide > 0
        ? (pesticideSaved / totalPesticide) * 100
        : 0;
    driftPrevented  = driftEvents.toDouble();
    potentialWaste  = pesticideSaved;
    actualWaste     = 0;
    withoutPesticide= totalPesticide;
    withPesticide   = (totalPesticide - pesticideSaved).clamp(0, double.infinity);
    withoutCost     = withoutPesticide * pesticideCost;
    withCost        = withPesticide    * pesticideCost;
    envImpact       = "Reduced chemical drift by ${pesticideSaved.toStringAsFixed(2)} L";
    reportGenerated = true;
    setState(() {});
  }

  // ── background matching DashboardScreen ──────────────────
  BoxDecoration get _bg => const BoxDecoration(
    gradient: RadialGradient(
      center: Alignment(-0.6, -1.0),
      radius: 1.4,
      colors: [Color(0xFF103D2C), Color(0xFF07261C), Color(0xFF051A13)],
      stops: [0.0, 0.45, 1.0],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.forestDeep,
      body: Stack(
        children: [
          Container(decoration: _bg),
          _blob(top: -80,   right: -80,  size: 300, color: _C.yellow, opacity: 0.20),
          _blob(bottom: 40, left:  -100, size: 280, color: _C.green,  opacity: 0.18),
          SafeArea(
            child: Column(
              children: [
                _topBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _inputSection(),
                        const SizedBox(height: 20),
                        _generateButton(),
                        if (reportGenerated) ...[
                          const SizedBox(height: 28),
                          _reportCard(),
                          const SizedBox(height: 20),
                          _visualizationCard(),
                          const SizedBox(height: 20),
                          _comparisonCard(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: _C.glass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.glassBorder),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
      ),
      const SizedBox(width: 16),
      Text("Chemical Calculator", style: _heading(size: 22)),
    ]),
  );

  Widget _inputSection() => _glassCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Input Parameters", style: _body(size: 13, color: _C.textMuted).copyWith(letterSpacing: 1.2)),
      const SizedBox(height: 16),
      _field(_costCtrl,          "Pesticide Cost (₹/L)"),
      _field(_pesticideUsedCtrl, "Total Pesticide Used (L)"),
      _field(_sprayRateCtrl,     "Spray Rate (L/min)"),
      _field(_driftEventsCtrl,   "Wind Drift Events"),
      _field(_closureTimeCtrl,   "Nozzle Closure Time (seconds)", isLast: true),
    ]),
  );

  Widget _field(TextEditingController ctrl, String label, {bool isLast = false}) =>
    Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Container(
        decoration: BoxDecoration(
          color: _C.glass,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.glassBorder),
        ),
        child: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: _body(size: 15, color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: _body(size: 13, color: _C.textMuted),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );

  Widget _generateButton() => GestureDetector(
    onTap: _generate,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_C.green, _C.cyan]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _C.green.withValues(alpha: 0.35), blurRadius: 20)],
      ),
      alignment: Alignment.center,
      child: Text(
        "Generate Report",
        style: _body(size: 16, color: _C.forestDeep).copyWith(fontWeight: FontWeight.w700),
      ),
    ),
  );

  Widget _reportCard() => _glassCard(
    accent: _C.green,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Impact Report", style: _body(size: 13, color: _C.textMuted).copyWith(letterSpacing: 1.2)),
      const SizedBox(height: 16),
      Row(children: [
        _reportStat("Pesticide Saved", "${pesticideSaved.toStringAsFixed(2)} L", _C.green),
        const SizedBox(width: 12),
        _reportStat("Money Saved", "₹${moneySaved.toStringAsFixed(0)}", _C.yellow),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        _reportStat("Drift Prevented", "${driftPrevented.toStringAsFixed(0)} events", _C.cyan),
        const SizedBox(width: 12),
        _reportStat("Efficiency", "${efficiency.toStringAsFixed(1)}%", _C.orange),
      ]),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.green.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          const Icon(Icons.eco_outlined, color: _C.green, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(envImpact, style: _body(size: 13, color: _C.green))),
        ]),
      ),
    ]),
  );

  Widget _reportStat(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: _body(size: 11, color: _C.textMuted)),
        const SizedBox(height: 4),
        Text(value, style: _mono(size: 18, color: color)),
      ]),
    ),
  );

  Widget _visualizationCard() => _glassCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Visualization", style: _body(size: 13, color: _C.textMuted).copyWith(letterSpacing: 1.2)),
      const SizedBox(height: 16),
      _progressRow("Drift Loss Without PreciSpray",
          totalPesticide > 0 ? potentialWaste / totalPesticide : 0, _C.orange),
      const SizedBox(height: 16),
      _progressRow("Drift Loss With PreciSpray",
          totalPesticide > 0 ? actualWaste / totalPesticide : 0, _C.green),
      const SizedBox(height: 16),
      _progressRow("Savings Efficiency", efficiency / 100, _C.cyan),
    ]),
  );

  Widget _progressRow(String label, double value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: _body(size: 13, color: Colors.white)),
        Text("${(value * 100).toStringAsFixed(1)}%", style: _body(size: 13, color: color)),
      ]),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          minHeight: 10,
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    ],
  );

  Widget _comparisonCard() => _glassCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Waste Comparison", style: _body(size: 13, color: _C.textMuted).copyWith(letterSpacing: 1.2)),
      const SizedBox(height: 16),
      _comparisonBlock("WITHOUT PRECISPRAY", _C.orange, [
        "Pesticide Used: ${withoutPesticide.toStringAsFixed(2)} L",
        "Drift Loss: ${potentialWaste.toStringAsFixed(2)} L",
        "Cost: ₹${withoutCost.toStringAsFixed(0)}",
      ]),
      Divider(color: _C.glassBorder, height: 28),
      _comparisonBlock("WITH PRECISPRAY", _C.green, [
        "Pesticide Used: ${withPesticide.toStringAsFixed(2)} L",
        "Drift Loss: ${actualWaste.toStringAsFixed(2)} L",
        "Cost: ₹${withCost.toStringAsFixed(0)}",
      ]),
      Divider(color: _C.glassBorder, height: 28),
      _comparisonBlock("TOTAL SAVINGS", _C.cyan, [
        "Pesticide Saved: ${pesticideSaved.toStringAsFixed(2)} L",
        "Money Saved: ₹${moneySaved.toStringAsFixed(0)}",
      ]),
    ]),
  );

  Widget _comparisonBlock(String title, Color color, List<String> lines) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: _body(size: 12, color: color).copyWith(
        letterSpacing: 1.2, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      ...lines.map((l) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(l, style: _body(size: 14, color: Colors.white)),
      )),
    ],
  );

  Widget _glassCard({required Widget child, Color? accent}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x26FFFFFF), Color(0x14FFFFFF)],
      ),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: accent?.withValues(alpha: 0.3) ?? _C.glassBorder),
    ),
    child: child,
  );

  Widget _blob({double? top, double? bottom, double? left, double? right,
      required double size, required Color color, required double opacity}) =>
    Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: IgnorePointer(
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: opacity),
            boxShadow: [BoxShadow(color: color.withValues(alpha: opacity), blurRadius: 80, spreadRadius: 40)],
          ),
        ),
      ),
    );
}
