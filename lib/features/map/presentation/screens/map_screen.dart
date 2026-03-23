import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/providers/location_provider.dart';
import 'package:wain_app/core/services/analytics_service.dart';
import 'package:wain_app/core/utils/navigation_launcher.dart';
import 'package:wain_app/core/widgets/blur_container.dart';
import 'package:wain_app/features/map/presentation/providers/map_providers.dart';
import 'package:wain_app/features/map/presentation/providers/route_providers.dart';
import 'package:wain_app/features/profile/presentation/providers/settings_providers.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:wain_app/features/map/presentation/widgets/venue_marker_widget.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:wain_app/features/map/presentation/widgets/cached_tile_provider.dart';
import 'package:wain_app/core/services/tile_cache_service.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

/// Main Map Screen - Shows venues on interactive OpenStreetMap
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  bool _hasCentered = false;

  // Analytics Dedup
  final Map<String, DateTime> _previewedVenueIds = {};

  // Follow Mode
  bool _isFollowMode = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    // Init Tile Cache
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TileCacheService().init();
    });
  }

  // ignore: unused_element - Preserved for future Search This Area feature
  Future<void> _searchArea() async {
    try {
      final center = _mapController.camera.center;
      final bounds = _mapController.camera.visibleBounds;

      debugPrint(
        '🔎 Searching area: ${bounds.southWest} -> ${bounds.northEast}',
      );

      final stopwatch = Stopwatch()..start();

      // Call Repository (Clean Architecture)
      final newVenues = await ref
          .read(venueRepositoryProvider)
          .searchVenuesInBounds(
            minLat: bounds.southWest.latitude,
            minLng: bounds.southWest.longitude,
            maxLat: bounds.northEast.latitude,
            maxLng: bounds.northEast.longitude,
            limit: 50,
          );

      stopwatch.stop();
      final latencyMs = stopwatch.elapsedMilliseconds;

      // No manual parsing needed anymore, Repository returns List<Venue>
      final venuesList =
          newVenues; // Keeping variable name for diff minimization

      debugPrint('📦 Found ${venuesList.length} venues from server');

      // Analytics: Log Search Area
      final double latDiff =
          bounds.northEast.latitude - bounds.southWest.latitude;
      final double lngDiff =
          bounds.northEast.longitude - bounds.southWest.longitude;
      // Approx km calculation
      final double areaKm2 =
          (latDiff * 111) *
          (lngDiff * 111 * math.cos(center.latitude * math.pi / 180)).abs();

      ref
          .read(analyticsServiceProvider)
          .logEvent(
            name: 'geo_search_latency',
            parameters: {
              'latency_ms': latencyMs,
              'result_count': venuesList.length,
              'area_km2': areaKm2,
              'center': '${center.latitude},${center.longitude}',
            },
          );
      ref
          .read(analyticsServiceProvider)
          .logEvent(
            name: 'map_search_area',
            parameters: {
              'result_count': venuesList.length,
              'area_km2': areaKm2,
              'center': '${center.latitude},${center.longitude}',
            },
          );

      if (venuesList.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.mapNoVenuesInArea),
            ),
          );
        }
      } else {
        // Parse and Merge
        final newVenues = venuesList; // Already List<Venue> from Repo

        // Count Offers
        final offersCount = newVenues.where((v) => v.hasActiveOffers).length;

        ref
            .read(cachedVenuesProvider(city: ref.read(cityProvider)).notifier)
            .mergeVenues(
              newVenues,
              centerLat: center.latitude,
              centerLng: center.longitude,
            );

        // Show Summary Toast
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          final msg = offersCount > 0
              ? l10n.mapFoundVenuesWithOffers(
                  '${newVenues.length}',
                  '$offersCount',
                )
              : l10n.mapFoundVenues('${newVenues.length}');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: offersCount > 0 ? AppTheme.successColor : null,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          // Auto-search removed
        });
      }
    } catch (e) {
      debugPrint('❌ Search failed: $e');

      // Log Failure
      ref
          .read(analyticsServiceProvider)
          .logEvent(
            name: 'geo_search_fail',
            parameters: {
              'reason': e.toString().substring(
                0,
                math.min(100, e.toString().length),
              ),
            },
          );

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        String msg = l10n.mapSearchError;
        if (e is FirebaseFunctionsException &&
            e.details == 'bounds_too_large') {
          msg = l10n.mapBoundsTooLarge;
        } else if (e is FirebaseFunctionsException &&
            e.code == 'resource-exhausted') {
          msg = l10n.mapRateLimited;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final city = ref.watch(cityProvider);
    final fallbackLocation = ref.watch(selectedCityFallbackLocationProvider);
    // Get user location for centering
    final locationAsync = ref.watch(userLocationProvider);
    final userLocation = locationAsync.when(
      data: (loc) => loc,
      loading: () => null,
      error: (_, _) => null,
    );

    // Auto-center on first real location OR if Follow Mode is active
    ref.listen(userLocationProvider, (previous, next) {
      if (next.hasValue && next.value!.isRealLocation) {
        if (!_hasCentered) {
          _hasCentered = true;
          _mapController.move(
            LatLng(next.value!.latitude, next.value!.longitude),
            16.0,
          );
        } else if (_isFollowMode) {
          _mapController.move(
            LatLng(next.value!.latitude, next.value!.longitude),
            _mapController.camera.zoom,
          );
        }
      }
    });

    // Get venues with cache-first loading
    final venuesState = ref.watch(cachedVenuesProvider(city: city));
    final venues = venuesState.venues;
    final isOffline = venuesState.isOffline;
    final isLoading = venuesState.isLoading && venues.isEmpty;

    // Route state
    final routeState = ref.watch(routeNotifierProvider);
    final selectedVenue = ref.watch(selectedVenueProvider);
    final filteredVenuesProviderVal = ref.watch(
      filteredVenuesProvider,
    ); // Using manual provider
    final filteredVenues = filteredVenuesProviderVal;

    // Listen to route changes to fit bounds
    ref.listen<RouteState>(routeNotifierProvider, (previous, next) {
      // Fit bounds when route is successfully fetched
      if (next.result != null && previous?.result == null) {
        final ven = ref.read(selectedVenueProvider);
        final loc = ref.read(userLocationProvider).asData?.value;
        if (ven != null && loc != null) {
          _fitBoundsForRoute(loc, ven);
        }
      }
    });

    // Get favorites
    final favoritesAsync = ref.watch(favoritesListProvider);
    final favorites = favoritesAsync.when(
      data: (list) => list,
      loading: () => <String>[],
      error: (_, _) => <String>[],
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (_sheetController.isAttached && _sheetController.size > 0.2) {
          await _sheetController.animateTo(
            0.1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
          ref.read(selectedVenueProvider.notifier).select(null);
          return;
        }

        if (context.mounted && context.canPop()) {
          context.pop();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // === MAP ===
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(
                  userLocation?.latitude ?? fallbackLocation.latitude,
                  userLocation?.longitude ?? fallbackLocation.longitude,
                ),
                initialZoom: 14.0,
                minZoom: 10.0,
                maxZoom: 18.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onTap: (_, _) {
                  // Deselect venue on map tap
                  ref.read(selectedVenueProvider.notifier).select(null);
                  _sheetController.animateTo(
                    0.1, // Collapse sheet
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
                onPositionChanged: (position, hasGesture) {
                  if (hasGesture) {
                    // If user interacts, disable follow mode
                    if (_isFollowMode) setState(() => _isFollowMode = false);

                    // REMOVED: Search This Area Logic
                  }
                },
              ),
              children: [
                // OpenStreetMap Tiles with Cache (Web Safe)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.wain.app',
                  tileProvider: kIsWeb
                      ? NetworkTileProvider()
                      : CachedTileProvider(userAgent: 'com.wain.app'),
                ),

                // Route Polyline
                if (routeState.result != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routeState.result!.points,
                        strokeWidth: 5,
                        color: AppTheme.primaryColor.withAlpha(204),
                      ),
                    ],
                  ),

                // Venue Markers with Clustering
                MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    maxClusterRadius: 120,
                    size: const Size(40, 40),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(50),
                    maxZoom: 15,
                    markers: filteredVenues.map((venue) {
                      final isSelected = selectedVenue?.id == venue.id;
                      return Marker(
                        point: LatLng(venue.lat, venue.lng),
                        width: isSelected ? 60 : 45,
                        height: isSelected ? 60 : 45,
                        child: VenueMarkerWidget(
                          venue: venue,
                          isSelected: isSelected,
                          onTap: () {
                            // 1. Log Marker Tap (Interaction) - Always log
                            ref
                                .read(analyticsServiceProvider)
                                .logMarkerTap(
                                  venueId: venue.id,
                                  venueName: venue.nameAr,
                                  city: venue.city,
                                );

                            // 2. Log Preview Open (Impression) - Dedup 10s
                            final now = DateTime.now();
                            final lastPreview = _previewedVenueIds[venue.id];
                            if (lastPreview == null ||
                                now.difference(lastPreview).inSeconds > 10) {
                              ref
                                  .read(analyticsServiceProvider)
                                  .logEvent(
                                    name: 'venue_preview_open',
                                    parameters: {
                                      'venue_id': venue.id,
                                      'venue_name': venue.nameAr,
                                      'source': 'map_marker',
                                    },
                                  );
                              _previewedVenueIds[venue.id] = now;
                            }

                            ref
                                .read(selectedVenueProvider.notifier)
                                .select(venue);

                            // Build route if we have user location
                            if (userLocation != null && !isOffline) {
                              ref
                                  .read(routeNotifierProvider.notifier)
                                  .buildRoute(
                                    from: LatLng(
                                      userLocation.latitude,
                                      userLocation.longitude,
                                    ),
                                    to: LatLng(venue.lat, venue.lng),
                                    venueId: venue.id,
                                    city: venue.city,
                                    source: 'marker_tap',
                                  );
                            }

                            // Improve sheet interaction - ensure map is visible but don't jump if already open
                            if (_sheetController.isAttached &&
                                _sheetController.size < 0.25) {
                              _sheetController.animateTo(
                                0.35,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            }
                          },
                        ),
                      );
                    }).toList(),
                    builder: (context, markers) {
                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 2,
                          ),
                          boxShadow: AppShadows.elevated,
                        ),
                        child: Center(
                          child: Text(
                            markers.length.toString(),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // User Location Marker
                if (userLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          userLocation.latitude,
                          userLocation.longitude,
                        ),
                        width: 30,
                        height: 30,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.infoColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.surface,
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            Icons.person,
                            color: theme.colorScheme.onPrimary,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // === NAVIGATION OVERLAY ===
            if (_isFollowMode)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                child: BlurContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  borderRadius: AppSpacing.radiusLg,
                  color: AppTheme.primaryColor.withAlpha(220),
                  border: Border.all(
                    color: theme.colorScheme.surface.withAlpha(70),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.navigation_rounded,
                        color: theme.colorScheme.onPrimary,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.mapNavModeActive,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                            if (routeState.result != null)
                              Text(
                                '${routeState.result!.distanceFormatted(l10n)} • ${routeState.result!.durationFormatted(l10n)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimary.withAlpha(
                                    220,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: theme.colorScheme.onPrimary,
                        ),
                        onPressed: () {
                          setState(() => _isFollowMode = false);
                        },
                      ),
                    ],
                  ),
                ),
              ),

            // REMOVED: Search This Area Button

            // === SEARCH & PROFILE ===
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  // Profile/Menu Button
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: Container(
                      width: AppSpacing.touchTargetMin,
                      height: AppSpacing.touchTargetMin,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.colorScheme.outline),
                        boxShadow: AppShadows.elevated,
                      ),
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Search Bar
                  Expanded(child: _buildSearchBar()),
                ],
              ),
            ),

            // === FILTER CHIPS ===
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 0,
              right: 0,
              child: _buildFilterChips(),
            ),

            // === OFFLINE BANNER ===
            if (isOffline)
              Positioned(
                top:
                    MediaQuery.of(context).padding.top +
                    180, // Moved down below search button
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: AppSpacing.radiusMd,
                    border: Border.all(
                      color: AppTheme.warningColor.withAlpha(90),
                    ),
                    boxShadow: AppShadows.elevated,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        color: AppTheme.warningColor,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm + 2),
                      Expanded(
                        child: Text(
                          l10n.mapOfflineBanner,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppTheme.warningColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // === LOADING INDICATOR ===
            if (isLoading)
              const Positioned.fill(
                child: Center(child: WainLoadingIndicator()),
              ),

            // === MY LOCATION BUTTON ===
            Positioned(
              right: 16,
              bottom: 200,
              child: FloatingActionButton.small(
                heroTag: 'myLocation',
                backgroundColor: theme.colorScheme.surface,
                onPressed: () {
                  if (userLocation != null) {
                    _mapController.move(
                      LatLng(userLocation.latitude, userLocation.longitude),
                      15.0,
                    );
                    // Reset search area to user location
                    ref.read(mapFilterProvider.notifier).setSearchArea(null);
                    setState(() {
                      // search area removed
                    });
                  }
                },
                child: Icon(
                  Icons.my_location,
                  color: userLocation?.isRealLocation == true
                      ? AppTheme.infoColor
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            // === ROUTE SUMMARY CARD ===
            if (routeState.result != null && selectedVenue != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 160,
                child: _buildRouteCard(
                  routeState.result!,
                  selectedVenue,
                  userLocation,
                  isOffline,
                ),
              ),

            // === BOTTOM SHEET ===
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.15,
              minChildSize: 0.1,
              maxChildSize: 0.7,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.xl),
                    ),
                    boxShadow: AppShadows.overlay,
                  ),
                  child: _buildBottomSheetContent(
                    scrollController,
                    filteredVenues,
                    favorites,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    return BlurContainer(
      borderRadius: AppSpacing.radiusMd,
      color: theme.colorScheme.surface.withAlpha(220),
      border: Border.all(color: theme.colorScheme.outline.withAlpha(170)),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.mapSearchHint,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(mapFilterProvider.notifier).setQuery('');
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
        onChanged: (value) {
          ref.read(mapFilterProvider.notifier).setQuery(value);
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    final filterState = ref.watch(mapFilterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Sort / Explore Mode
          _buildFilterChip(
            label: filterState.sortBy == SortOption.topRated
                ? AppLocalizations.of(context)!.mapFilterTopRated
                : AppLocalizations.of(context)!.mapFilterExplore,
            icon: filterState.sortBy == SortOption.topRated
                ? Icons.local_fire_department
                : Icons.explore,
            isSelected: filterState.sortBy == SortOption.topRated,
            onTap: () {
              final newSort = filterState.sortBy == SortOption.topRated
                  ? SortOption.nearest
                  : SortOption.topRated;
              ref.read(mapFilterProvider.notifier).setSort(newSort);
            },
            // Custom color for trending
            selectedColor: AppTheme.warningColor,
          ),
          const SizedBox(width: 8),

          // Open Now
          _buildFilterChip(
            label: AppLocalizations.of(context)!.mapFilterOpenNow,
            icon: Icons.access_time,
            isSelected: filterState.openNow,
            onTap: () {
              ref.read(mapFilterProvider.notifier).toggleOpenNow();
            },
          ),
          const SizedBox(width: 8),

          // Partners
          _buildFilterChip(
            label: AppLocalizations.of(context)!.mapFilterPartners,
            icon: Icons.verified,
            isSelected: filterState.showPartnersOnly,
            onTap: () {
              ref.read(mapFilterProvider.notifier).toggleShowPartners();
            },
          ),
          const SizedBox(width: 8),

          // Has Offers
          _buildFilterChip(
            label: AppLocalizations.of(context)!.mapFilterOffers,
            icon: Icons.local_offer,
            isSelected: filterState.hasOffers,
            onTap: () {
              ref.read(mapFilterProvider.notifier).toggleHasOffers();
            },
          ),
          const SizedBox(width: 8),

          // Categories
          _buildFilterChip(
            label: AppLocalizations.of(context)!.mapFilterRestaurants,
            icon: Icons.restaurant,
            isSelected: filterState.categories.contains('restaurant'),
            onTap: () {
              ref.read(mapFilterProvider.notifier).toggleCategory('restaurant');
            },
          ),
          const SizedBox(width: 8),

          _buildFilterChip(
            label: AppLocalizations.of(context)!.mapFilterCafes,
            icon: Icons.local_cafe,
            isSelected: filterState.categories.contains('cafe'),
            onTap: () {
              ref.read(mapFilterProvider.notifier).toggleCategory('cafe');
            },
          ),
          const SizedBox(width: 8),

          // Mood
          _buildFilterChip(
            label: AppLocalizations.of(context)!.mapFilterRomantic,
            icon: Icons.favorite,
            isSelected: filterState.moodTags.contains('romantic'),
            onTap: () {
              ref.read(mapFilterProvider.notifier).toggleMood('romantic');
            },
          ),
          const SizedBox(width: 8),

          _buildFilterChip(
            label: AppLocalizations.of(context)!.mapFilterFamily,
            icon: Icons.family_restroom,
            isSelected: filterState.moodTags.contains('family'),
            onTap: () {
              ref.read(mapFilterProvider.notifier).toggleMood('family');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    Color? selectedColor,
  }) {
    final theme = Theme.of(context);
    final activeColor = selectedColor ?? AppTheme.primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : theme.colorScheme.surface,
          borderRadius: AppSpacing.radiusFull,
          border: Border.all(
            color: isSelected ? activeColor : theme.colorScheme.outline,
          ),
          boxShadow: AppShadows.elevated,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.xs + 2),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetContent(
    ScrollController scrollController,
    List<dynamic> filtered,
    List<String> favorites,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final selectedVenue = ref.watch(selectedVenueProvider);
    final userLocationAsync = ref.watch(userLocationProvider);
    final userLocation = userLocationAsync.when(
      data: (loc) => loc,
      loading: () => null,
      error: (_, _) => null,
    );

    // 1. Show Preview Card if venue selected
    if (selectedVenue != null) {
      double? distanceKm;
      if (userLocation != null) {
        distanceKm = _calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          selectedVenue.lat,
          selectedVenue.lng,
        );
      }

      return SingleChildScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(), // Ensures drag works
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(
                  top: AppSpacing.md,
                  bottom: AppSpacing.md,
                ),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: AppSpacing.radiusFull,
                ),
              ),
            ),

            // Image
            if (selectedVenue.photos.isNotEmpty)
              Container(
                height: 180,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  borderRadius: AppSpacing.radiusLg,
                  image: DecorationImage(
                    image: NetworkImage(selectedVenue.photos.first),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          selectedVenue.nameAr,
                          style: theme.textTheme.headlineMedium,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withAlpha(24),
                          borderRadius: AppSpacing.radiusSm,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: AppTheme.warningColor,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              selectedVenue.rating.toString(),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppTheme.warningColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Offer Badge
                  if (selectedVenue.hasActiveOffers)
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm + 2,
                        vertical: AppSpacing.xs + 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primarySurfaceColor,
                        borderRadius: AppSpacing.radiusFull,
                        border: Border.all(
                          color: AppTheme.primaryColor.withAlpha(60),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_offer_outlined,
                            size: 14,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: AppSpacing.xs + 2),
                          Text(
                            l10n.mapOfferAvailable,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Info Row
                  Row(
                    children: [
                      Text(
                        selectedVenue.categories.firstOrNull ??
                            l10n.mapCategoryGeneral,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 8),
                      Text('•', style: theme.textTheme.bodyMedium),
                      const SizedBox(width: 8),
                      if (distanceKm != null)
                        Text(
                          formatDistance(distanceKm, l10n),
                          style: theme.textTheme.bodyMedium,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Claim Offer CTA
                  if (selectedVenue.hasActiveOffers)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: FilledButton.icon(
                        onPressed: () {
                          context.push('/venue/${selectedVenue.id}');
                        },
                        icon: const Icon(Icons.local_offer),
                        label: Text(l10n.mapGetOfferNow),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSpacing.radiusMd,
                          ),
                          textStyle: theme.textTheme.labelLarge,
                        ),
                      ),
                    ),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              context.push('/venue/${selectedVenue.id}'),
                          icon: const Icon(Icons.info_outline),
                          label: Text(l10n.mapDetails),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            NavigationLauncher.showNavDialog(
                              context: context,
                              lat: selectedVenue.lat,
                              lng: selectedVenue.lng,
                              venueName: selectedVenue.nameAr,
                              onWaze: () {
                                HapticFeedback.mediumImpact();
                                ref
                                    .read(analyticsServiceProvider)
                                    .logNavigationClick(
                                      venueId: selectedVenue.id,
                                      navApp: 'waze',
                                    );
                              },
                              onGoogleMaps: () {
                                HapticFeedback.mediumImpact();
                                ref
                                    .read(analyticsServiceProvider)
                                    .logNavigationClick(
                                      venueId: selectedVenue.id,
                                      navApp: 'google_maps',
                                    );
                              },
                            );
                          },
                          icon: const Icon(Icons.directions),
                          label: Text(l10n.mapDirections),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 2. Default List View (Search/Browse) -> SLIVER IMPLEMENTATION
    return CustomScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Header (Handle + Title)
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 0),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline,
                    borderRadius: AppSpacing.radiusFull,
                  ),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.mapVenueCount('${filtered.length}'),
                  style: theme.textTheme.headlineSmall,
                ),
              ),
            ],
          ),
        ),

        // List Items
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final venue = filtered[index];
            final isFavorite = favorites.contains(venue.id);

            // Calculate distance
            double? distanceKm;
            if (userLocation != null) {
              distanceKm = _calculateDistance(
                userLocation.latitude,
                userLocation.longitude,
                venue.lat,
                venue.lng,
              );
            }

            return GestureDetector(
              onTap: () {
                ref.read(selectedVenueProvider.notifier).select(venue);
                final targetZoom = math.max(_mapController.camera.zoom, 16.0);
                _mapController.move(LatLng(venue.lat, venue.lng), targetZoom);

                // Only expand if collapsed
                if (_sheetController.isAttached &&
                    _sheetController.size < 0.25) {
                  _sheetController.animateTo(
                    0.35, // Consistent with marker tap
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.only(
                  bottom: AppSpacing.md,
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: AppSpacing.radiusMd,
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withAlpha(25),
                        borderRadius: AppSpacing.radiusSm,
                      ),
                      child: Icon(
                        _getCategoryIcon(venue),
                        color: _getCategoryColor(venue),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            venue.nameAr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                          if (distanceKm != null)
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.mapDistanceAway(distanceKm.toStringAsFixed(1)),
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),

                    // Favorite
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite
                            ? AppTheme.errorColor
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        ref
                            .read(favoritesListProvider.notifier)
                            .toggle(venue.id);
                      },
                    ),

                    // Arrow
                    IconButton(
                      icon: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () => context.push('/venue/${venue.id}'),
                    ),
                  ],
                ),
              ),
            );
          }, childCount: filtered.length),
        ),

        // Bottom Padding for safety
        const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
      ],
    );
  }

  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

  IconData _getCategoryIcon(dynamic venue) {
    if (venue.categories.isEmpty) return Icons.place;
    final cat = venue.categories.first.toLowerCase();

    if (cat.contains('cafe') ||
        cat.contains('coffee') ||
        cat.contains('كافيه')) {
      return Icons.local_cafe;
    } else if (cat.contains('restaurant') ||
        cat.contains('food') ||
        cat.contains('مطعم')) {
      return Icons.restaurant;
    } else if (cat.contains('shisha') ||
        cat.contains('hookah') ||
        cat.contains('argileh')) {
      return Icons.smoke_free;
    } else if (cat.contains('bar') || cat.contains('pub')) {
      return Icons.nightlife;
    } else if (cat.contains('shop') ||
        cat.contains('store') ||
        cat.contains('market')) {
      return Icons.shopping_bag;
    } else if (cat.contains('park') || cat.contains('garden')) {
      return Icons.park;
    }
    return Icons.place;
  }

  Color _getCategoryColor(dynamic venue) {
    if (venue.categories.isEmpty) return AppTheme.primaryColor;
    final cat = venue.categories.first.toLowerCase();

    if (cat.contains('cafe') || cat.contains('coffee')) {
      return AppTheme.warningColor;
    } else if (cat.contains('restaurant') || cat.contains('food')) {
      return AppTheme.primaryColor;
    } else if (cat.contains('shisha')) {
      return AppTheme.secondaryColor;
    } else if (cat.contains('park')) {
      return AppTheme.successColor;
    } else if (cat.contains('bar')) {
      return AppTheme.infoColor;
    }
    return AppTheme.primaryColor;
  }

  /// Fit map bounds to show user location and venue with route
  void _fitBoundsForRoute(dynamic userLocation, dynamic venue) {
    final bounds = LatLngBounds(
      LatLng(
        math.min(userLocation.latitude, venue.lat),
        math.min(userLocation.longitude, venue.lng),
      ),
      LatLng(
        math.max(userLocation.latitude, venue.lat),
        math.max(userLocation.longitude, venue.lng),
      ),
    );

    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(80)),
    );
  }

  /// Build route summary card with navigation button
  Widget _buildRouteCard(
    dynamic routeResult,
    dynamic venue,
    dynamic userLocation,
    bool isOffline,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return BlurContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppSpacing.radiusLg,
      color: theme.colorScheme.surface.withAlpha(225),
      border: Border.all(color: theme.colorScheme.outline.withAlpha(170)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Route info row
          Row(
            children: [
              // Distance & Duration
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm + 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withAlpha(25),
                        borderRadius: AppSpacing.radiusMd,
                      ),
                      child: Icon(
                        Icons.directions_rounded,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            routeResult.distanceFormatted(l10n),
                            style: theme.textTheme.headlineSmall,
                          ),
                          Text(
                            '≈ ${routeResult.durationFormatted(AppLocalizations.of(context)!)}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Close button
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  ref.read(routeNotifierProvider.notifier).clearRoute();
                  ref.read(selectedVenueProvider.notifier).select(null);
                  final targetZoom = math.max(_mapController.camera.zoom, 16.0);
                  _mapController.move(_mapController.camera.center, targetZoom);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Start Navigation button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isOffline
                  ? null
                  : () {
                      NavigationLauncher.showNavDialog(
                        context: context,
                        lat: venue.lat,
                        lng: venue.lng,
                        venueName: venue.nameAr,
                        onWaze: () {
                          ref
                              .read(routeNotifierProvider.notifier)
                              .logNavStart(
                                venueId: venue.id,
                                city: venue.city,
                                navApp: 'waze',
                              );
                        },
                        onGoogleMaps: () {
                          ref
                              .read(routeNotifierProvider.notifier)
                              .logNavStart(
                                venueId: venue.id,
                                city: venue.city,
                                navApp: 'google_maps',
                              );
                        },
                      );
                    },
              icon: const Icon(Icons.navigation_rounded),
              label: Text(
                isOffline ? l10n.mapNeedsConnection : l10n.mapStartNavigation,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.radiusMd,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

