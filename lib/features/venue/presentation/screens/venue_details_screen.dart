import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wain_app/core/errors/app_exceptions.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/services/analytics_service.dart';
import 'package:wain_app/core/widgets/app_empty_state.dart';
import 'package:wain_app/core/widgets/app_error_widget.dart';
import 'package:wain_app/core/widgets/app_skeleton.dart';
import 'package:wain_app/core/utils/geo_utils.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/features/offers/domain/entities/offer.dart';
import '../../../offers/presentation/screens/offer_qr_code_screen.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../../domain/entities/venue.dart';
import '../providers/venue_providers.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';

import '../../../navigation/presentation/providers/navigation_provider.dart';
import '../../../reviews/presentation/widgets/reviews_section.dart';
import '../../../offers/presentation/providers/offers_providers.dart';
import '../widgets/venue_hero_header.dart';
import '../widgets/venue_hours_section.dart';
import '../widgets/venue_menu_tab.dart';
import '../widgets/venue_meta_section.dart';
import '../widgets/venue_summary_strip.dart';
import '../widgets/venue_social_links_section.dart';
import '../widgets/venue_stories_section.dart';

/// Venue Details Screen
class VenueDetailsScreen extends ConsumerStatefulWidget {
  final String venueId;

  const VenueDetailsScreen({super.key, required this.venueId});

  @override
  ConsumerState<VenueDetailsScreen> createState() => _VenueDetailsScreenState();
}

class _VenueDetailsScreenState extends ConsumerState<VenueDetailsScreen>
    with TickerProviderStateMixin {
  bool _hasLoggedView = false;
  late final TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!mounted) return;
    if (_selectedTabIndex != _tabController.index) {
      _selectedTabIndex = _tabController.index;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  // Launch Maps with deep link
  Future<void> _openMaps(double lat, double lng, String navApp) async {
    Uri uri;
    if (navApp == 'waze') {
      uri = Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');
    } else {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
      );
    }

    // Try to launch in external app first, fallback to browser
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        // Fallback: open in browser
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      // Last resort: try browser
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  // Show BottomSheet and log navigation click
  void _showMapsBottomSheet(
    BuildContext context,
    String venueId,
    double lat,
    double lng,
  ) {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.selectMapApp,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.map, color: Colors.blue, size: 28),
              ),
              title: Text(
                l10n.brandGoogleMaps,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(l10n.openInGoogleMaps),
              onTap: () async {
                Navigator.pop(ctx);
                // Try to log navigation click (don't block if fails)
                try {
                  await ref.read(
                    logNavigationClickProvider(
                      venueId: venueId,
                      navApp: 'google_maps',
                    ).future,
                  );
                } catch (e) {
                  if (kDebugMode) {
                    debugPrint('Failed to log navigation click: $e');
                  }
                }
                // Open maps (always)
                await _openMaps(lat, lng, 'google_maps');
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.lightBlue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.navigation,
                  color: Colors.lightBlue,
                  size: 28,
                ),
              ),
              title: Text(
                l10n.brandWaze,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(l10n.openInWaze),
              onTap: () async {
                Navigator.pop(ctx);
                // Try to log navigation click (don't block if fails)
                try {
                  await ref.read(
                    logNavigationClickProvider(
                      venueId: venueId,
                      navApp: 'waze',
                    ).future,
                  );
                } catch (e) {
                  if (kDebugMode) {
                    debugPrint('Failed to log navigation click: $e');
                  }
                }
                // Open maps (always)
                await _openMaps(lat, lng, 'waze');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  AppException _asAppException(Object error) {
    if (error is AppException) return error;
    return ServerException(message: error.toString());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final venueAsync = ref.watch(venueByIdProvider(widget.venueId));
    final isFavorite = ref.watch(
      favoritesListProvider.select(
        (favoritesAsync) => favoritesAsync.maybeWhen(
          data: (favorites) => favorites.contains(widget.venueId),
          orElse: () => false,
        ),
      ),
    );

    return Scaffold(
      body: venueAsync.when(
        loading: () => const VenueDetailsSkeleton(),
        error: (err, stack) => AppErrorWidget(
          exception: _asAppException(err),
          onRetry: () => ref.invalidate(venueByIdProvider(widget.venueId)),
        ),
        data: (venue) {
          if (venue == null) {
            return AppEmptyState(
              icon: Icons.storefront_outlined,
              message: l10n.venueNotFound,
            );
          }

          // Log venue view (only once per session)
          if (!_hasLoggedView) {
            _hasLoggedView = true;
            final analytics = ref.read(analyticsServiceProvider);
            analytics.logVenueViewFull(
              venueId: venue.id,
              venueName: venue.nameAr,
              city: venue.city,
              source: 'venue_details',
            );
            analytics.trackVenueEvent(
              venueId: venue.id,
              eventType: 'view',
              source: 'venue_details',
            );
          }

          // Combined tags for display (Mood + Occasion)
          final displayTags = <String>[
            ...venue.tags.mood,
            ...venue.tags.occasion,
          ];

          return NestedScrollView(
            floatHeaderSlivers: true,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                VenueHeroHeader(venue: venue, isFavorite: isFavorite),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: VenueMetaSection(
                      venue: venue,
                      displayTags: displayTags,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: VenueSummaryStrip(venue: venue),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: false,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      tabAlignment: TabAlignment.fill,
                      indicatorColor: AppTheme.primaryColor,
                      labelColor: AppTheme.primaryColor,
                      unselectedLabelColor: Colors.grey,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      tabs: [
                        Tab(text: l10n.tabMenu),
                        Tab(text: l10n.tabReviews),
                        Tab(text: l10n.tabAbout),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: _buildActiveTabBody(venue),
          );
        },
      ),
      bottomNavigationBar: venueAsync.asData?.value != null
          ? Consumer(
              builder: (context, ref, _) {
                final venue = venueAsync.asData!.value!;
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        // Call Button (working)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: venue.phone.isNotEmpty
                                ? () async {
                                    final analytics = ref.read(
                                      analyticsServiceProvider,
                                    );
                                    analytics.logCallClick(
                                      venueId: venue.id,
                                      venueName: venue.nameAr,
                                      city: venue.city,
                                      source: 'venue_details',
                                    );
                                    analytics.trackVenueEvent(
                                      venueId: venue.id,
                                      eventType: 'call',
                                      source: 'venue_details',
                                    );
                                    final uri = Uri.parse(
                                      'tel:${venue.normalizedPhone}',
                                    );
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri);
                                    }
                                  }
                                : null,
                            icon: const Icon(Icons.phone),
                            label: Text(l10n.call),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // WhatsApp Button (working)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: venue.phone.isNotEmpty
                                ? () async {
                                    final analytics = ref.read(
                                      analyticsServiceProvider,
                                    );
                                    analytics.logEvent(
                                      name: 'whatsapp_click',
                                      parameters: {
                                        'venue_id': venue.id,
                                        'venue_name': venue.nameAr,
                                        'city': venue.city,
                                        'source': 'venue_details',
                                      },
                                    );
                                    analytics.trackVenueEvent(
                                      venueId: venue.id,
                                      eventType: 'call',
                                      source: 'venue_details',
                                    );
                                    final uri = Uri.parse(
                                      'https://wa.me/${venue.normalizedPhone}',
                                    );
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    }
                                  }
                                : null,
                            icon: const Icon(Icons.chat),
                            label: Text(l10n.whatsapp),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Navigate Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _showMapsBottomSheet(
                                context,
                                venue.id,
                                venue.lat,
                                venue.lng,
                              );
                            },
                            icon: const Icon(Icons.navigation),
                            label: Text(l10n.navigate),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : null,
    );
  }

  void _showClaimConfirmation(Offer offer, String city, String venueName) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.importantNotice, textAlign: TextAlign.right),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.offerValidTenMinutes,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.offerActivationWarning,
              style: const TextStyle(height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleOfferClaim(offer, city, venueName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.activateOfferNow),
          ),
        ],
      ),
    );
  }

  void _handleOfferClaim(Offer offer, String city, String venueName) async {
    final success = await ref
        .read(claimOfferProvider.notifier)
        .claim(offer: offer, source: 'venue_details', city: city);

    if (!mounted) return;

    if (success != null) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OfferQRCodeScreen(
            claimResult: success,
            offer: offer,
            venueName: venueName,
          ),
        ),
      );
    } else {
      final error = ref.read(claimOfferProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.errorPrefix}: '
            '${error ?? AppLocalizations.of(context)!.claimRequestFailed}',
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // === INFO ROW ===
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  // === DISTANCE ROW ===
  Widget _buildDistanceRow(Venue venue) {
    final l10n = AppLocalizations.of(context)!;
    final locationAsync = ref.watch(userLocationProvider);
    return locationAsync.when(
      data: (pos) {
        if (pos == null) {
          return _buildInfoRow(Icons.near_me, l10n.locationUnavailable);
        }
        final dist = calculateDistanceKm(
          pos.latitude,
          pos.longitude,
          venue.lat,
          venue.lng,
        );
        final distText = dist < 1
            ? '${(dist * 1000).toInt()} ${l10n.meterUnit}'
            : '${dist.toStringAsFixed(1)} ${l10n.kilometerUnit}';
        return _buildInfoRow(Icons.near_me, l10n.distanceAway(distText));
      },
      loading: () => _buildInfoRow(Icons.near_me, l10n.detectingLocation),
      error: (error, stackTrace) =>
          _buildInfoRow(Icons.near_me, l10n.failedToDetectLocation),
    );
  }

  Widget _buildActiveTabBody(Venue venue) {
    switch (_selectedTabIndex) {
      case 0:
        return VenueMenuTab(
          venue: venue,
          onClaimOffer: (offer) =>
              _showClaimConfirmation(offer, venue.city, venue.nameAr),
        );
      case 1:
        return CustomScrollView(
          key: const PageStorageKey<String>('reviews_tab'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return switch (index) {
                    0 => VenueStoriesSection(venueId: venue.id),
                    1 => const SizedBox(height: 16),
                    2 => const Divider(),
                    3 => const SizedBox(height: 16),
                    4 => ReviewsSection(
                      venueId: venue.id,
                      venueName: venue.nameAr,
                    ),
                    _ => null,
                  };
                }, childCount: 5),
              ),
            ),
          ],
        );
      default:
        final aboutChildren = <Widget>[
          VenueWorkingHoursSection(venue: venue),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          if (venue.hasSocialLinks) ...[
            VenueSocialLinksSection(venue: venue),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
          ],
          _buildInfoRow(Icons.location_on_outlined, venue.city),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.attach_money,
            '${venue.minPrice} - ${venue.maxPrice} ${venue.currency}',
          ),
          const SizedBox(height: 12),
          _buildDistanceRow(venue),
        ];
        return CustomScrollView(
          key: const PageStorageKey<String>('about_tab'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => aboutChildren[index],
                  childCount: aboutChildren.length,
                ),
              ),
            ),
          ],
        );
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    return Material(
      color: backgroundColor,
      elevation: overlapsContent ? 1.5 : 0,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
