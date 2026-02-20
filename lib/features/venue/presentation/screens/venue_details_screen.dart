import 'dart:async';
import 'dart:math' show asin, cos, pi, sin, sqrt;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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

const Duration _kMenuUiMotionDuration = Duration(milliseconds: 220);

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
  final ScrollController _menuScrollController = ScrollController();
  Timer? _menuSearchDebounce;
  bool _isProgrammaticMenuScroll = false;
  bool _menuScrollSyncScheduled = false;

  @override
  void initState() {
    super.initState();
    _menuScrollController.addListener(_onMenuScroll);
  }

  @override
  void dispose() {
    _menuScrollController.removeListener(_onMenuScroll);
    _menuScrollController.dispose();
    _menuSearchDebounce?.cancel();
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
        error: (err, stack) => Center(child: Text('${l10n.errorPrefix}: $err')),
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

          return DefaultTabController(
            length: 3,
            child: NestedScrollView(
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
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        tabAlignment: TabAlignment.fill,
                        indicatorColor: AppTheme.primaryColor,
                        labelColor: AppTheme.primaryColor,
                        unselectedLabelColor: Colors.grey,
                        indicatorWeight: 3,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
              body: TabBarView(
                children: [
                  // Tab 1: Menu & Offers
                  CustomScrollView(
                    key: const PageStorageKey<String>('menu_tab'),
                    controller: _menuScrollController,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                          child: VenueOffersSection(
                            venue: venue,
                            onClaimOffer: (offer) => _showClaimConfirmation(
                              offer,
                              venue.city,
                              venue.nameAr,
                            ),
                          ),
                        ),
                      ),
                      ..._buildMenuSlivers(venue),
                      const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
                    ],
                  ),
                  // Tab 2: Reviews & Stories
                  CustomScrollView(
                    key: const PageStorageKey<String>('reviews_tab'),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            VenueStoriesSection(venueId: venue.id),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            ReviewsSection(venueId: venue.id, venueName: venue.nameAr),
                          ]),
                        ),
                      ),
                    ],
                  ),
                  // Tab 3: About
                  CustomScrollView(
                    key: const PageStorageKey<String>('about_tab'),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
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
                          ]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
        for (final sectionItems in groupedBySection.values) {
          sectionItems.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        }

        final activeSections = <MenuSection>[];
        for (final section in sections) {
          final hasItems = groupedBySection.keys.any(
            (categoryId) => _categoryMatchesSection(categoryId, section.id),
          );
          if (hasItems) {
            activeSections.add(section);
          }
        }

        final unmatchedCategoryIds =
            groupedBySection.keys
                .where(
                  (categoryId) => !sections.any(
                    (section) =>
                        _categoryMatchesSection(categoryId, section.id),
                  ),
                )
                .toList()
              ..sort();

        for (var i = 0; i < unmatchedCategoryIds.length; i += 1) {
          final categoryId = unmatchedCategoryIds[i];
          final fallbackName = _humanizeCategoryId(categoryId);
          activeSections.add(
            MenuSection(
              id: categoryId,
              nameAr: fallbackName,
              nameEn: fallbackName,
              icon: 'restaurant_menu',
              sortOrder: 1000 + i,
            ),
          );
        }

        activeSections.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        if (activeSections.isEmpty) {
          return _buildMenuImageFallbackSlivers(venue);
        }

        final sectionItemCounts = <String, int>{};
        for (final section in activeSections) {
          sectionItemCounts[section.id] = groupedBySection.entries
              .where(
                (entry) => _categoryMatchesSection(entry.key, section.id),
              )
              .fold<int>(0, (sum, entry) => sum + entry.value.length);
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
          final sorted =
              groupedBySection.entries
                  .where(
                    (entry) => _categoryMatchesSection(entry.key, section.id),
                  )
                  .expand((entry) => entry.value)
                  .toList()
                ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          final filtered = sorted
              .where((item) => _matchesMenuQuery(item, query))
              .toList();
          if (filtered.isEmpty) continue;

          _menuSectionKeys.putIfAbsent(section.id, () => GlobalKey());
          filteredSections.add(
            _MenuSectionGroup(section: section, items: filtered),
          );
        }
        final activeSectionIds = filteredSections
            .map((group) => group.section.id)
            .toSet();
        _menuSectionKeys.removeWhere(
          (sectionId, _) => !activeSectionIds.contains(sectionId),
        );

        final featuredItems =
            availableItems
                .where(
                  (item) => item.isFeatured && _matchesMenuQuery(item, query),
                )
                .toList()
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        final visibleItemsCount = filteredSections.fold<int>(
          0,
          (sum, group) => sum + group.items.length,
        );

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
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: _kMenuUiMotionDuration,
                    child: Text(
                      key: ValueKey<String>(
                        '$visibleItemsCount:${filteredSections.length}',
                      ),
                      '$visibleItemsCount '
                      '\u0635\u0646\u0641 \u0641\u064a ${filteredSections.length} '
                      '\u0623\u0642\u0633\u0627\u0645',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (selectedSectionId == 'all' && featuredItems.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    VenueFeaturedItemsRow(
                      items: featuredItems,
                      onItemTap: _showMenuItemDetailsSheet,
                    ),
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
                    totalCount: availableItems.length,
                    sectionItemCounts: sectionItemCounts,
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
                child: AnimatedSwitcher(
                  duration: _kMenuUiMotionDuration,
                  child: VenueMenuEmptyState(
                    key: ValueKey<String>('empty_menu:$query'),
                    message: l10n.menuNoMatchingResults,
                  ),
                ),
              ),
            ),
          );
        } else {
          slivers.add(
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final group = filteredSections[index];
                  return VenueMenuSectionBlock(
                    key: _menuSectionKeys[group.section.id],
                    section: group.section,
                    items: group.items,
                    initiallyExpanded: index == 0,
                    shouldExpand:
                        selectedSectionId != 'all' &&
                        selectedSectionId == group.section.id,
                    onItemTap: _showMenuItemDetailsSheet,
                  );
                }, childCount: filteredSections.length),
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
              const VenueMenuEmptyState(
                message:
                    '\u0644\u0627 \u064a\u0648\u062c\u062f \u0645\u0646\u064a\u0648 \u062d\u0627\u0644\u064a\u0627\u064b',
              ),
              if (venue.menuImages.isNotEmpty) ...[
                const SizedBox(height: 12),
                VenueMenuImageGallery(images: venue.menuImages),
              ],
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
    _menuSearchDebounce?.cancel();
    _menuSearchDebounce = Timer(const Duration(milliseconds: 120), () {
      if (!mounted || _menuSearchQuery == query) return;
      setState(() {
        _menuSearchQuery = query;
        if (query.isNotEmpty) {
          _selectedMenuCategoryId = 'all';
        }
      });
    });
  }

  void _onMenuSectionSelected(String sectionId) {
    if (_selectedMenuCategoryId != sectionId) {
      setState(() => _selectedMenuCategoryId = sectionId);
    }

    if (sectionId == 'all') return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sectionContext = _menuSectionKeys[sectionId]?.currentContext;
      if (sectionContext == null) return;
      _isProgrammaticMenuScroll = true;
      try {
        await Scrollable.ensureVisible(
          sectionContext,
          duration: _kMenuUiMotionDuration,
          curve: Curves.easeOut,
          alignment: 0.10,
        );
      } finally {
        Future<void>.delayed(const Duration(milliseconds: 120), () {
          if (!mounted) return;
          _isProgrammaticMenuScroll = false;
          _syncSelectedMenuSectionFromScroll(force: true);
        });
      }
    });
  }

  void _onMenuScroll() {
    if (_isProgrammaticMenuScroll || _menuScrollSyncScheduled) return;
    _menuScrollSyncScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _menuScrollSyncScheduled = false;
      _syncSelectedMenuSectionFromScroll();
    });
  }

  void _syncSelectedMenuSectionFromScroll({bool force = false}) {
    if (!mounted || !_menuScrollController.hasClients) return;
    if (_isProgrammaticMenuScroll && !force) return;
    if (_menuSectionKeys.isEmpty) return;

    final currentOffset = _menuScrollController.offset;
    String? visibleSectionId;
    double nearestPastOffset = -double.infinity;
    String? nearestFutureSectionId;
    double nearestFutureOffset = double.infinity;

    _menuSectionKeys.forEach((sectionId, key) {
      final sectionContext = key.currentContext;
      if (sectionContext == null) return;

      final renderObject = sectionContext.findRenderObject();
      if (renderObject == null || !renderObject.attached) return;

      final viewport = RenderAbstractViewport.maybeOf(renderObject);
      if (viewport == null) return;

      final revealOffset = viewport.getOffsetToReveal(renderObject, 0.0).offset;
      final offsetDelta = revealOffset - currentOffset;

      if (offsetDelta <= 16 && revealOffset > nearestPastOffset) {
        nearestPastOffset = revealOffset;
        visibleSectionId = sectionId;
      } else if (offsetDelta > 16 && revealOffset < nearestFutureOffset) {
        nearestFutureOffset = revealOffset;
        nearestFutureSectionId = sectionId;
      }
    });

    final resolvedSectionId = visibleSectionId ?? nearestFutureSectionId;
    if (resolvedSectionId == null ||
        resolvedSectionId == _selectedMenuCategoryId) {
      return;
    }

    setState(() => _selectedMenuCategoryId = resolvedSectionId);
  }

  bool _matchesMenuQuery(MenuItem item, String query) {
    if (query.isEmpty) return true;

    return item.nameAr.toLowerCase().contains(query) ||
        item.nameEn.toLowerCase().contains(query) ||
        item.descriptionAr.toLowerCase().contains(query);
  }

  String _normalizeCategoryKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  bool _categoryMatchesSection(String categoryId, String sectionId) {
    if (categoryId == sectionId) return true;
    return _normalizeCategoryKey(categoryId) ==
        _normalizeCategoryKey(sectionId);
  }

  String _humanizeCategoryId(String value) {
    final normalized = value.trim().replaceAll('_', ' ');
    if (normalized.isEmpty) return 'Other';
    return normalized
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map(
          (word) => word.length == 1
              ? word.toUpperCase()
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  String _formatPrice(double value) {
    if (!value.isFinite) return '0';
    if ((value - value.roundToDouble()).abs() < 0.000001) {
      return value.toStringAsFixed(0);
    }
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'[.]$'), '');
  }

  void _showMenuItemDetailsSheet(MenuItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final bottomPadding = MediaQuery.of(sheetContext).viewPadding.bottom;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.68,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomPadding),
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (item.photoUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        item.photoUrl,
                        height: 210,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 210,
                          color: Colors.grey.shade200,
                          alignment: Alignment.center,
                          child: const Icon(Icons.fastfood, size: 36),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.restaurant_menu, size: 38),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    item.nameAr,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (item.nameEn.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.nameEn,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (item.descriptionAr.isNotEmpty)
                    Text(
                      item.descriptionAr,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  if (item.descriptionAr.isNotEmpty) const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.sell_outlined, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Price',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          '${_formatPrice(item.price)} ${item.currency}',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
