import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/offers/domain/entities/offer.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class OfferQRCodeScreen extends StatefulWidget {
  final ClaimResult claimResult;
  final Offer offer;
  final String venueName;

  const OfferQRCodeScreen({
    super.key,
    required this.claimResult,
    required this.offer,
    required this.venueName,
  });

  @override
  State<OfferQRCodeScreen> createState() => _OfferQRCodeScreenState();
}

class _OfferQRCodeScreenState extends State<OfferQRCodeScreen> {
  late Timer _timer;
  late Duration _remainingTime;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateRemainingTime();
    });
  }

  void _calculateRemainingTime() {
    final remaining = widget.claimResult.expiresAt.difference(DateTime.now());
    if (remaining.isNegative) {
      setState(() => _remainingTime = Duration.zero);
      _timer.cancel();
      return;
    }

    setState(() => _remainingTime = remaining);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _timerText {
    final minutes = _remainingTime.inMinutes.toString().padLeft(2, '0');
    final seconds = (_remainingTime.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isExpired = _remainingTime == Duration.zero;
    final statusColor = isExpired ? AppTheme.errorColor : AppTheme.successColor;

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onPrimary,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(l10n.offerQrDiscountCode),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 420),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: AppSpacing.radiusLg,
                    boxShadow: AppShadows.overlay,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: AppTheme.primarySurfaceColor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          border: Border(
                            bottom: BorderSide(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              widget.venueName,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              widget.offer.getDiscountText(l10n),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.displayMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.xxl),
                        child: isExpired
                            ? Icon(
                                Icons.qr_code_2_rounded,
                                size: 176,
                                color: theme.colorScheme.outline,
                              )
                            : DecoratedBox(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: AppSpacing.radiusMd,
                                  border: Border.all(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: QrImageView(
                                    data: widget.claimResult.token,
                                    version: QrVersions.auto,
                                    size: 240,
                                    backgroundColor: theme.colorScheme.surface,
                                  ),
                                ),
                              ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.lg,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(14),
                          border: Border(
                            top: BorderSide(color: theme.colorScheme.outline),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              isExpired
                                  ? l10n.offerQrCodeExpired
                                  : l10n.offerQrValidFor,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _timerText,
                              style: theme.textTheme.displayMedium?.copyWith(
                                color: statusColor,
                                fontFamily: 'Courier',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          isExpired
                              ? l10n.offerQrPeriodExpired
                              : l10n.offerQrShowToCashier,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isExpired
                                ? AppTheme.errorColor
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  isExpired ? l10n.offerQrRedeemed : widget.offer.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
