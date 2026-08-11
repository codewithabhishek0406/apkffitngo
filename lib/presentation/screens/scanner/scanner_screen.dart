import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/result.dart';
import '../../../data/models/product_request_model.dart';
import '../../providers/providers.dart';

enum _ScanState { scanning, looking, notFound }

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final MobileScannerController _ctrl = MobileScannerController();
  _ScanState _state = _ScanState.scanning;
  String? _lastBarcode;
  String _statusMessage = 'Point camera at a barcode';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onBarcode(BarcodeCapture capture) async {
    if (_state != _ScanState.scanning) return;

    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || !barcode.isValidBarcode) return;
    if (barcode == _lastBarcode) return;

    _lastBarcode = barcode;
    setState(() {
      _state = _ScanState.looking;
      _statusMessage = 'Looking up "$barcode"…';
    });

    // 1. Check Supabase first
    final repo = ref.read(foodRepositoryProvider);
    final result = await repo.getProductByBarcode(barcode);

    if (result.isSuccess && result.dataOrNull != null) {
      final product = result.dataOrNull!;
      if (!mounted) return;
      await ref.read(localStorageServiceProvider).addRecentProduct(product);
      if (!mounted) return;
      context.push('/products/${product.slug}', extra: product);
      setState(() => _state = _ScanState.scanning);
      return;
    }

    // 2. Fall back to OpenFoodFacts
    setState(() => _statusMessage = 'Not in database — checking OpenFoodFacts…');
    final offService = ref.read(openFoodFactsServiceProvider);
    final offResult = await offService.fetchByBarcode(barcode);

    if (offResult.isSuccess) {
      final offData = offResult.dataOrNull!;
      if (!mounted) return;
      _showOFFBottomSheet(barcode, offData.name ?? barcode);
      return;
    }

    // 3. Nothing found
    if (!mounted) return;
    setState(() {
      _state = _ScanState.notFound;
      _statusMessage = 'Product not found';
    });
    _showRequestSheet(barcode);
  }

  void _showOFFBottomSheet(String barcode, String name) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _OFFFoundSheet(
        barcode: barcode,
        name: name,
        onRequest: () => _showRequestSheet(barcode),
        onDismiss: _resetScan,
      ),
    ).whenComplete(_resetScan);
  }

  void _showRequestSheet(String barcode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RequestProductSheet(barcode: barcode),
    ).whenComplete(_resetScan);
  }

  void _resetScan() {
    if (mounted) {
      setState(() {
        _state = _ScanState.scanning;
        _lastBarcode = null;
        _statusMessage = 'Point camera at a barcode';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(
          'Barcode Scanner',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            color: Colors.white,
            onPressed: () => _ctrl.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded),
            color: Colors.white,
            onPressed: () => _ctrl.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _ctrl, onDetect: _onBarcode),

          CustomPaint(
            painter: _ScannerOverlayPainter(),
            child: const SizedBox.expand(),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_state == _ScanState.looking) ...[
                    const CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    _statusMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _showManualEntry,
                    icon: const Icon(Icons.keyboard_rounded,
                        size: 16, color: Colors.white),
                    label: const Text(
                      'Enter barcode manually',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualEntry() async {
    final ctrl = TextEditingController();
    final barcode = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enter Barcode'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration:
              const InputDecoration(hintText: 'e.g. 8901058851456'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Search'),
          ),
        ],
      ),
    );
    if (barcode != null && barcode.isValidBarcode) {
      await _onBarcode(BarcodeCapture(
        barcodes: [Barcode(rawValue: barcode)],
      ));
    }
  }
}

// ── Scanner overlay ────────────────────────────────────────────────────────

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cutoutWidth = size.width * 0.75;
    final cutoutHeight = cutoutWidth * 0.6;
    final cutoutLeft = (size.width - cutoutWidth) / 2;
    final cutoutTop = (size.height - cutoutHeight) / 2;
    final cutoutRect =
        Rect.fromLTWH(cutoutLeft, cutoutTop, cutoutWidth, cutoutHeight);

    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
          cutoutRect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const cornerLen = 24.0;

    final corners = <List<Offset>>[
      [cutoutRect.topLeft,    Offset(cornerLen, 0),  Offset(0, cornerLen)],
      [cutoutRect.topRight,   Offset(-cornerLen, 0), Offset(0, cornerLen)],
      [cutoutRect.bottomLeft, Offset(cornerLen, 0),  Offset(0, -cornerLen)],
      [cutoutRect.bottomRight,Offset(-cornerLen, 0), Offset(0, -cornerLen)],
    ];

    for (final c in corners) {
      canvas.drawLine(c[0], c[0] + c[1], borderPaint);
      canvas.drawLine(c[0], c[0] + c[2], borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Bottom sheets ──────────────────────────────────────────────────────────

class _OFFFoundSheet extends StatelessWidget {
  const _OFFFoundSheet({
    required this.barcode,
    required this.name,
    required this.onRequest,
    required this.onDismiss,
  });
  final String barcode;
  final String name;
  final VoidCallback onRequest;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined,
                size: 48, color: AppColors.warning),
            const SizedBox(height: 16),
            Text('Product on OpenFoodFacts',
                style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Text(
              '"$name" exists in OpenFoodFacts but hasn\'t been '
              'reviewed and published in FitNGo yet.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onRequest();
                },
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Request this product'),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onDismiss();
              },
              child: const Text('Continue scanning'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestProductSheet extends ConsumerStatefulWidget {
  const _RequestProductSheet({required this.barcode});
  final String barcode;

  @override
  ConsumerState<_RequestProductSheet> createState() =>
      _RequestProductSheetState();
}

class _RequestProductSheetState
    extends ConsumerState<_RequestProductSheet> {
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _submitting = true);

    final request = ProductRequestModel(
      id: '',
      productName: _nameCtrl.text.trim(),
      brand: _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
      barcode: widget.barcode,
      message: _msgCtrl.text.trim().isEmpty ? null : _msgCtrl.text.trim(),
    );

    final repo = ref.read(foodRepositoryProvider);
    final result = await repo.submitProductRequest(request);

    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess
              ? 'Request submitted! We\'ll add it soon.'
              : 'Failed to submit. Please try again.',
        ),
        backgroundColor:
            result.isSuccess ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Request this product',
                style: AppTextStyles.headlineSmall),
            const SizedBox(height: 4),
            Text('Barcode: ${widget.barcode}',
                style: AppTextStyles.bodySmall),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration:
                  const InputDecoration(labelText: 'Product name *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _brandCtrl,
              decoration:
                  const InputDecoration(labelText: 'Brand (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _msgCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Additional notes (optional)'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
