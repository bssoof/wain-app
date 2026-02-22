import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_repository.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_providers.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class MerchantScanScreen extends ConsumerStatefulWidget {
  const MerchantScanScreen({super.key});

  @override
  ConsumerState<MerchantScanScreen> createState() => _MerchantScanScreenState();
}

class _MerchantScanScreenState extends ConsumerState<MerchantScanScreen>
    with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _processToken(barcode.rawValue!);
        break; // Process first valid code
      }
    }
  }

  Future<void> _processToken(String token) async {
    setState(() {
      _isProcessing = true;
    });
    // Pause camera to prevent multiple scans
    await _controller.stop();

    if (!mounted) return;

    // 1. Validate
    final repo = ref.read(merchantRepositoryProvider);
    final result = await repo.validateToken(token);

    if (!mounted) return;

    // 2. Show Result Dialog
    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _RedemptionSheet(
        result: result,
        token: token,
        onRedeem: () async {
          // 3. Redeem
          final success = await repo.redeemToken(token);
          if (context.mounted) {
            Navigator.pop(context); // Close sheet
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.scanRedeemSuccess),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.scanRedeemError),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        onCancel: () {
          Navigator.pop(context);
        },
      ),
    );

    // Resume scanning
    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
      _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanTitle),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _handleBarcode),
          // Overlay
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: AppTheme.primaryColor,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          if (_isProcessing) const Center(child: WainLoadingIndicator()),
        ],
      ),
    );
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderRadius = 10,
    this.borderLength = 30,
    this.borderWidth = 10,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero)
      ..addRect(
        Rect.fromCenter(
          center: rect.center,
          width: cutOutSize,
          height: cutOutSize,
        ),
      );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    // Just a placeholder for simple overlay logic
    // In real usage, use 'qr_code_scanner' package's overlay or custom painter
    // This is a simplified version effectively making a hole
    return Path()..addRect(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );

    final backgroundPaint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final cutOutPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect)
      ..addRect(cutOutRect);

    canvas.drawPath(cutOutPath, backgroundPaint);

    // Draw corners
    // (Omitted for brevity, assuming standard overlay visual is enough for prototype)
    canvas.drawRect(cutOutRect, borderPaint);
  }

  @override
  ShapeBorder scale(double t) => this;
}

class _RedemptionSheet extends StatefulWidget {
  final ValidationResult result;
  final String token;
  final VoidCallback onRedeem;
  final VoidCallback onCancel;

  const _RedemptionSheet({
    required this.result,
    required this.token,
    required this.onRedeem,
    required this.onCancel,
  });

  @override
  State<_RedemptionSheet> createState() => _RedemptionSheetState();
}

class _RedemptionSheetState extends State<_RedemptionSheet> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final result = widget.result;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status Icon
          Center(
            child: Icon(
              result.valid ? Icons.check_circle : Icons.cancel,
              size: 64,
              color: result.valid ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            result.valid ? l10n.scanValidOffer : l10n.scanInvalidOffer,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Details
          if (result.valid) ...[
            Text(
              result.offer?['title_ar'] ?? l10n.scanUnnamedOffer,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              result.venue?['name_ar'] ?? l10n.scanUnknownVenue,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Text(
              l10n.scanReasonPrefix(result.reason ?? l10n.scanUnknownReason),
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 32),

          // Actions
          if (result.valid && result.canRedeem)
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() => _isLoading = true);
                      await Future.delayed(
                        const Duration(milliseconds: 500),
                      ); // UX delay
                      widget.onRedeem();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const WainLoadingIndicator()
                  : Text(l10n.scanRedeemBtn),
            )
          else if (result.valid && !result.canRedeem)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange.shade50),
              child: Text(
                l10n.scanMerchantRequired,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.orange),
              ),
            ),

          const SizedBox(height: 12),
          TextButton(
            onPressed: widget.onCancel,
            child: Text(l10n.scanCancelRescan),
          ),
        ],
      ),
    );
  }
}
