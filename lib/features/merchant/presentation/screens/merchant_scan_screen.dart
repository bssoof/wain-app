import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wain_app/core/routing/navigation_extensions.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/widgets/app_button.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_validation_result.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_invalidation.dart';
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
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => MerchantRedemptionSheet(
        result: result,
        onRedeem: (billAmount) async {
          final success = await repository.redeemToken(
            token,
            billAmount: billAmount,
          );
          if (context.mounted) {
            if (success) {
              ref.invalidateMerchantDashboardData();
            }
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
            if (success) {
              Navigator.of(context).pop();
            }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/merchant/dashboard'),
        ),
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

const double _kMaxBillAmount = 100000;

double _roundMoney(double value) => double.parse(value.toStringAsFixed(2));

double? _tryParsePositiveMoney(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final normalized = trimmed.replaceAll(',', '.');
  final parsed = double.tryParse(normalized);
  if (parsed == null || parsed <= 0 || parsed > _kMaxBillAmount) {
    return null;
  }
  return _roundMoney(parsed);
}

double _calculatePercentSavings({
  required double billAmount,
  required double discountPercent,
}) {
  final rawSavings = billAmount * discountPercent / 100;
  return _roundMoney(rawSavings.clamp(0, billAmount).toDouble());
}

String _formatMoney(double value) {
  final rounded = _roundMoney(value);
  return rounded % 1 == 0
      ? rounded.toStringAsFixed(0)
      : rounded.toStringAsFixed(2);
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

class MerchantRedemptionSheet extends StatefulWidget {
  final MerchantValidationResult result;
  final Future<void> Function(double? billAmount) onRedeem;
  final VoidCallback onCancel;

  const MerchantRedemptionSheet({
    super.key,
    required this.result,
    required this.onRedeem,
    required this.onCancel,
  });

  @override
  State<MerchantRedemptionSheet> createState() =>
      _MerchantRedemptionSheetState();
}

class _MerchantRedemptionSheetState extends State<MerchantRedemptionSheet> {
  bool _isLoading = false;
  late final TextEditingController _billAmountController;

  MerchantValidationOfferPreview? get _offer => widget.result.offer;
  bool get _isPercentOffer => _offer?.discountType == 'percent';
  double get _offerDiscountValue => _offer?.discountValue ?? 0;
  String get _offerCurrency => _offer?.currency ?? 'ILS';
  double? get _parsedBillAmount =>
      _tryParsePositiveMoney(_billAmountController.text);
  bool get _hasInvalidBillAmount =>
      _billAmountController.text.trim().isNotEmpty && _parsedBillAmount == null;
  double? get _estimatedSavings => _parsedBillAmount == null
      ? null
      : _calculatePercentSavings(
          billAmount: _parsedBillAmount!,
          discountPercent: _offerDiscountValue,
        );
  double? get _estimatedFinalAmount =>
      (_parsedBillAmount != null && _estimatedSavings != null)
      ? _roundMoney(_parsedBillAmount! - _estimatedSavings!)
      : null;

  @override
  void initState() {
    super.initState();
    _billAmountController = TextEditingController()
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
  }

  @override
  void dispose() {
    _billAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final result = widget.result;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mediaQuery = MediaQuery.of(context);
    final viewInsets = mediaQuery.viewInsets;

    final statusColor = result.valid
        ? AppTheme.successColor
        : AppTheme.errorColor;

    return SafeArea(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                    (result.offer?.titleAr.trim().isNotEmpty ?? false)
                        ? result.offer!.titleAr
                        : l10n.scanUnnamedOffer,
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    (result.venue?.nameAr.trim().isNotEmpty ?? false)
                        ? result.venue!.nameAr
                        : l10n.scanUnknownVenue,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium,
                  ),
                ] else
                  Text(
                    l10n.scanReasonPrefix(
                      result.reason ?? l10n.scanUnknownReason,
                    ),
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppTheme.errorColor,
                    ),
                  ),
                if (result.valid && result.canRedeem && _isPercentOffer) ...[
                  const SizedBox(height: AppSpacing.lg),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(90),
                      borderRadius: AppSpacing.radiusMd,
                      border: Border.all(
                        color: colorScheme.outlineVariant.withAlpha(120),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.scanBillAmountLabel,
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n.scanBillAmountHint(
                              _formatMoney(_offerDiscountValue),
                            ),
                            style: textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            controller: _billAmountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.done,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*[.,]?\d{0,2}$'),
                              ),
                            ],
                            onTapOutside: (_) =>
                                FocusScope.of(context).unfocus(),
                            decoration: InputDecoration(
                              labelText: l10n.scanBillAmountField(
                                _offerCurrency,
                              ),
                              hintText: l10n.scanBillAmountOptionalHint,
                              errorText: _hasInvalidBillAmount
                                  ? l10n.scanBillAmountInvalid
                                  : null,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            l10n.scanBillAmountHelper,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (_estimatedSavings != null &&
                              _estimatedFinalAmount != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppTheme.successColor.withAlpha(16),
                                borderRadius: AppSpacing.radiusMd,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _SummaryRow(
                                      label: l10n.scanBeforeDiscountLabel,
                                      value:
                                          '${_formatMoney(_parsedBillAmount!)} $_offerCurrency',
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    _SummaryRow(
                                      label: l10n.scanConfirmedSavingsLabel,
                                      value:
                                          '${_formatMoney(_estimatedSavings!)} $_offerCurrency',
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    _SummaryRow(
                                      label: l10n.scanAfterDiscountLabel,
                                      value:
                                          '${_formatMoney(_estimatedFinalAmount!)} $_offerCurrency',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),
                if (result.valid && result.canRedeem)
                  AppButton.primary(
                    label: l10n.scanRedeemBtn,
                    onPressed: _isLoading || _hasInvalidBillAmount
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            await widget.onRedeem(_parsedBillAmount);
                            if (mounted) {
                              setState(() => _isLoading = false);
                            }
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
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(value, style: textTheme.titleSmall),
      ],
    );
  }
}
