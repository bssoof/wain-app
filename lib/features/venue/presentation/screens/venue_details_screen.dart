import 'dart:math' show asin, cos, pi, sin, sqrt;
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/services/analytics_service.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/features/offers/domain/entities/offer.dart';
import '../../../offers/presentation/screens/offer_qr_code_screen.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../../domain/entities/venue.dart';
import '../providers/venue_providers.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';

import '../../../navigation/presentation/providers/navigation_provider.dart';
import '../../../reviews/presentation/widgets/reviews_section.dart';
import '../../../menu/presentation/providers/menu_providers.dart';
import '../../../menu/domain/entities/menu_item.dart';
import '../../../menu/domain/entities/menu_section.dart';
import '../../../offers/presentation/providers/offers_providers.dart';
import '../widgets/venue_hero_header.dart';
import '../widgets/venue_hours_section.dart';
import '../widgets/venue_menu_section.dart';
import '../widgets/venue_meta_section.dart';
import '../widgets/venue_offers_section.dart';
import '../widgets/venue_social_links_section.dart';
import '../widgets/venue_stories_section.dart';

/// Venue Details Screen
class VenueDetailsScreen extends ConsumerStatefulWidget {
  final String venueId;

  const VenueDetailsScreen({super.key, required this.venueId});

  @override
  ConsumerState<VenueDetailsScreen> createState() => _VenueDetailsScreenState();
}

class _VenueDetailsScreenState extends ConsumerState<VenueDetailsScreen> {
  bool _hasLoggedView = false;
  final TextEditingController _menuSearchController = TextEditingController();
  final Map<String, GlobalKey> _menuSectionKeys = {};
  String _menuSearchQuery = '';
  String _selectedMenuCategoryId = 'all';

  @override
  void dispose() {
    _menuSearchController.dispose();
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
              title: const Text(
                'Google Maps',
                style: TextStyle(fontWeight: FontWeight.w600),
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
                  debugPrint('Failed to log navigation click: $e');
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
              title: const Text(
                'Waze',
                style: TextStyle(fontWeight: FontWeight.w600),
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
                  debugPrint('Failed to log navigation click: $e');
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Watch to keep alive/observe
    ref.watch(claimOfferProvider);
    final venueAsync = ref.watch(venueByIdProvider(widget.venueId));

    // Favorites
    final favoritesAsync = ref.watch(favoritesListProvider);
    final favorites = favoritesAsync.when(
      data: (list) => list,
      loading: () => <String>[],
      error: (_, _) => <String>[],
    );
    final isFavorite = favorites.contains(widget.venueId);

    return Scaffold(
      body: venueAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (venue) {
          if (venue == null) {
            return Center(child: Text(l10n.venueNotFound));
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
          ].take(5).toList();

          return CustomScrollView(
            slivers: [
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
              ..._buildMenuSlivers(venue),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // === OFFERS SECTION ===
                    VenueOffersSection(
                      venue: venue,
                      onClaimOffer: (offer) => _showClaimConfirmation(
                        offer,
                        venue.city,
                        venue.nameAr,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // === STORIES SECTION ===
                    VenueStoriesSection(venueId: venue.id),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // === REVIEWS SECTION ===
                    ReviewsSection(venueId: venue.id, venueName: venue.nameAr),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // === WORKING HOURS ===
                    VenueWorkingHoursSection(venue: venue),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // === SOCIAL LINKS ===
                    if (venue.hasSocialLinks) ...[
                      VenueSocialLinksSection(venue: venue),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                    ],

                    // Info Items
                    _buildInfoRow(Icons.location_on_outlined, venue.city),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.attach_money,
                      '${venue.minPrice} - ${venue.maxPrice} ${venue.currency}',
                    ),
                    const SizedBox(height: 12),
                    // Real distance from user location
                    _buildDistanceRow(venue),
                  ]),
                ),
              ),
            ],
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

  // === MENU SLIVERS (structured menu + sticky category filters + search) ===
  List<Widget> _buildMenuSlivers(Venue venue) {
    final l10n = AppLocalizations.of(context)!;
    final venueCategory = venue.categories.isNotEmpty
        ? venue.categories.first
        : 'restaurant';
    final menuAsync = ref.watch(menuItemsProvider(venue.id));
    final sections = ref.watch(menuSectionsProvider(venueCategory));

    return menuAsync.when(
      loading: () => [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: VenueMenuLoadingSkeleton(),
          ),
        ),
      ],
      error: (error, stackTrace) => _buildMenuImageFallbackSlivers(venue),
      data: (items) {
        final availableItems = items.where((i) => i.isAvailable).toList();
        if (availableItems.isEmpty) {
          return _buildMenuImageFallbackSlivers(venue);
        }

        final groupedBySection = <String, List<MenuItem>>{};
        for (final item in availableItems) {
          groupedBySection.putIfAbsent(item.category, () => []).add(item);
        }

        final activeSections = sections
            .where(
              (section) => groupedBySection[section.id]?.isNotEmpty ?? false,
            )
            .toList();

        if (activeSections.isEmpty) {
          return _buildMenuImageFallbackSlivers(venue);
        }

        final selectedSectionId =
            activeSections.any(
              (section) => section.id == _selectedMenuCategoryId,
            )
            ? _selectedMenuCategoryId
            : 'all';

        final query = _menuSearchQuery.trim().toLowerCase();
        final filteredSections = <_MenuSectionGroup>[];

        for (final section in activeSections) {
          final sorted = [...(groupedBySection[section.id] ?? <MenuItem>[])]
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          if (selectedSectionId != 'all' && selectedSectionId != section.id) {
            continue;
          }

          final filtered = sorted
              .where((item) => _matchesMenuQuery(item, query))
              .toList();
          if (filtered.isEmpty) continue;

          _menuSectionKeys.putIfAbsent(section.id, () => GlobalKey());
          filteredSections.add(
            _MenuSectionGroup(section: section, items: filtered),
          );
        }

        final featuredItems =
            availableItems
                .where(
                  (item) => item.isFeatured && _matchesMenuQuery(item, query),
                )
                .toList()
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        final slivers = <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 16),
                  VenueMenuHeader(itemCount: availableItems.length),
                  const SizedBox(height: 12),
                  VenueMenuSearchField(
                    controller: _menuSearchController,
                    onChanged: _onMenuSearchChanged,
                    onClear: _menuSearchController.text.isEmpty
                        ? null
                        : () {
                            _menuSearchController.clear();
                            _onMenuSearchChanged('');
                          },
                  ),
                  if (featuredItems.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    VenueFeaturedItemsRow(items: featuredItems),
                  ],
                ],
              ),
            ),
          ),
        ];

        if (activeSections.length > 1) {
          slivers.add(
            SliverPersistentHeader(
              pinned: true,
              delegate: PinnedMenuHeaderDelegate(
                height: 60,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                  alignment: Alignment.centerLeft,
                  child: VenueMenuCategoryChips(
                    sections: activeSections,
                    selectedSectionId: selectedSectionId,
                    onSelected: _onMenuSectionSelected,
                  ),
                ),
              ),
            ),
          );
        }

        if (filteredSections.isEmpty) {
          slivers.add(
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: VenueMenuEmptyState(message: l10n.menuNoMatchingResults),
              ),
            ),
          );
        } else {
          slivers.add(
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  filteredSections.map((group) {
                    return VenueMenuSectionBlock(
                      key: _menuSectionKeys[group.section.id],
                      section: group.section,
                      items: group.items,
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        }

        if (venue.menuImages.isNotEmpty) {
          slivers.add(
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: VenueMenuImageGallery(images: venue.menuImages),
              ),
            ),
          );
        }

        slivers.add(
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Divider(),
            ),
          ),
        );

        return slivers;
      },
    );
  }

  List<Widget> _buildMenuImageFallbackSlivers(Venue venue) {
    final l10n = AppLocalizations.of(context)!;
    final fallbackItemCount = venue.menuImages.length;

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              const SizedBox(height: 16),
              VenueMenuHeader(
                itemCount: fallbackItemCount,
                counterLabel: fallbackItemCount == 1
                    ? l10n.photoSingle
                    : l10n.photoPlural,
              ),
              const SizedBox(height: 12),
              if (venue.menuImages.isNotEmpty)
                VenueMenuImageGallery(images: venue.menuImages)
              else
                VenueMenuEmptyState(message: l10n.noMenuAvailable),
            ],
          ),
        ),
      ),
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Divider(),
        ),
      ),
    ];
  }

  void _onMenuSearchChanged(String query) {
    if (_menuSearchQuery == query) return;
    setState(() => _menuSearchQuery = query);
  }

  void _onMenuSectionSelected(String sectionId) {
    if (_selectedMenuCategoryId == sectionId) return;
    setState(() => _selectedMenuCategoryId = sectionId);

    if (sectionId == 'all') return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sectionContext = _menuSectionKeys[sectionId]?.currentContext;
      if (sectionContext == null) return;
      Scrollable.ensureVisible(
        sectionContext,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        alignment: 0.10,
      );
    });
  }

  bool _matchesMenuQuery(MenuItem item, String query) {
    if (query.isEmpty) return true;

    return item.nameAr.toLowerCase().contains(query) ||
        item.nameEn.toLowerCase().contains(query) ||
        item.descriptionAr.toLowerCase().contains(query);
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
        final dist = _calculateDistance(
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

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371.0; // km
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return 2 * r * asin(sqrt(a));
  }
}

class _MenuSectionGroup {
  final MenuSection section;
  final List<MenuItem> items;

  const _MenuSectionGroup({required this.section, required this.items});
}
