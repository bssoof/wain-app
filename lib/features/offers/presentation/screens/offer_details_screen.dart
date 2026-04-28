import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/services/analytics_service.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/widgets/app_button.dart';
import 'package:wain_app/core/widgets/offline_widgets.dart';
import 'package:wain_app/features/offers/domain/entities/offer.dart';
import 'package:wain_app/features/offers/presentation/providers/offers_providers.dart';
import 'package:wain_app/features/offers/presentation/screens/offer_qr_code_screen.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

/// Screen for displaying offer details.
class OfferDetailsScreen extends ConsumerStatefulWidget {
  final String offerId;

  const OfferDetailsScreen({super.key, required this.offerId});

  @override
  ConsumerState<OfferDetailsScreen> createState() => _OfferDetailsScreenState();
}

class _OfferDetailsScreenState extends ConsumerState<OfferDetailsScreen> {
  bool _hasLoggedView = false;

  void _logOfferView(Offer offer, String city) {
    if (_hasLoggedView) return;
    _hasLoggedView = true;

    final analytics = ref.read(analyticsServiceProvider);
    analytics.logEvent(
      name: 'offer_view',
      parameters: {
        'offer_id': offer.id,
        'venue_id': offer.venueId,
        'source': 'offer_details',
        'is_partner': offer.isPartner.toString(),
        'city': city,
      },
    );
    analytics.trackOfferDetailView(
      venueId: offer.venueId,
      offerId: offer.id,
      source: 'offer_details',
    );
  }

  Future<void> _handleClaim(Offer offer, String city, String venueName) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await ref
          .read(claimOfferProvider.notifier)
          .claim(offer: offer, source: 'offer_details', city: city);

      if (!mounted) return;

      if (result != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OfferQRCodeScreen(
              claimResult: result,
              offer: offer,
              venueName: venueName,
            ),
            fullscreenDialog: true,
          ),
        );
        return;
      }

      final error = ref.read(claimOfferProvider).error;
      final message = _claimErrorMessage(l10n, error);
      messenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor),
      );
    } catch (error) {
      if (!mounted) return;

      var message = l10n.offerDetailsUnexpectedError;
      final value = error.toString();
      if (value.contains('offer_already_used') ||
          value.contains('failed-precondition')) {
        message = l10n.offerErrorAlreadyUsed;
      } else if (value.contains('offer_expired')) {
        message = l10n.offerErrorExpired;
      } else if (value.contains('offer_inactive') ||
          value.contains('offer_not_started')) {
        message = l10n.offerErrorUnavailable;
      } else if (value.contains('resource-exhausted')) {
        message = l10n.offerDetailsLimitExceeded;
      } else if (value.contains('network')) {
        message = l10n.offerDetailsNoInternet;
      }

      messenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  String _claimErrorMessage(AppLocalizations l10n, String? error) {
    switch (error) {
      case 'offer_already_used':
        return l10n.offerErrorAlreadyUsed;
      case 'offer_expired':
        return l10n.offerErrorExpired;
      case 'offer_inactive':
      case 'offer_not_started':
        return l10n.offerErrorUnavailable;
      case 'claim_save_failed':
      case null:
      case '':
        return l10n.offerDetailsRequestFailFallback;
      default:
        return error;
    }
  }

  String _claimActionLabel(AppLocalizations l10n, Offer offer) {
    if (offer.isExpired) return l10n.offerValidityExpired;
    if (!offer.isValid) return l10n.offerErrorUnavailable;
    return l10n.getOffer;
  }

  void _showAlreadyUsedMessage(AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.offerErrorAlreadyUsed),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final offerSnapshotAsync = ref.watch(
      offerByIdSnapshotProvider(widget.offerId),
    );
    final offerAsync = ref.watch(offerByIdProvider(offerId: widget.offerId));
    final claimState = ref.watch(claimOfferProvider);
    final redeemedAsync = ref.watch(
      offerRedeemedStatusProvider(widget.offerId),
    );

    return offerAsync.when(
      loading: () => _buildStateScaffold(
        context,
        child: const Center(child: WainLoadingIndicator()),
      ),
      error: (error, stackTrace) => _buildStateScaffold(
        context,
        child: _buildMessageState(
          theme,
          icon: Icons.error_outline_rounded,
          title: l10n.offerDetailsLoadFail,
        ),
      ),
      data: (offer) {
        final offerSnapshot = offerSnapshotAsync.asData?.value;
        final showOfflineEmpty =
            offer == null &&
            offerSnapshot != null &&
            !offerSnapshot.hasData &&
            offerSnapshot.isFromCache &&
            offerSnapshot.fetchedAt == null;
        if (showOfflineEmpty) {
          return _buildStateScaffold(
            context,
            child: const OfflineEmptyState(
              title: 'لا توجد نسخة محفوظة لهذا العرض',
              subtitle: 'افتح العرض مرة واحدة أثناء الاتصال لحفظ نسخة محلية.',
            ),
          );
        }

        if (offer == null) {
          return _buildStateScaffold(
            context,
            child: _buildMessageState(
              theme,
              icon: Icons.local_offer_outlined,
              title: l10n.offerDetailsNotFound,
            ),
          );
        }

        final venueAsync = ref.watch(venueByIdProvider(offer.venueId));
        return venueAsync.when(
          loading: () => _buildStateScaffold(
            context,
            child: const Center(child: WainLoadingIndicator()),
          ),
          error: (error, stackTrace) => _buildStateScaffold(
            context,
            child: _buildMessageState(
              theme,
              icon: Icons.storefront_outlined,
              title: l10n.offerDetailsVenueLoadFail,
            ),
          ),
          data: (venue) {
            if (venue == null) {
              return _buildStateScaffold(
                context,
                child: _buildMessageState(
                  theme,
                  icon: Icons.storefront_outlined,
                  title: l10n.offerDetailsVenueNotFound,
                ),
              );
            }

            _logOfferView(offer, venue.city);
            final isSavedAsync = ref.watch(isOfferSavedProvider(offer.id));
            final isUnavailable = !offer.isValid;
            final isAlreadyUsed =
                offer.singleUsePerCustomer &&
                redeemedAsync.maybeWhen(
                  data: (value) => value,
                  orElse: () => false,
                );
            final headerStart = isUnavailable
                ? theme.colorScheme.surfaceContainerHighest
                : theme.colorScheme.primary;
            final headerEnd = isUnavailable
                ? theme.colorScheme.surfaceContainer
                : AppTheme.secondaryColor;

            return Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: OfflineBanner(
                      isVisible: offerSnapshot?.isFromCache ?? false,
                      fetchedAt: offerSnapshot?.fetchedAt,
                    ),
                  ),
                  SliverAppBar(
                    expandedHeight: 250,
                    pinned: true,
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    surfaceTintColor: Colors.transparent,
                    actions: [
                      isSavedAsync.when(
                        data: (isSaved) => IconButton(
                          onPressed: () async {
                            await ref
                                .read(savedOffersListProvider.notifier)
                                .toggle(offer.id);
                            ref.invalidate(savedOffersFullProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isSaved
                                        ? l10n.offerDetailsSaveRemoved
                                        : l10n.offerDetailsSaved,
                                  ),
                                ),
                              );
                            }
                          },
                          icon: Icon(
                            isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                          ),
                        ),
                        loading: () => const Padding(
                          padding: EdgeInsetsDirectional.only(
                            end: AppSpacing.md,
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: WainLoadingIndicator(size: 20),
                            ),
                          ),
                        ),
                        error: (error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [headerStart, headerEnd],
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.xl,
                              72,
                              AppSpacing.xl,
                              AppSpacing.xl,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xl,
                                    vertical: AppSpacing.md,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: AppSpacing.radiusLg,
                                    boxShadow: AppShadows.elevated,
                                  ),
                                  child: Text(
                                    offer.getDiscountText(l10n),
                                    style: theme.textTheme.displayMedium
                                        ?.copyWith(
                                          color: isUnavailable
                                              ? theme
                                                    .colorScheme
                                                    .onSurfaceVariant
                                              : theme.colorScheme.primary,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                if (offer.isPartner && !isUnavailable) ...[
                                  const SizedBox(height: AppSpacing.md),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.warningColor,
                                      borderRadius: AppSpacing.radiusFull,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.workspace_premium_rounded,
                                          size: 16,
                                          color: theme.colorScheme.onPrimary,
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Text(
                                          l10n.offerDetailsExclusive,
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                                color:
                                                    theme.colorScheme.onPrimary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: AppSpacing.screenPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primarySurfaceColor,
                              borderRadius: AppSpacing.radiusFull,
                            ),
                            child: Text(
                              venue.nameAr,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            offer.title,
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _OfferInfoCard(
                            icon: Icons.description_outlined,
                            title: l10n.menuItemDescLabel,
                            child: Text(
                              offer.description,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _OfferInfoCard(
                            icon: Icons.schedule_rounded,
                            title: l10n.offerDetailsValidity,
                            toneColor: AppTheme.infoColor,
                            child: Text(
                              offer.getValidityText(l10n),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppTheme.infoColor,
                              ),
                            ),
                          ),
                          if (offer.termsAr != null &&
                              offer.termsAr!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.lg),
                            _OfferInfoCard(
                              icon: Icons.info_outline_rounded,
                              title: l10n.offerDetailsTerms,
                              toneColor: AppTheme.warningColor,
                              child: Text(
                                offer.termsAr!,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                          ],
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: AppShadows.overlay,
                  border: Border(
                    top: BorderSide(color: theme.colorScheme.outline),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: OnlineOnlyGuard(
                    child: AppButton.primary(
                      label: isAlreadyUsed
                          ? l10n.offerQrRedeemed
                          : _claimActionLabel(l10n, offer),
                      onPressed: claimState.isLoading
                          ? null
                          : isUnavailable
                          ? null
                          : isAlreadyUsed
                          ? () => _showAlreadyUsedMessage(l10n)
                          : () => _handleClaim(offer, venue.city, venue.nameAr),
                      icon: const Icon(Icons.card_giftcard_rounded),
                      isLoading: claimState.isLoading,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Scaffold _buildStateScaffold(BuildContext context, {required Widget child}) {
    return Scaffold(body: SafeArea(child: child));
  }

  Widget _buildMessageState(
    ThemeData theme, {
    required IconData icon,
    required String title,
  }) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Color? toneColor;

  const _OfferInfoCard({
    required this.icon,
    required this.title,
    required this.child,
    this.toneColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = toneColor ?? theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: AppShadows.elevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: accent.withAlpha(18),
                  borderRadius: AppSpacing.radiusMd,
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
