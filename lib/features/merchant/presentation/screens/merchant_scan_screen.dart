import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/widgets/app_button.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_repository.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_providers.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

class MerchantScanScreen extends ConsumerStatefulWidget {
  const MerchantScanScreen({super.key});

  @override
  ConsumerState<MerchantScanScreen> createState() => _MerchantScanScreenState();
}

class _MerchantScanScreenState extends ConsumerState<MerchantScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_isProcessing) {
      return;
    }

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        _processToken(rawValue);
        break;
      }
    }
  }

  Future<void> _processToken(String token) async {
    setState(() => _isProcessing = true);
    await _controller.stop();

    if (!mounted) {
      return;
    }

    final repository = ref.read(merchantRepositoryProvider);
    final result = await repository.validateToken(token);

    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => _RedemptionSheet(
        result: result,
        onRedeem: () async {
          final success = await repository.redeemToken(token);
          if (context.mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? AppLocalizations.of(context)!.scanRedeemSuccess
                      : AppLocalizations.of(context)!.scanRedeemError,
                ),
                backgroundColor: success
                    ? AppTheme.successColor
                    : AppTheme.errorColor,
              ),
            );
          }
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l10n.scanTitle),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _handleBarcode),
          CustomPaint(
            painter: _ScannerOverlayPainter(borderColor: AppTheme.primaryColor),
          ),
          PositionedDirectional(
            start: AppSpacing.xl,
            end: AppSpacing.xl,
            bottom: mediaQuery.padding.bottom + AppSpacing.xl,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(170),
                borderRadius: AppSpacing.radiusLg,
                border: Border.all(color: Colors.white.withAlpha(26)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.scanTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.scanCancelRescan,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withAlpha(210),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isProcessing)
            ColoredBox(
              color: Colors.black.withAlpha(150),
              child: const Center(child: WainLoadingIndicator()),
            ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;

  const _ScannerOverlayPainter({required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cutOutRect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: 280,
      height: 280,
    );

    final backgroundPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(
        RRect.fromRectAndRadius(cutOutRect, const Radius.circular(24)),
      );

    canvas.drawPath(
      backgroundPath,
      Paint()..color = Colors.black.withAlpha(170),
    );

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawRRect(
      RRect.fromRectAndRadius(cutOutRect, const Radius.circular(24)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor;
  }
}

class _RedemptionSheet extends StatefulWidget {
  final ValidationResult result;
  final Future<void> Function() onRedeem;
  final VoidCallback onCancel;

  const _RedemptionSheet({
    required this.result,
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final statusColor = result.valid
        ? AppTheme.successColor
        : AppTheme.errorColor;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(18),
                  borderRadius: AppSpacing.radiusLg,
                ),
                alignment: Alignment.center,
                child: Icon(
                  result.valid
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  size: 40,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              result.valid ? l10n.scanValidOffer : l10n.scanInvalidOffer,
              textAlign: TextAlign.center,
              style: textTheme.displayMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            if (result.valid) ...[
              Text(
                result.offer?['title_ar'] ?? l10n.scanUnnamedOffer,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                result.venue?['name_ar'] ?? l10n.scanUnknownVenue,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
            ] else
              Text(
                l10n.scanReasonPrefix(result.reason ?? l10n.scanUnknownReason),
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppTheme.errorColor,
                ),
              ),
            const SizedBox(height: AppSpacing.xxl),
            if (result.valid && result.canRedeem)
              AppButton.primary(
                label: l10n.scanRedeemBtn,
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() => _isLoading = true);
                        await widget.onRedeem();
                      },
                isLoading: _isLoading,
              )
            else if (result.valid && !result.canRedeem)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withAlpha(18),
                  borderRadius: AppSpacing.radiusMd,
                  border: Border.all(
                    color: AppTheme.warningColor.withAlpha(40),
                  ),
                ),
                child: Text(
                  l10n.scanMerchantRequired,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            AppButton.secondary(
              label: l10n.scanCancelRescan,
              onPressed: _isLoading ? null : widget.onCancel,
            ),
          ],
        ),
      ),
    );
  }
}
