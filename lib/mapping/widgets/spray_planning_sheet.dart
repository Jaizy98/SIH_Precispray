import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/field_model.dart';
import '../controllers/mapping_controller.dart';

// ── Design tokens — matches existing app color palette ────────────
class _C {
  static const green = Color(0xFF4ADE80);  static const cyan = Color(0xFF2DD4FF);
  static const yellow = Color(0xFFFFD23F);
  static const glass = Color(0x0FFFFFFF);
  static const glassBorder = Color(0x1FFFFFFF);
  static const textBody = Color(0xFFCDEBD8);
  static const textMuted = Color(0xFFA9D9C2);
}

TextStyle _heading({double size = 18, Color color = Colors.white}) =>
    GoogleFonts.spaceGrotesk(
        fontSize: size, fontWeight: FontWeight.w700, color: color);

TextStyle _body({double size = 14, Color color = _C.textBody}) =>
    GoogleFonts.manrope(
        fontSize: size, fontWeight: FontWeight.w500, color: color);

TextStyle _mono({double size = 20, Color color = _C.yellow}) =>
    GoogleFonts.jetBrainsMono(
        fontSize: size, fontWeight: FontWeight.w600, color: color);

/// Bottom sheet shown when farmer taps "Start Spraying".
/// Collects pesticide name and dosage (mL/hectare) before starting the session.
///
/// Shows a live calculation preview: "Total needed: X mL"
/// Validates input before calling controller.beginSpraying().
class SprayPlanningSheet extends StatefulWidget {
  final FieldModel field;
  final MappingController controller;

  const SprayPlanningSheet({
    super.key,
    required this.field,
    required this.controller,
  });

  @override
  State<SprayPlanningSheet> createState() => _SprayPlanningSheetState();
}

class _SprayPlanningSheetState extends State<SprayPlanningSheet> {
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final dosage = double.tryParse(_dosageCtrl.text.trim());

    if (name.isEmpty) {
      setState(() => _error = 'Please enter the pesticide name.');
      return;
    }
    if (dosage == null || dosage <= 0) {
      setState(() =>
          _error = 'Enter a valid dosage greater than 0 (mL per hectare).');
      return;
    }

    Navigator.of(context).pop(); // close the sheet
    widget.controller.beginSpraying(
      field: widget.field,
      pesticideName: name,
      dosageMlPerHectare: dosage,
    );
  }

  /// Live preview of total chemical needed — updates as user types.
  Widget _totalPreview() {
    final dosage = double.tryParse(_dosageCtrl.text.trim());
    if (dosage == null || dosage <= 0) return const SizedBox.shrink();
    final totalMl = dosage * widget.field.hectares;
    final totalL = totalMl / 1000;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _C.green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.green.withValues(alpha: 0.30)),
      ),
      child: Row(children: [
        const Icon(Icons.science_outlined, color: _C.green, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: _body(size: 13, color: _C.textBody),
              children: [
                const TextSpan(text: 'Total needed: '),
                TextSpan(
                  text: '${totalMl.toStringAsFixed(0)} mL',
                  style: _mono(size: 14, color: _C.green),
                ),
                TextSpan(text: '  (${totalL.toStringAsFixed(2)} L)'),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D3526),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: _C.glassBorder),
          left: BorderSide(color: _C.glassBorder),
          right: BorderSide(color: _C.glassBorder),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Drag handle ─────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: _C.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Field info header ────────────────────────────────────
          Text('Plan Spray', style: _heading(size: 20)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.crop_square_rounded,
                size: 13, color: _C.cyan),
            const SizedBox(width: 6),
            Text(
              '${field.fieldName}  ·  '
              '${field.hectares.toStringAsFixed(3)} ha  ·  '
              '${field.acres.toStringAsFixed(3)} ac',
              style: _body(size: 12, color: _C.textMuted),
            ),
          ]),

          const SizedBox(height: 20),

          // ── Pesticide name ───────────────────────────────────────
          _inputField(
            controller: _nameCtrl,
            hint: 'Pesticide name (e.g. Chlorpyrifos 20 EC)',
            icon: Icons.local_pharmacy_outlined,
            onChanged: (_) => setState(() => _error = null),
          ),

          const SizedBox(height: 12),

          // ── Dosage ───────────────────────────────────────────────
          _inputField(
            controller: _dosageCtrl,
            hint: 'Recommended dose (mL per hectare)',
            icon: Icons.opacity_outlined,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() => _error = null),
          ),

          // ── Live total preview ───────────────────────────────────
          ValueListenableBuilder(
            valueListenable: _dosageCtrl,
            builder: (_, __, ___) => _totalPreview(),
          ),

          // ── Error message ────────────────────────────────────────
          if (_error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4D4D).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFFF4D4D).withValues(alpha: 0.30)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline,
                    size: 15, color: Color(0xFFFF4D4D)),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_error!,
                        style:
                            _body(size: 12, color: const Color(0xFFFF4D4D)))),
              ]),
            ),
          ],

          const SizedBox(height: 20),

          // ── Confirm button ───────────────────────────────────────
          GestureDetector(
            onTap: _submit,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_C.green, _C.cyan]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: _C.green.withValues(alpha: 0.35),
                      blurRadius: 18)
                ],
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_florist_rounded,
                      size: 18, color: Color(0xFF06241A)),
                  const SizedBox(width: 8),
                  Text(
                    'Start Spraying',
                    style: _body(
                      size: 15,
                      color: const Color(0xFF06241A),
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _C.glass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.glassBorder),
      ),
      child: Row(children: [
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Icon(icon, size: 18, color: _C.textMuted),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: _body(size: 14, color: Colors.white),
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: _body(size: 13, color: _C.textMuted),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ),
      ]),
    );
  }
}
