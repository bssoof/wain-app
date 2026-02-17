import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/providers/location_provider.dart';
import 'package:wain_app/core/services/analytics_service.dart';
import 'package:wain_app/core/utils/navigation_launcher.dart';
import 'package:wain_app/features/map/presentation/providers/map_providers.dart';
import 'package:wain_app/features/map/presentation/providers/route_providers.dart';
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
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  bool _hasCentered = false;
  
  // Analytics Dedup
  final Map<String, DateTime> _previewedVenueIds = {};
  
  // Follow Mode
  bool _isFollowMode = false;
  
  @override
  void initState() {
    super.initState();
    
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
      
      debugPrint('🔎 Searching area: ${bounds.southWest} -> ${bounds.northEast}');
      
      final stopwatch = Stopwatch()..start();
      
      
      // Call Repository (Clean Architecture)
      final newVenues = await ref.read(venueRepositoryProvider).searchVenuesInBounds(
        minLat: bounds.southWest.latitude,
        minLng: bounds.southWest.longitude,
        maxLat: bounds.northEast.latitude,
        maxLng: bounds.northEast.longitude,
        limit: 50,
      );
      
      stopwatch.stop();
      final latencyMs = stopwatch.elapsedMilliseconds;
      
      // No manual parsing needed anymore, Repository returns List<Venue>
      final venuesList = newVenues; // Keeping variable name for diff minimization

      
      debugPrint('📦 Found ${venuesList.length} venues from server');
      
      // Analytics: Log Search Area
      final double latDiff = bounds.northEast.latitude - bounds.southWest.latitude;
      final double lngDiff = bounds.northEast.longitude - bounds.southWest.longitude;
      // Approx km calculation
      final double areaKm2 = (latDiff * 111) * (lngDiff * 111 * math.cos(center.latitude * math.pi / 180)).abs();
      
       ref.read(analyticsServiceProvider).logEvent(
        name: 'geo_search_latency',
        parameters: {
           'latency_ms': latencyMs,
           'result_count': venuesList.length,
           'area_km2': areaKm2,
           'center': '${center.latitude},${center.longitude}'
        }
      );
      ref.read(analyticsServiceProvider).logEvent(
        name: 'map_search_area',
        parameters: {
           'result_count': venuesList.length,
           'area_km2': areaKm2,
           'center': '${center.latitude},${center.longitude}'
        }
      );

      if (venuesList.isEmpty) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('لا توجد أماكن في هذه المنطقة حالياً')),
           );
        }
      } else {
        // Parse and Merge
        final newVenues = venuesList; // Already List<Venue> from Repo
        
        // Count Offers
        final offersCount = newVenues.where((v) => v.hasActiveOffers).length;
        
        ref.read(cachedVenuesProvider().notifier).mergeVenues(
          newVenues, 
          centerLat: center.latitude, 
          centerLng: center.longitude
        );
        
        // Show Summary Toast
        if (mounted) {
          final msg = offersCount > 0 
              ? 'تم العثور على ${newVenues.length} مكان ($offersCount عروض متاحة 🔥)'
              : 'تم العثور على ${newVenues.length} مكان';
              
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text(msg),
               backgroundColor: offersCount > 0 ? Colors.green.shade700 : null,
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
      ref.read(analyticsServiceProvider).logEvent(
        name: 'geo_search_fail', 
        parameters: { 'reason': e.toString().substring(0, math.min(100, e.toString().length)) }
      );

      if (mounted) {
        String msg = 'حدث خطأ في البحث';
        if (e is FirebaseFunctionsException && e.details == 'bounds_too_large') {
           msg = 'المنطقة كبيرة جداً، يرجى التقريب أكثر';
        } else if (e is FirebaseFunctionsException && e.code == 'resource-exhausted') {
           msg = 'تم تجاوز حد البحث المسموح (Rate Limit)';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
            16.0
          );
        } else if (_isFollowMode) {
           _mapController.move(
            LatLng(next.value!.latitude, next.value!.longitude), 
            _mapController.camera.zoom
          );
        }
      }
    });
    
    // Get venues with cache-first loading
    final venuesState = ref.watch(cachedVenuesProvider());
    final venues = venuesState.venues;
    final isOffline = venuesState.isOffline;
    final isLoading = venuesState.isLoading && venues.isEmpty;
    
    // Route state
    final routeState = ref.watch(routeNotifierProvider);
    final selectedVenue = ref.watch(selectedVenueProvider);
    final filteredVenuesProviderVal = ref.watch(filteredVenuesProvider); // Using manual provider
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
      canPop: false, // Prevent default pop
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        
        // 1. If sheet is expanded, collapse it
        if (_sheetController.isAttached && _sheetController.size > 0.2) {
          _sheetController.animateTo(
            0.1, 
            duration: const Duration(milliseconds: 300), 
            curve: Curves.easeOut,
          );
          // Also deselect venue if any
          ref.read(selectedVenueProvider.notifier).select(null);
          return;
        }

        // 2. Allow Pop (return to Home)
        if (context.mounted) {
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
                userLocation?.latitude ?? kRamallahLat,
                userLocation?.longitude ?? kRamallahLng,
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
                          ref.read(analyticsServiceProvider).logMarkerTap(
                            venueId: venue.id,
                            venueName: venue.nameAr,
                            city: venue.city,
                          );

                          // 2. Log Preview Open (Impression) - Dedup 10s
                          final now = DateTime.now();
                          final lastPreview = _previewedVenueIds[venue.id];
                          if (lastPreview == null || now.difference(lastPreview).inSeconds > 10) {
                             ref.read(analyticsServiceProvider).logEvent(
                                name: 'venue_preview_open', 
                                parameters: {
                                  'venue_id': venue.id,
                                  'venue_name': venue.nameAr,
                                  'source': 'map_marker',
                                }
                              );
                              _previewedVenueIds[venue.id] = now;
                          }

                          ref.read(selectedVenueProvider.notifier).select(venue);
                          
                          // Build route if we have user location
                          if (userLocation != null && !isOffline) {
                            ref.read(routeNotifierProvider.notifier).buildRoute(
                              from: LatLng(userLocation.latitude, userLocation.longitude),
                              to: LatLng(venue.lat, venue.lng),
                              venueId: venue.id,
                              city: venue.city,
                              source: 'marker_tap',
                            );
                          }
                          
                          // Improve sheet interaction - ensure map is visible but don't jump if already open
                          if (_sheetController.isAttached && _sheetController.size < 0.25) {
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
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(51),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          markers.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
                      point: LatLng(userLocation.latitude, userLocation.longitude),
                      width: 30,
                      height: 30,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
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
               child: Card(
                 color: AppTheme.primaryColor,
                 child: Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                   child: Row(
                     children: [
                       const Icon(Icons.navigation, color: Colors.white),
                       const SizedBox(width: 12),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             const Text(
                               'وضع الملاحة مفعل',
                               style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                             ),
                             if (routeState.result != null)
                               Text(
                                 '${routeState.result!.distanceFormatted} • ${routeState.result!.durationFormatted}',
                                 style: const TextStyle(color: Colors.white70, fontSize: 13),
                               ),
                           ],
                         ),
                       ),
                       IconButton(
                         icon: const Icon(Icons.close, color: Colors.white),
                         onPressed: () {
                           setState(() => _isFollowMode = false);
                         },
                       ),
                     ],
                   ),
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person, color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(width: 12),
                
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
              top: MediaQuery.of(context).padding.top + 180, // Moved down below search button
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'أنت غير متصل - تصفح النسخة المحفوظة',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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
              child: Center(
                child: WainLoadingIndicator(),
              ),
            ),
          
          // === MY LOCATION BUTTON ===
          Positioned(
            right: 16,
            bottom: 200,
            child: FloatingActionButton.small(
              heroTag: 'myLocation',
              backgroundColor: Colors.white,
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
                    ? Colors.blue 
                    : Colors.grey,
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
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: _buildBottomSheetContent(scrollController, filteredVenues, favorites),
              );
            },
          ),
        ],
      ),
    ));
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'ابحث عن مكان...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(mapFilterProvider.notifier).setQuery('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            label: filterState.sortBy == SortOption.topRated ? 'الأعلى تقييماً' : 'استكشاف',
            icon: filterState.sortBy == SortOption.topRated ? Icons.local_fire_department : Icons.explore,
            isSelected: filterState.sortBy == SortOption.topRated,
            onTap: () {
              final newSort = filterState.sortBy == SortOption.topRated
                  ? SortOption.nearest
                  : SortOption.topRated;
              ref.read(mapFilterProvider.notifier).setSort(newSort);
            },
            // Custom color for trending
            selectedColor: Colors.orange.shade600,
          ),
          const SizedBox(width: 8),

          // Open Now
          _buildFilterChip(
            label: 'مفتوح الآن',
            icon: Icons.access_time,
            isSelected: filterState.openNow,
            onTap: () {
              ref.read(mapFilterProvider.notifier).toggleOpenNow();
            },
          ),
          const SizedBox(width: 8),

          // Partners
          _buildFilterChip(
            label: 'شركاء',
            icon: Icons.verified,
            isSelected: filterState.showPartnersOnly,
            onTap: () {
              ref.read(mapFilterProvider.notifier).toggleShowPartners();
            },
          ),
          const SizedBox(width: 8),

          // Has Offers
          _buildFilterChip(
            label: 'عروض',
            icon: Icons.local_offer,
            isSelected: filterState.hasOffers,
            onTap: () {
              ref.read(mapFilterProvider.notifier).toggleHasOffers();
            },
          ),
          const SizedBox(width: 8),
          
          // Categories
          _buildFilterChip(
            label: 'مطاعم',
            icon: Icons.restaurant,
            isSelected: filterState.categories.contains('restaurant'),
            onTap: () {
              ref.read(mapFilterProvider.notifier).toggleCategory('restaurant');
            },
          ),
          const SizedBox(width: 8),
          
          _buildFilterChip(
            label: 'كافيهات',
            icon: Icons.local_cafe,
            isSelected: filterState.categories.contains('cafe'),
            onTap: () {
              ref.read(mapFilterProvider.notifier).toggleCategory('cafe');
            },
          ),
          const SizedBox(width: 8),
          
          // Mood
          _buildFilterChip(
            label: 'رومانسي',
            icon: Icons.favorite,
            isSelected: filterState.moodTags.contains('romantic'),
            onTap: () {
              ref.read(mapFilterProvider.notifier).toggleMood('romantic');
            },
          ),
          const SizedBox(width: 8),
          
          _buildFilterChip(
            label: 'عائلي',
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
    final activeColor = selectedColor ?? AppTheme.primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetContent(ScrollController scrollController, List<dynamic> filtered, List<String> favorites) {
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
          userLocation.latitude, userLocation.longitude,
          selectedVenue.lat, selectedVenue.lng,
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
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Image
            if (selectedVenue.photos.isNotEmpty)
              Container(
                height: 180,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(selectedVenue.photos.first),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
            Padding(
              padding: const EdgeInsets.all(16),
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
                           style: const TextStyle(
                             fontSize: 22,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                       ),
                       Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star, size: 16, color: Colors.amber.shade800),
                              const SizedBox(width: 4),
                              Text(
                                selectedVenue.rating.toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
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
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                             Icon(Icons.local_offer, size: 14, color: Colors.red.shade700),
                             const SizedBox(width: 6),
                             Text(
                               'يوجد عرض متاح',
                               style: TextStyle(
                                 color: Colors.red.shade800,
                                 fontWeight: FontWeight.bold,
                                 fontSize: 12
                               ),
                             ),
                          ],
                        ),
                      ),
                   
                   // Info Row
                   Row(
                     children: [
                       Text(
                         selectedVenue.categories.firstOrNull ?? 'عام',
                         style: TextStyle(color: Colors.grey.shade600),
                       ),
                       const SizedBox(width: 8),
                       const Text('•', style: TextStyle(color: Colors.grey)),
                       const SizedBox(width: 8),
                       if (distanceKm != null)
                          Text(
                            distanceKm < 1 
                                ? '${(distanceKm * 1000).round()} م'
                                : '${distanceKm.toStringAsFixed(1)} كم',
                            style: TextStyle(color: Colors.grey.shade600),
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
                          label: const Text('احصل على العرض الآن'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                   
                   // Buttons
                   Row(
                     children: [
                       Expanded(
                         child: ElevatedButton.icon(
                           onPressed: () => context.push('/venue/${selectedVenue.id}'),
                           icon: const Icon(Icons.info_outline),
                           label: const Text('التفاصيل'),
                           style: ElevatedButton.styleFrom(
                             backgroundColor: AppTheme.primaryColor,
                             foregroundColor: Colors.white,
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
                                  ref.read(analyticsServiceProvider).logNavigationClick(
                                    venueId: selectedVenue.id,
                                    navApp: 'waze',
                                  );
                                },
                                onGoogleMaps: () {
                                  HapticFeedback.mediumImpact();
                                  ref.read(analyticsServiceProvider).logNavigationClick(
                                    venueId: selectedVenue.id,
                                    navApp: 'google_maps',
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.directions),
                            label: const Text('اتجاهات'),
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
                     color: Colors.grey.shade300,
                     borderRadius: BorderRadius.circular(2),
                   ),
                 ),
               ),
               // Title
               Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '${filtered.length} مكان',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
               ),
            ],
          ),
        ),
        
        // List Items
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final venue = filtered[index];
              final isFavorite = favorites.contains(venue.id);
              
              // Calculate distance
              double? distanceKm;
              if (userLocation != null) {
                distanceKm = _calculateDistance(
                  userLocation.latitude, userLocation.longitude,
                  venue.lat, venue.lng,
                );
              }
              
              return GestureDetector(
                onTap: () {
                  ref.read(selectedVenueProvider.notifier).select(venue);
                  final targetZoom = math.max(_mapController.camera.zoom, 16.0);
                  _mapController.move(LatLng(venue.lat, venue.lng), targetZoom);
                  
                  // Only expand if collapsed
                  if (_sheetController.isAttached && _sheetController.size < 0.25) {
                    _sheetController.animateTo(
                        0.35, // Consistent with marker tap
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: null,
                  ),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getCategoryIcon(venue),
                          color: _getCategoryColor(venue),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              venue.nameAr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (distanceKm != null)
                              Text(
                                'يبعد ${distanceKm.toStringAsFixed(1)} كم',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                      
                      // Favorite
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                        ),
                        onPressed: () {
                          ref.read(favoritesListProvider.notifier).toggle(venue.id);
                        },
                      ),
                      
                      // Arrow
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        onPressed: () => context.push('/venue/${venue.id}'),
                      ),
                    ],
                  ),
                ),
              );
            },
            childCount: filtered.length,
          ),
        ),
        
        // Bottom Padding for safety
        const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
      ],
    );
  }




  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * math.pi / 180;
  }
  
  IconData _getCategoryIcon(dynamic venue) {
    if (venue.categories.isEmpty) return Icons.place;
    final cat = venue.categories.first.toLowerCase();
    
    if (cat.contains('cafe') || cat.contains('coffee') || cat.contains('كافيه')) {
      return Icons.local_cafe;
    } else if (cat.contains('restaurant') || cat.contains('food') || cat.contains('مطعم')) {
      return Icons.restaurant;
    } else if (cat.contains('shisha') || cat.contains('hookah') || cat.contains('argileh')) {
      return Icons.smoke_free;
    } else if (cat.contains('bar') || cat.contains('pub')) {
      return Icons.nightlife;
    } else if (cat.contains('shop') || cat.contains('store') || cat.contains('market')) {
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
      return Colors.brown.shade400;
    } else if (cat.contains('restaurant') || cat.contains('food')) {
      return AppTheme.primaryColor;
    } else if (cat.contains('shisha')) {
      return Colors.purple.shade400;
    } else if (cat.contains('park')) {
      return Colors.green.shade600;
    } else if (cat.contains('bar')) {
      return Colors.indigo.shade400;
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
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(80),
      ),
    );
  }

  /// Build route summary card with navigation button
  Widget _buildRouteCard(
    dynamic routeResult,
    dynamic venue,
    dynamic userLocation,
    bool isOffline,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(38),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.directions,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            routeResult.distanceFormatted,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '≈ ${routeResult.durationFormatted}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
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
          const SizedBox(height: 12),
          
          // Start Navigation button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isOffline ? null : () {
                NavigationLauncher.showNavDialog(
                  context: context,
                  lat: venue.lat,
                  lng: venue.lng,
                  venueName: venue.nameAr,
                  onWaze: () {
                    ref.read(routeNotifierProvider.notifier).logNavStart(
                      venueId: venue.id,
                      city: venue.city,
                      navApp: 'waze',
                    );
                  },
                  onGoogleMaps: () {
                    ref.read(routeNotifierProvider.notifier).logNavStart(
                      venueId: venue.id,
                      city: venue.city,
                      navApp: 'google_maps',
                    );
                  },
                );
              },
              icon: const Icon(Icons.navigation),
              label: Text(isOffline ? 'يحتاج اتصال' : 'ابدأ الملاحة'),
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
    );
  }


}
