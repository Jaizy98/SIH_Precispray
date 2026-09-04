import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart' show ProfileStore;

// ── Design tokens (mirrors AppColors) ────────────────────
class _C {
  static const forestDeep  = Color(0xFF06241A);
  static const green       = Color(0xFF4ADE80);
  static const cyan        = Color(0xFF2DD4FF);
  static const yellow      = Color(0xFFFFD23F);
  static const glass       = Color(0x0FFFFFFF);
  static const glassBorder = Color(0x1FFFFFFF);
  static const textBody    = Color(0xFFCDEBD8);
  static const textMuted   = Color(0xFFA9D9C2);
}

TextStyle _heading({double size = 22, Color color = Colors.white}) =>
    GoogleFonts.spaceGrotesk(fontSize: size, fontWeight: FontWeight.w700, color: color, height: 1.1);
TextStyle _body({double size = 14, Color color = _C.textBody}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: FontWeight.w500, color: color);

// ── Sell listing model ────────────────────────────────────
class CropListing {
  final String cropName;
  final String plotName;
  String quantity;   // kg / quintal — editable
  String pricePerKg; // ₹ — editable

  CropListing({
    required this.cropName,
    required this.plotName,
    this.quantity = '',
    this.pricePerKg = '',
  });
}

// ── Nearby farmer model (hardcoded seed data) ─────────────
class NearbyFarmer {
  final String name;
  final String location;
  final String crop;
  final String quantity;
  final String pricePerKg;
  final String plotArea;
  final Color accent;

  const NearbyFarmer({
    required this.name,
    required this.location,
    required this.crop,
    required this.quantity,
    required this.pricePerKg,
    required this.plotArea,
    required this.accent,
  });
}

const List<NearbyFarmer> kNearbyFarmers = [
  NearbyFarmer(name: 'Suresh Patil',   location: 'Nashik, 3.2 km',   crop: 'Grapes',  quantity: '400 kg',  pricePerKg: '₹55/kg',  plotArea: '2.1 ac', accent: Color(0xFF4ADE80)),
  NearbyFarmer(name: 'Meena Devi',     location: 'Pune, 5.8 km',     crop: 'Onion',   quantity: '1200 kg', pricePerKg: '₹18/kg',  plotArea: '3.4 ac', accent: Color(0xFFFFD23F)),
  NearbyFarmer(name: 'Raju Yadav',     location: 'Solapur, 7.1 km',  crop: 'Cotton',  quantity: '800 kg',  pricePerKg: '₹62/kg',  plotArea: '5.0 ac', accent: Color(0xFF2DD4FF)),
  NearbyFarmer(name: 'Kavita Shinde',  location: 'Ahmednagar, 9 km', crop: 'Wheat',   quantity: '2000 kg', pricePerKg: '₹22/kg',  plotArea: '4.5 ac', accent: Color(0xFFFF8C42)),
  NearbyFarmer(name: 'Balaji Reddy',   location: 'Latur, 11.4 km',   crop: 'Soybean', quantity: '600 kg',  pricePerKg: '₹40/kg',  plotArea: '1.8 ac', accent: Color(0xFF4ADE80)),
  NearbyFarmer(name: 'Priya Kumari',   location: 'Kolhapur, 14 km',  crop: 'Rice',    quantity: '3000 kg', pricePerKg: '₹28/kg',  plotArea: '6.2 ac', accent: Color(0xFFFFD23F)),
];

// ── NetworkingStore — singleton for sell listings ─────────
class NetworkingStore extends ChangeNotifier {
  static final NetworkingStore _instance = NetworkingStore._internal();
  factory NetworkingStore() => _instance;
  NetworkingStore._internal();

  List<CropListing> listings = [];

  /// Rebuilds listings from the current ProfileStore state.
  void syncFromProfile() {
    final profile = ProfileStore();
    if (!profile.hasProfile) { listings = []; notifyListeners(); return; }

    final crops = profile.crops
        .split(',')
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();

    // Preserve qty/price if the listing already exists
    final existing = { for (final l in listings) '${l.cropName}|${l.plotName}': l };

    listings = [];
    if (profile.plotNames.isEmpty) {
      for (final crop in crops) {
        final key = '$crop|';
        final prev = existing[key];
        listings.add(CropListing(
          cropName: crop, plotName: '',
          quantity: prev?.quantity ?? '',
          pricePerKg: prev?.pricePerKg ?? '',
        ));
      }
    } else {
      for (int i = 0; i < profile.plotNames.length; i++) {
        final plot = profile.plotNames[i];
        for (final crop in crops) {
          final key = '$crop|$plot';
          final prev = existing[key];
          listings.add(CropListing(
            cropName: crop, plotName: plot,
            quantity: prev?.quantity ?? '',
            pricePerKg: prev?.pricePerKg ?? '',
          ));
        }
      }
    }
    notifyListeners();
  }
}

// ══════════════════════════════════════════════════════════
// NETWORKING SCREEN
// ══════════════════════════════════════════════════════════
class NetworkingScreen extends StatefulWidget {
  const NetworkingScreen({super.key});

  @override
  State<NetworkingScreen> createState() => _NetworkingScreenState();
}

class _NetworkingScreenState extends State<NetworkingScreen> {
  bool _isSell = true; // true = Sell tab, false = Buy tab

  @override
  void initState() {
    super.initState();
    NetworkingStore().syncFromProfile();
  }

  BoxDecoration get _bg => const BoxDecoration(
    gradient: RadialGradient(
      center: Alignment(-0.6, -1.0), radius: 1.4,
      colors: [Color(0xFF103D2C), Color(0xFF07261C), Color(0xFF051A13)],
      stops: [0.0, 0.45, 1.0],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.forestDeep,
      body: Stack(children: [
        Container(decoration: _bg),
        _blob(top: -80,   right: -80,  size: 320, color: _C.green,  opacity: 0.18),
        _blob(bottom: 60, left: -100,  size: 280, color: _C.cyan,   opacity: 0.15),
        SafeArea(child: Column(children: [
          _topBar(context),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _profileCard(),
              const SizedBox(height: 20),
              _toggleRow(),
              const SizedBox(height: 20),
              _isSell ? const _SellView() : const _BuyView(),
            ]),
          )),
        ])),
      ]),
    );
  }

  // ── Top bar ──────────────────────────────────────────────
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
        Text('Networking', style: _heading(size: 24)),
        Text('Buy & sell crops directly', style: _body(size: 12, color: _C.textMuted)),
      ]),
    ]),
  );

  // ── Farmer profile summary card ──────────────────────────
  Widget _profileCard() {
    final p = ProfileStore();
    if (!p.hasProfile) {
      return Container(
        width: double.infinity, padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0x26FFFFFF), Color(0x14FFFFFF)]),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _C.glassBorder),
        ),
        child: Row(children: [
          const Icon(Icons.person_outline, color: _C.textMuted, size: 32),
          const SizedBox(width: 14),
          Expanded(child: Text('Complete your Profile to start trading.',
              style: _body(size: 13, color: _C.textMuted))),
        ]),
      );
    }

    final plots = List.generate(p.plotAreas.length, (i) {
      final n = i < p.plotNames.length && p.plotNames[i].trim().isNotEmpty
          ? p.plotNames[i].trim() : 'Plot ${i + 1}';
      final a = p.plotAreas[i].trim();
      return a.isNotEmpty ? '$n · $a ac' : n;
    }).join('   |   ');

    return Container(
      width: double.infinity, padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0x26FFFFFF), Color(0x14FFFFFF)]),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _C.green.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(color: _C.green.withValues(alpha: 0.08), blurRadius: 20)],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: _C.green.withValues(alpha: 0.15), shape: BoxShape.circle,
            border: Border.all(color: _C.green.withValues(alpha: 0.4)),
          ),
          alignment: Alignment.center,
          child: Text(
            p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
            style: _heading(size: 20, color: _C.green),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.name, style: _body(size: 15, color: Colors.white).copyWith(fontWeight: FontWeight.w700)),
          if (p.crops.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(p.crops, style: _body(size: 12, color: _C.green)),
          ],
          if (plots.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(plots, style: _body(size: 11, color: _C.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ])),
      ]),
    );
  }

  // ── Sell / Buy toggle ────────────────────────────────────
  Widget _toggleRow() => Container(
    height: 46,
    decoration: BoxDecoration(
      color: _C.glass, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _C.glassBorder),
    ),
    child: Row(children: [
      Expanded(child: _toggleBtn('Sell', Icons.sell_outlined, true)),
      Expanded(child: _toggleBtn('Buy',  Icons.shopping_bag_outlined, false)),
    ]),
  );

  Widget _toggleBtn(String label, IconData icon, bool isSell) {
    final active = _isSell == isSell;
    final color  = isSell ? _C.green : _C.cyan;
    return GestureDetector(
      onTap: () => setState(() => _isSell = isSell),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? color.withValues(alpha: 0.4) : Colors.transparent),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: active ? color : _C.textMuted),
          const SizedBox(width: 6),
          Text(label, style: _body(size: 13, color: active ? color : _C.textMuted)
              .copyWith(fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
        ]),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────
  Widget _blob({double? top, double? bottom, double? left, double? right,
      required double size, required Color color, required double opacity}) =>
      Positioned(top: top, bottom: bottom, left: left, right: right,
        child: IgnorePointer(child: Container(width: size, height: size,
          decoration: BoxDecoration(shape: BoxShape.circle,
            color: color.withValues(alpha: opacity),
            boxShadow: [BoxShadow(color: color.withValues(alpha: opacity), blurRadius: 80, spreadRadius: 40)],
          ),
        )),
      );
}

// ══════════════════════════════════════════════════════════
// SELL VIEW — editable crop listing cards from ProfileStore
// ══════════════════════════════════════════════════════════
class _SellView extends StatefulWidget {
  const _SellView();

  @override
  State<_SellView> createState() => _SellViewState();
}

class _SellViewState extends State<_SellView> {
  @override
  void initState() {
    super.initState();
    NetworkingStore().addListener(_onStoreChange);
  }

  @override
  void dispose() {
    NetworkingStore().removeListener(_onStoreChange);
    super.dispose();
  }

  void _onStoreChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final store    = NetworkingStore();
    final listings = store.listings;

    if (listings.isEmpty) {
      return _emptyState(
        icon: Icons.sell_outlined,
        message: 'No crops found.\nAdd crops in your Profile to list them for sale.',
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.sell_outlined, color: _C.green, size: 15),
        const SizedBox(width: 6),
        Text('YOUR LISTINGS', style: _body(size: 11, color: _C.green)
            .copyWith(letterSpacing: 1.5, fontWeight: FontWeight.w800)),
      ]),
      const SizedBox(height: 4),
      Text('Set the quantity and price for each crop you want to sell.',
          style: _body(size: 11, color: _C.textMuted)),
      const SizedBox(height: 16),
      ...listings.map((l) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: _SellCard(listing: l),
      )),
    ]);
  }
}

// ── Individual sell card ──────────────────────────────────
class _SellCard extends StatefulWidget {
  final CropListing listing;
  const _SellCard({required this.listing});

  @override
  State<_SellCard> createState() => _SellCardState();
}

class _SellCardState extends State<_SellCard> {
  late TextEditingController _qtyCtrl;
  late TextEditingController _priceCtrl;
  bool _listed = false;

  @override
  void initState() {
    super.initState();
    _qtyCtrl   = TextEditingController(text: widget.listing.quantity);
    _priceCtrl = TextEditingController(text: widget.listing.pricePerKg);
    _listed    = widget.listing.quantity.isNotEmpty && widget.listing.pricePerKg.isNotEmpty;
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.listing.quantity   = _qtyCtrl.text.trim();
    widget.listing.pricePerKg = _priceCtrl.text.trim();
    setState(() => _listed = widget.listing.quantity.isNotEmpty && widget.listing.pricePerKg.isNotEmpty);
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: _C.green.withValues(alpha: 0.9),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Text('${widget.listing.cropName} listing saved!',
          style: _body(size: 13, color: _C.forestDeep).copyWith(fontWeight: FontWeight.w700)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final borderColor = _listed ? _C.green.withValues(alpha: 0.35) : _C.glassBorder;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0x26FFFFFF), Color(0x14FFFFFF)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: _listed
            ? [BoxShadow(color: _C.green.withValues(alpha: 0.1), blurRadius: 16)]
            : [],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row: crop name + listed badge
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _C.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _C.green.withValues(alpha: 0.3)),
            ),
            child: Text(l.cropName, style: _body(size: 13, color: _C.green)
                .copyWith(fontWeight: FontWeight.w700)),
          ),
          if (l.plotName.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(l.plotName, style: _body(size: 11, color: _C.textMuted)),
          ],
          const Spacer(),
          if (_listed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _C.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('LISTED', style: _body(size: 9, color: _C.green)
                  .copyWith(fontWeight: FontWeight.w800, letterSpacing: 1)),
            ),
        ]),
        const SizedBox(height: 14),
        // Input fields row
        Row(children: [
          Expanded(child: _inputField(_qtyCtrl, 'Quantity (kg)', Icons.scale_outlined)),
          const SizedBox(width: 10),
          Expanded(child: _inputField(_priceCtrl, 'Price (₹/kg)', Icons.currency_rupee)),
        ]),
        const SizedBox(height: 12),
        // Save / List button
        GestureDetector(
          onTap: _save,
          child: Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_C.green.withValues(alpha: 0.8), _C.cyan.withValues(alpha: 0.8)]),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(_listed ? 'Update Listing' : 'List for Sale',
                style: _body(size: 13, color: _C.forestDeep).copyWith(fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _C.glassBorder),
    ),
    child: Row(children: [
      Icon(icon, size: 14, color: _C.textMuted),
      const SizedBox(width: 6),
      Expanded(child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: _body(size: 13, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: _body(size: 12, color: _C.textMuted),
          isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero,
        ),
      )),
    ]),
  );
}

// ══════════════════════════════════════════════════════════
// BUY VIEW — list of nearby farmers with their listings
// ══════════════════════════════════════════════════════════
class _BuyView extends StatelessWidget {
  const _BuyView();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.shopping_bag_outlined, color: _C.cyan, size: 15),
        const SizedBox(width: 6),
        Text('FARMERS NEAR YOU', style: _body(size: 11, color: _C.cyan)
            .copyWith(letterSpacing: 1.5, fontWeight: FontWeight.w800)),
      ]),
      const SizedBox(height: 4),
      Text('Browse crops available from farmers in your area.',
          style: _body(size: 11, color: _C.textMuted)),
      const SizedBox(height: 16),
      ...kNearbyFarmers.map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: _BuyCard(farmer: f),
      )),
    ]);
  }
}

// ── Individual buy card ───────────────────────────────────
class _BuyCard extends StatelessWidget {
  final NearbyFarmer farmer;
  const _BuyCard({required this.farmer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0x26FFFFFF), Color(0x14FFFFFF)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: farmer.accent.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(color: farmer.accent.withValues(alpha: 0.07), blurRadius: 16)],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Left: farmer avatar ──────────────────────────
        Column(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: farmer.accent.withValues(alpha: 0.15), shape: BoxShape.circle,
              border: Border.all(color: farmer.accent.withValues(alpha: 0.4)),
            ),
            alignment: Alignment.center,
            child: Text(farmer.name[0],
                style: _heading(size: 18, color: farmer.accent)),
          ),
          const SizedBox(height: 6),
          Text(farmer.plotArea,
              style: _body(size: 9, color: _C.textMuted)),
        ]),
        const SizedBox(width: 14),
        // ── Middle: farmer info + crop ───────────────────
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(farmer.name,
              style: _body(size: 14, color: Colors.white).copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 11, color: _C.textMuted),
            const SizedBox(width: 3),
            Text(farmer.location, style: _body(size: 11, color: _C.textMuted)),
          ]),
          const SizedBox(height: 10),
          // Crop pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: farmer.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: farmer.accent.withValues(alpha: 0.3)),
            ),
            child: Text(farmer.crop,
                style: _body(size: 12, color: farmer.accent).copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          // Qty + Price chips row
          Row(children: [
            _statChip(Icons.scale_outlined,   farmer.quantity,   _C.textBody),
            const SizedBox(width: 8),
            _statChip(Icons.currency_rupee,   farmer.pricePerKg, _C.yellow),
          ]),
        ])),
        const SizedBox(width: 12),
        // ── Right: contact button ────────────────────────
        GestureDetector(
          onTap: () => _showContactSheet(context, farmer),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: farmer.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: farmer.accent.withValues(alpha: 0.4)),
            ),
            child: Icon(Icons.chat_bubble_outline, size: 18, color: farmer.accent),
          ),
        ),
      ]),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 10, color: color), const SizedBox(width: 4),
      Text(label, style: _body(size: 10, color: color)),
    ]),
  );

  void _showContactSheet(BuildContext context, NearbyFarmer f) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF0B3D2E), Color(0xFF06241A)]),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: _C.glassBorder, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: f.accent.withValues(alpha: 0.15), shape: BoxShape.circle,
                  border: Border.all(color: f.accent.withValues(alpha: 0.4)),
                ),
                alignment: Alignment.center,
                child: Text(f.name[0], style: _heading(size: 20, color: f.accent)),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.name, style: _heading(size: 18)),
                Text(f.location, style: _body(size: 12, color: _C.textMuted)),
              ]),
            ]),
            const SizedBox(height: 20),
            Divider(color: _C.glassBorder),
            const SizedBox(height: 16),
            _infoRow(Icons.grass_outlined,    'Crop',     f.crop,        f.accent),
            _infoRow(Icons.scale_outlined,    'Available',f.quantity,    _C.textBody),
            _infoRow(Icons.currency_rupee,    'Price',    f.pricePerKg,  _C.yellow),
            _infoRow(Icons.crop_square,       'Plot area',f.plotArea,    _C.cyan),
            const SizedBox(height: 24),
            Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [f.accent.withValues(alpha: 0.8), _C.cyan.withValues(alpha: 0.8)]),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF06241A)),
                const SizedBox(width: 8),
                Text('Send Enquiry', style: _body(size: 14, color: _C.forestDeep)
                    .copyWith(fontWeight: FontWeight.w700)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Icon(icon, size: 16, color: color), const SizedBox(width: 10),
          Text('$label  ', style: _body(size: 12, color: _C.textMuted)),
          Text(value, style: _body(size: 13, color: Colors.white).copyWith(fontWeight: FontWeight.w600)),
        ]),
      );
}

// ── Shared empty state ────────────────────────────────────
Widget _emptyState({required IconData icon, required String message}) =>
    Container(
      width: double.infinity, padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0x26FFFFFF), Color(0x14FFFFFF)]),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _C.glassBorder),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: _C.textMuted, size: 36), const SizedBox(height: 12),
        Text(message, style: _body(size: 12, color: _C.textMuted), textAlign: TextAlign.center),
      ]),
    );
