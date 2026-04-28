import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/providers/offline_providers.dart';
import 'package:wain_app/core/routing/app_router.dart';
import 'package:wain_app/core/routing/navigation_extensions.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/widgets/app_empty_state.dart';
import 'package:wain_app/core/widgets/offline_widgets.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_offer.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_providers.dart';
import 'package:wain_app/features/merchant/presentation/widgets/merchant_offer_form_sheet.dart';

import '../providers/merchant_dashboard_providers.dart';

/// Merchant Offers Management Screen — إدارة العروض
class MerchantOffersScreen extends ConsumerStatefulWidget {
  final String? highlightOfferId;

  const MerchantOffersScreen({super.key, this.highlightOfferId});

  @override
  ConsumerState<MerchantOffersScreen> createState() =>
      _MerchantOffersScreenState();
}

class _MerchantOffersScreenState extends ConsumerState<MerchantOffersScreen> {
  final Set<String> _busyOfferIds = <String>{};
  final Map<String, GlobalKey> _offerCardKeys = <String, GlobalKey>{};
  String? _highlightedOfferId;
  bool _didRevealHighlightedOffer = false;

  @override
  void initState() {
    super.initState();
    _highlightedOfferId = widget.highlightOfferId;
  }

  @override
  void didUpdateWidget(covariant MerchantOffersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.highlightOfferId != widget.highlightOfferId) {
      _highlightedOfferId = widget.highlightOfferId;
      _didRevealHighlightedOffer = false;
    }
  }

  bool _isOfferBusy(String offerId) => _busyOfferIds.contains(offerId);

  GlobalKey _offerCardKey(String offerId) {
    return _offerCardKeys.putIfAbsent(offerId, GlobalKey.new);
  }

  void _setOfferBusy(String offerId, bool busy) {
    setState(() {
      if (busy) {
        _busyOfferIds.add(offerId);
      } else {
        _busyOfferIds.remove(offerId);
      }
    });
  }

  Future<void> _toggleOfferStatus(MerchantOffer offer, bool value) async {
    if (!ref.read(isOnlineProvider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.offlineActionRequiresConnection,
          ),
        ),
      );
      return;
    }
    final offerId = offer.id;
    if (_isOfferBusy(offerId)) return;
    final l10n = AppLocalizations.of(context)!;
    final nextStatus = value
        ? MerchantOfferStatus.active
        : MerchantOfferStatus.paused;

    _setOfferBusy(offerId, true);
    try {
      await ref
          .read(merchantOffersRepositoryProvider)
          .setOfferStatus(offerId: offerId, status: nextStatus);
      ref.invalidate(merchantOffersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.merchantOffersToggleUpdated(
              nextStatus == MerchantOfferStatus.active
                  ? l10n.merchantOffersActive
                  : l10n.merchantOffersPaused,
            ),
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.merchantOffersToggleError(e.toString())),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        _setOfferBusy(offerId, false);
      }
    }
  }

  Future<void> _deleteOffer(MerchantOffer offer) async {
    if (!ref.read(isOnlineProvider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.offlineActionRequiresConnection,
          ),
        ),
      );
      return;
    }
    final offerId = offer.id;
    if (_isOfferBusy(offerId)) return;
    final l10n = AppLocalizations.of(context)!;

    _setOfferBusy(offerId, true);
    try {
      await ref.read(merchantOffersRepositoryProvider).deleteOffer(offerId);
      ref.invalidate(merchantOffersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.merchantOffersDeleteSuccess),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.merchantOffersDeleteError(e.toString())),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        _setOfferBusy(offerId, false);
      }
    }
  }

  Future<void> _featureOffer(MerchantOffer offer) async {
    final l10n = AppLocalizations.of(context)!;
    if (_isOfferBusy(offer.id)) return;
    final pricing = await ref
        .read(merchantOffersRepositoryProvider)
        .fetchOfferPinPricing();
    if (!pricing.values.any((price) => price > 0)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.merchantOffersPinPricingUnavailable)),
      );
      return;
    }
    final duration = await _showPinDialog(pricing);
    if (duration == null) return;

    _setOfferBusy(offer.id, true);
    try {
      final requestId =
          'offer_pin_${offer.id}_${DateTime.now().millisecondsSinceEpoch}';
      await ref
          .read(merchantOffersRepositoryProvider)
          .pinOffer(
            offerId: offer.id,
            durationDays: duration,
            requestId: requestId,
          );
      ref.invalidate(merchantOffersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.merchantOffersPinSuccess),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final insufficient = e.toString().toLowerCase().contains(
        'insufficient_wallet_balance',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            insufficient
                ? l10n.merchantOffersPinInsufficientBalance
                : l10n.merchantOffersPinError(e.toString()),
          ),
          action: insufficient
              ? SnackBarAction(
                  label: l10n.merchantOffersPinGoWallet,
                  onPressed: () => context.push(AppRoutes.merchantWallet),
                )
              : null,
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) _setOfferBusy(offer.id, false);
    }
  }

  Future<int?> _showPinDialog(Map<int, double> pricing) async {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.merchantOffersPinTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.merchantOffersPinSubtitle),
            const SizedBox(height: 12),
            for (final days in [1, 3, 7])
              if ((pricing[days] ?? 0) > 0)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.merchantOffersPinOption(
                      days,
                      (pricing[days] ?? 0).toStringAsFixed(2),
                    ),
                  ),
                  onTap: () => Navigator.of(dialogContext).pop(days),
                ),
          ],
        ),
      ),
    );
  }

  void _maybeRevealHighlightedOffer(List<MerchantOffer> offers) {
    final highlightOfferId = _highlightedOfferId;
    if (highlightOfferId == null || _didRevealHighlightedOffer) {
      return;
    }

    final exists = offers.any((offer) => offer.id == highlightOfferId);
    if (!exists) {
      _didRevealHighlightedOffer = true;
      return;
    }

    _didRevealHighlightedOffer = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      final targetContext = _offerCardKeys[highlightOfferId]?.currentContext;
      if (targetContext != null) {
        await Scrollable.ensureVisible(
          targetContext,
          alignment: 0.12,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }

      Future<void>.delayed(const Duration(seconds: 3), () {
        if (!mounted || _highlightedOfferId != highlightOfferId) {
          return;
        }
        setState(() => _highlightedOfferId = null);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final offersAsync = ref.watch(merchantOffersProvider);
    final offersSnapshotAsync = ref.watch(merchantOffersSnapshotProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/merchant/dashboard'),
        ),
        title: Text(l10n.merchantOffersTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: ref.watch(isOnlineProvider)
            ? () => _showOfferForm(context, null)
            : () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(
                      context,
                    )!.offlineActionRequiresConnection,
                  ),
                ),
              ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        icon: const Icon(Icons.add),
        label: Text(l10n.merchantOffersNewOffer),
      ),
      body: offersAsync.when(
        loading: () => const Center(child: WainLoadingIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Text(
              l10n.merchantOffersErrorLoad(err.toString()),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ),
        data: (offers) {
          final snapshot = offersSnapshotAsync.asData?.value;
          final showOfflineEmpty =
              offers.isEmpty &&
              snapshot != null &&
              !snapshot.hasData &&
              snapshot.isFromCache &&
              snapshot.fetchedAt == null &&
              !ref.read(isOnlineProvider);
          if (showOfflineEmpty) {
            return const OfflineEmptyState(
              title: 'لا توجد نسخة محفوظة للعروض',
              subtitle:
                  'افتح شاشة العروض مرة واحدة أثناء الاتصال لحفظ نسخة محلية.',
            );
          }

          if (offers.isEmpty) {
            return Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppEmptyState(
                    icon: Icons.local_offer_outlined,
                    message: l10n.merchantOffersEmpty,
                  ),
                  Text(
                    l10n.merchantOffersEmptyPrompt,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          _maybeRevealHighlightedOffer(offers);
          return ListView(
            padding: AppSpacing.screenPadding,
            children: [
              OfflineBanner(
                isVisible: snapshot?.isFromCache ?? false,
                fetchedAt: snapshot?.fetchedAt,
              ),
              if (snapshot?.isFromCache ?? false)
                const SizedBox(height: AppSpacing.md),
              for (final offer in offers)
                _buildOfferCard(
                  context: context,
                  offer: offer,
                  l10n: l10n,
                  theme: theme,
                  colorScheme: colorScheme,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOfferCard({
    required BuildContext context,
    required MerchantOffer offer,
    required AppLocalizations l10n,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    final offerId = offer.id;
    final isBusy = _isOfferBusy(offerId);
    final singleUsePerCustomer = offer.singleUsePerCustomer;
    final now = DateTime.now();
    final effectiveStatus = offer.effectiveStatusAt(now);
    final isActive = effectiveStatus == MerchantOfferStatus.active;
    final isExpired = effectiveStatus == MerchantOfferStatus.expired;
    final endingSoon = offer.isEndingSoonAt(now);
    final isFeatured = offer.isFeaturedAt(now);
    final featuredUntil = offer.featuredUntil;
    final featureExpired = featuredUntil != null && !featuredUntil.isAfter(now);
    final featureExpiringSoon =
        featuredUntil != null &&
        featuredUntil.isAfter(now) &&
        featuredUntil.isBefore(now.add(const Duration(hours: 24)));
    final featureStateText = featureExpired
        ? l10n.merchantOffersFeatureExpired
        : featureExpiringSoon
        ? l10n.merchantOffersFeatureExpiringSoon
        : isFeatured
        ? l10n.merchantOffersFeatureActive
        : null;
    final isHighlighted = offerId == _highlightedOfferId;
    final statusColor = isExpired
        ? colorScheme.error
        : isActive
        ? AppTheme.successColor
        : colorScheme.onSurfaceVariant;
    final borderColor = isHighlighted
        ? colorScheme.primary
        : isExpired
        ? colorScheme.error.withAlpha(90)
        : isActive
        ? AppTheme.successColor.withAlpha(90)
        : colorScheme.outline;
    final surfaceColor = isHighlighted
        ? colorScheme.primaryContainer.withAlpha(36)
        : isExpired
        ? colorScheme.errorContainer.withAlpha(60)
        : colorScheme.surface;

    return AnimatedContainer(
      key: _offerCardKey(offerId),
      duration: const Duration(milliseconds: 350),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: borderColor, width: isHighlighted ? 2 : 1),
        boxShadow: isHighlighted
            ? [
                ...AppShadows.elevated,
                BoxShadow(
                  color: colorScheme.primary.withAlpha(40),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : AppShadows.elevated,
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            leading: Icon(Icons.local_offer, color: statusColor, size: 32),
            title: Text(
              offer.primaryTitle.isNotEmpty
                  ? offer.primaryTitle
                  : l10n.merchantOffersDefaultTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (offer.hasDescription)
                  Text(
                    offer.primaryDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                const SizedBox(height: AppSpacing.xs),
                _buildDateRow(context, offer, l10n),
                const SizedBox(height: AppSpacing.sm),
                _buildStatsRow(context, offer, l10n),
                const SizedBox(height: AppSpacing.sm),
                _buildUsagePolicyChip(context, singleUsePerCustomer, l10n),
                if (isFeatured || featureExpiringSoon || featureExpired) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(
                        Icons.push_pin,
                        size: 13,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        isFeatured
                            ? l10n.merchantOffersFeaturedBadge
                            : l10n.merchantOffersFeatureEndedBadge,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    featuredUntil == null
                        ? l10n.merchantOffersFeatureNeverSet
                        : l10n.merchantOffersFeaturedUntil(
                            '${featuredUntil.day}/${featuredUntil.month}/${featuredUntil.year}',
                          ),
                    style: theme.textTheme.labelSmall,
                  ),
                  if (featureStateText != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      featureStateText,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: featureExpired
                            ? colorScheme.error
                            : featureExpiringSoon
                            ? AppTheme.warningColor
                            : AppTheme.successColor,
                      ),
                    ),
                  ],
                ],
                if (endingSoon) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withAlpha(20),
                      borderRadius: AppSpacing.radiusSm,
                      border: Border.all(
                        color: AppTheme.warningColor.withAlpha(80),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 13,
                          color: AppTheme.warningColor,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          l10n.merchantOffersEndingSoon,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.warningColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            trailing: PopupMenuButton<String>(
              enabled: !isBusy,
              onSelected: (action) =>
                  _handleOfferAction(context, offer, action),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit, size: 20),
                      const SizedBox(width: 8),
                      Text(l10n.merchantOffersEdit),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete,
                        size: 20,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.merchantOffersDeleteMenu,
                        style: const TextStyle(color: AppTheme.errorColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isExpired)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.md,
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: isBusy || isExpired
                        ? null
                        : () => _featureOffer(offer),
                    icon: const Icon(Icons.push_pin, size: 16),
                    label: Text(
                      (isFeatured || featureExpiringSoon || featureExpired)
                          ? l10n.merchantOffersRenewFeature
                          : l10n.merchantOffersPin,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.successColor.withAlpha(18)
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: AppSpacing.radiusSm,
                    ),
                    child: Text(
                      isActive
                          ? l10n.merchantOffersActive
                          : l10n.merchantOffersPaused,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? AppTheme.successColor
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    isActive
                        ? l10n.merchantOffersActive
                        : l10n.merchantOffersPaused,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 52,
                    child: isBusy
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Switch(
                            value: isActive,
                            onChanged: (value) =>
                                _toggleOfferStatus(offer, value),
                          ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: AppSpacing.radiusSm,
                    ),
                    child: Text(
                      l10n.merchantOffersExpired,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  if (featuredUntil != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.merchantOffersExpiredFeatureRenewUnavailable,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateRow(
    BuildContext context,
    MerchantOffer offer,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final startAt = offer.startAt;
    final endAt = offer.endAt;

    String dateText = '';
    if (startAt != null) {
      dateText += '${startAt.day}/${startAt.month}/${startAt.year}';
    }
    if (endAt != null) {
      dateText += ' - ${endAt.day}/${endAt.month}/${endAt.year}';
    }
    if (dateText.isEmpty) dateText = l10n.merchantOffersNoDate;

    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          size: 12,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(dateText, style: theme.textTheme.labelSmall),
      ],
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    MerchantOffer offer,
    AppLocalizations l10n,
  ) {
    final claims = offer.claimsCount;
    final redeemed = offer.redeemedCount;
    final conversion = offer.conversionPercent;
    final theme = Theme.of(context);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _buildMetricChip(
          context: context,
          icon: Icons.people_alt,
          label: l10n.merchantOffersClaims(claims),
          tone: AppTheme.warningColor,
        ),
        _buildMetricChip(
          context: context,
          icon: Icons.check_circle,
          label: l10n.merchantOffersRedeemed(redeemed),
          tone: AppTheme.successColor,
        ),
        _buildMetricChip(
          context: context,
          icon: Icons.percent,
          label: l10n.merchantOffersConversion(conversion.toStringAsFixed(0)),
          tone: theme.colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildUsagePolicyChip(
    BuildContext context,
    bool singleUsePerCustomer,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final color = singleUsePerCustomer
        ? theme.colorScheme.secondary
        : AppTheme.successColor;
    final label = singleUsePerCustomer
        ? l10n.merchantOffersUsageBadgeSingle
        : l10n.merchantOffersUsageBadgeRepeatable;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: AppSpacing.radiusSm,
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            singleUsePerCustomer ? Icons.lock_clock_outlined : Icons.repeat,
            size: 13,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color tone,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: tone.withAlpha(18),
        borderRadius: AppSpacing.radiusSm,
        border: Border.all(color: tone.withAlpha(48)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: tone),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: tone,
            ),
          ),
        ],
      ),
    );
  }

  void _handleOfferAction(
    BuildContext context,
    MerchantOffer offer,
    String action,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    switch (action) {
      case 'edit':
        _showOfferForm(context, offer);
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          useRootNavigator: false,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.merchantOffersDeleteTitle),
            content: Text(l10n.merchantOffersDeleteConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.merchantOffersNo),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(
                  l10n.merchantOffersYesDelete,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await _deleteOffer(offer);
        }
        break;
    }
  }

  void _showOfferForm(BuildContext context, MerchantOffer? existingOffer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MerchantOfferFormSheet(existingOffer: existingOffer),
    );
  }
}
