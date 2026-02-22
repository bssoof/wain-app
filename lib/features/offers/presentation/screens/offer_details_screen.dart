import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/services/analytics_service.dart';
import 'package:wain_app/features/offers/domain/entities/offer.dart';
import 'package:wain_app/features/offers/presentation/providers/offers_providers.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
import 'package:wain_app/features/offers/presentation/screens/offer_qr_code_screen.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';
import 'package:wain_app/l10n/app_localizations.dart';

/// Screen for displaying offer details
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

    ref
        .read(analyticsServiceProvider)
        .logEvent(
          name: 'offer_view',
          parameters: {
            'offer_id': offer.id,
            'venue_id': offer.venueId,
            'source': 'offer_details',
            'is_partner': offer.isPartner.toString(),
            'city': city,
          },
        );
  }

  void _handleClaim(Offer offer, String city, String venueName) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final result = await ref
          .read(claimOfferProvider.notifier)
          .claim(offer: offer, source: 'offer_details', city: city);

      if (!mounted) return;

      if (result != null) {
        // Success: Navigate to QR Screen
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
      } else {
        final error = ref.read(claimOfferProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ ${error ?? l10n.offerDetailsRequestFailFallback}"),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      String msg = l10n.offerDetailsUnexpectedError;
      if (e.toString().contains('failed-precondition')) {
        msg = l10n.offerDetailsAlreadyUsed;
      } else if (e.toString().contains('resource-exhausted')) {
        msg = l10n.offerDetailsLimitExceeded;
      } else if (e.toString().contains('network')) {
        msg = l10n.offerDetailsNoInternet;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, textDirection: TextDirection.rtl),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final offerAsync = ref.watch(offerByIdProvider(offerId: widget.offerId));
    final claimState = ref.watch(claimOfferProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: offerAsync.when(
        loading: () => const Center(child: WainLoadingIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                l10n.offerDetailsLoadFail,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        data: (offer) {
          if (offer == null) {
            return Center(child: Text(l10n.offerDetailsNotFound));
          }

          // Fetch venue to get city
          // We can use a Consumer to fetch venue without rebuilding the entire scaffold if unnecessary,
          // but here we need city for actions.
          final venueAsync = ref.watch(venueByIdProvider(offer.venueId));

          return venueAsync.when(
            loading: () => const Center(child: WainLoadingIndicator()),
            error: (_, _) =>
                Center(child: Text(l10n.offerDetailsVenueLoadFail)),
            data: (venue) {
              if (venue == null) {
                return Center(child: Text(l10n.offerDetailsVenueNotFound));
              }

              // Log view with city
              _logOfferView(offer, venue.city);

              return CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    expandedHeight: 200,
                    pinned: true,
                    backgroundColor: AppTheme.primaryColor,
                    actions: [
                      // Save/Bookmark Button
                      Consumer(
                        builder: (context, ref, child) {
                          final isSavedAsync = ref.watch(
                            isOfferSavedProvider(offer.id),
                          );
                          return isSavedAsync.when(
                            data: (isSaved) => IconButton(
                              iconSize: 32,
                              onPressed: () async {
                                await ref
                                    .read(savedOffersListProvider.notifier)
                                    .toggle(offer.id);
                                // Refresh saved offers full list
                                ref.invalidate(savedOffersFullProvider);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isSaved ? l10n.offerDetailsSaveRemoved : l10n.offerDetailsSaved,
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              icon: Icon(
                                isSaved
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            loading: () => const SizedBox(
                              width: 56,
                              height: 56,
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: WainLoadingIndicator(),
                                ),
                              ),
                            ),
                            error: (_, _) => IconButton(
                              iconSize: 32,
                              onPressed: null,
                              icon: const Icon(
                                Icons.bookmark_border,
                                color: Colors.white54,
                                size: 32,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryColor.withAlpha(204),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  offer.getDiscountText(l10n),
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              if (offer.isPartner) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        l10n.offerDetailsExclusive,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
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

                  // Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            offer.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Description
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              offer.description,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                                height: 1.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Validity
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.offerDetailsValidity,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      offer.getValidityText(l10n),
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Terms
                          if (offer.termsAr != null &&
                              offer.termsAr!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.orange.shade700,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n.offerDetailsTerms,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    offer.termsAr!,
                                    style: TextStyle(
                                      color: Colors.orange.shade800,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(
                            height: 100,
                          ), // Space for bottom button
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),

      // Bottom Claim Button
      bottomNavigationBar: offerAsync.when(
        loading: () => null,
        error: (_, _) => null,
        data: (offer) {
          if (offer == null) return null;

          // Verify venue loaded for city
          final venueAsync = ref.watch(venueByIdProvider(offer.venueId));

          return venueAsync.maybeWhen(
            data: (venue) {
              if (venue == null) return null;
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: ElevatedButton(
                    onPressed: claimState.isLoading
                        ? null
                        : () => _handleClaim(offer, venue.city, venue.nameAr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: claimState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: WainLoadingIndicator(),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.card_giftcard),
                              const SizedBox(width: 8),
                              Text(
                                l10n.getOffer,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              );
            },
            orElse: () => null,
          );
        },
      ),
    );
  }
}
