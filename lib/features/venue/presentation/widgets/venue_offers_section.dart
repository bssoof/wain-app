import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/offers/domain/entities/offer.dart';
import 'package:wain_app/features/offers/presentation/providers/offers_providers.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

class VenueOffersSection extends ConsumerWidget {
  static const int _inlinePreviewLimit = 2;

  final Venue venue;
  final ValueChanged<Offer> onClaimOffer;

  const VenueOffersSection({
    super.key,
    required this.venue,
    required this.onClaimOffer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final offersAsync = ref.watch(offersByVenueProvider(venueId: venue.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withAlpha(18),
                borderRadius: AppSpacing.radiusMd,
              ),
              child: Icon(
                Icons.local_offer_rounded,
                color: AppTheme.warningColor,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(l10n.offersAvailable, style: theme.textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        offersAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: WainLoadingIndicator(),
            ),
          ),
          error: (error, stackTrace) => _MessageCard(
            icon: Icons.error_outline_rounded,
            color: AppTheme.errorColor,
            message: l10n.offersLoadFailed,
          ),
          data: (offers) {
            final redeemedByOffer = <String, bool>{
              for (final offer in offers)
                offer.id: ref
                    .watch(offerRedeemedStatusProvider(offer.id))
                    .maybeWhen(data: (value) => value, orElse: () => false),
            };
            final displayData = _resolveDisplayData(offers, redeemedByOffer);

            if (displayData.sheetOffersCount == 0) {
              return _MessageCard(
                icon: Icons.card_giftcard_rounded,
                color: theme.colorScheme.onSurfaceVariant,
                message: l10n.noOffersNow,
                subtitle: l10n.followForNewOffers,
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (displayData.previewOffers.isEmpty)
                  _MessageCard(
                    icon: Icons.card_giftcard_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    message: l10n.noOffersNow,
                    subtitle: l10n.followForNewOffers,
                  )
                else
                  ...displayData.previewOffers.map(
                    (offer) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _OfferPreviewCard(
                        offer: offer,
                        onOpenDetails: () => context.push('/offer/${offer.id}'),
                        onClaim: () => onClaimOffer(offer),
                      ),
                    ),
                  ),
                if (displayData.shouldShowAllOffersCta)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () =>
                          _showAllOffersSheet(context, l10n, displayData),
                      icon: const Icon(Icons.view_list_rounded),
                      label: Text(
                        l10n.venueOffersViewAll(displayData.sheetOffersCount),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  _VenueOfferDisplayData _resolveDisplayData(
    List<Offer> offers,
    Map<String, bool> redeemedByOffer,
  ) {
    final validOffers = offers.where((offer) => offer.isValid).toList()
      ..sort(_compareOffers);
    final availableOffers = <Offer>[];
    final usedOffers = <Offer>[];

    for (final offer in validOffers) {
      final alreadyUsed =
          offer.singleUsePerCustomer && (redeemedByOffer[offer.id] ?? false);
      if (alreadyUsed) {
        usedOffers.add(offer);
      } else {
        availableOffers.add(offer);
      }
    }

    final previewOffers = availableOffers.take(_inlinePreviewLimit).toList();
    return _VenueOfferDisplayData(
      previewOffers: previewOffers,
      availableOffers: availableOffers,
      usedOffers: usedOffers,
    );
  }

  int _compareOffers(Offer a, Offer b) {
    final partnerCompare = (b.isPartner ? 1 : 0).compareTo(a.isPartner ? 1 : 0);
    if (partnerCompare != 0) {
      return partnerCompare;
    }

    final discountCompare = _offerPriorityValue(
      b,
    ).compareTo(_offerPriorityValue(a));
    if (discountCompare != 0) {
      return discountCompare;
    }

    final aEndsAt = a.endAt ?? DateTime(9999);
    final bEndsAt = b.endAt ?? DateTime(9999);
    final urgencyCompare = aEndsAt.compareTo(bEndsAt);
    if (urgencyCompare != 0) {
      return urgencyCompare;
    }

    return a.title.compareTo(b.title);
  }

  double _offerPriorityValue(Offer offer) {
    switch (offer.discountType) {
      case DiscountType.amount:
        return offer.discountValue + 1000;
      case DiscountType.percent:
        return offer.discountValue + 500;
      case DiscountType.freeItem:
        return 100;
    }
  }

  void _showAllOffersSheet(
    BuildContext context,
    AppLocalizations l10n,
    _VenueOfferDisplayData displayData,
  ) {
    final theme = Theme.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        maxChildSize: 0.94,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: AppShadows.overlay,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: AppSpacing.radiusFull,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.xl,
                  AppSpacing.sm,
                ),
                child: Text(
                  l10n.venueOffersAllTitle,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.sm,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  children: [
                    if (displayData.availableOffers.isNotEmpty) ...[
                      _BottomSheetSectionLabel(
                        title: l10n.venueOffersAvailableNow,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...displayData.availableOffers.map(
                        (offer) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _OfferPreviewCard(
                            offer: offer,
                            onOpenDetails: () =>
                                context.push('/offer/${offer.id}'),
                            onClaim: () => onClaimOffer(offer),
                          ),
                        ),
                      ),
                    ],
                    if (displayData.usedOffers.isNotEmpty) ...[
                      if (displayData.availableOffers.isNotEmpty)
                        const SizedBox(height: AppSpacing.sm),
                      _BottomSheetSectionLabel(
                        title: l10n.venueOffersPreviouslyUsed,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...displayData.usedOffers.map(
                        (offer) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _OfferPreviewCard(
                            offer: offer,
                            onOpenDetails: () =>
                                context.push('/offer/${offer.id}'),
                            onClaim: () => onClaimOffer(offer),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VenueOfferDisplayData {
  final List<Offer> previewOffers;
  final List<Offer> availableOffers;
  final List<Offer> usedOffers;

  const _VenueOfferDisplayData({
    required this.previewOffers,
    required this.availableOffers,
    required this.usedOffers,
  });

  int get sheetOffersCount => availableOffers.length + usedOffers.length;

  bool get shouldShowAllOffersCta =>
      availableOffers.length > previewOffers.length || usedOffers.isNotEmpty;
}

class _OfferPreviewCard extends ConsumerWidget {
  final Offer offer;
  final VoidCallback onOpenDetails;
  final VoidCallback onClaim;

  const _OfferPreviewCard({
    required this.offer,
    required this.onOpenDetails,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final redeemedAsync = ref.watch(offerRedeemedStatusProvider(offer.id));
    final isAlreadyUsed =
        offer.singleUsePerCustomer &&
        redeemedAsync.maybeWhen(data: (value) => value, orElse: () => false);
    final isExpired = offer.isExpired || !offer.isActive;
    final accentColor = isExpired
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.primary;
    final surfaceColor = isExpired
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.surface;
    final borderColor = isExpired
        ? theme.colorScheme.outlineVariant
        : offer.isPartner
        ? theme.colorScheme.primary
        : theme.colorScheme.outline;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: borderColor),
        boxShadow: AppShadows.elevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: AppSpacing.radiusMd,
                ),
                child: Text(
                  offer.getDiscountText(l10n),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  offer.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isExpired
                        ? theme.colorScheme.onSurfaceVariant
                        : null,
                  ),
                ),
              ),
              if (offer.isPartner && !isExpired)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withAlpha(18),
                    borderRadius: AppSpacing.radiusFull,
                  ),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    color: AppTheme.warningColor,
                    size: 16,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            offer.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isExpired ? theme.colorScheme.onSurfaceVariant : null,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  offer.getValidityText(l10n),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isExpired
                        ? theme.colorScheme.onSurfaceVariant
                        : null,
                    fontWeight: isExpired ? FontWeight.w700 : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onOpenDetails,
                  child: Text(l10n.offerDetails),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: isExpired
                      ? null
                      : isAlreadyUsed
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.offerErrorAlreadyUsed),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                        }
                      : onClaim,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isExpired || isAlreadyUsed
                        ? theme.colorScheme.surfaceContainerHighest
                        : null,
                    foregroundColor: isExpired || isAlreadyUsed
                        ? theme.colorScheme.onSurfaceVariant
                        : null,
                  ),
                  child: Text(
                    isExpired
                        ? l10n.offerValidityExpired
                        : isAlreadyUsed
                        ? l10n.offerQrRedeemed
                        : l10n.getOffer,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  final String? subtitle;

  const _MessageCard({
    required this.icon,
    required this.color,
    required this.message,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _BottomSheetSectionLabel extends StatelessWidget {
  final String title;

  const _BottomSheetSectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}
