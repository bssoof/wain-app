import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/providers/location_provider.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
import 'package:wain_app/shared/widgets/venue_card.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

/// Section that displays the 5 nearest venues based on user location
class NearbyVenuesSection extends ConsumerWidget {
  const NearbyVenuesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get user location
    final locationAsync = ref.watch(userLocationProvider);

    return locationAsync.when(
      loading: () => _buildLoading(),
      error: (_, _) => const SizedBox.shrink(),
      data: (userLocation) {
        // Get nearby venues
        final nearbyAsync = ref.watch(
          nearbyVenuesProvider(
            userLat: userLocation.latitude,
            userLng: userLocation.longitude,
          ),
        );

        return nearbyAsync.when(
          loading: () => _buildLoading(),
          error: (_, _) => const SizedBox.shrink(),
          data: (nearbyVenues) {
            if (nearbyVenues.isEmpty) return const SizedBox.shrink();

            // Get favorites for heart icons
            final favoritesAsync = ref.watch(favoritesListProvider);
            final favorites = favoritesAsync.when(
              data: (list) => list,
              loading: () => <String>[],
              error: (_, _) => <String>[],
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.near_me,
                            color: AppTheme.primaryColor,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.nearbyVenuesTitle,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (!userLocation.isRealLocation)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.nearbyApproxLocation,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Horizontal Scroll of Venue Cards
                SizedBox(
                  height: 235,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: nearbyVenues.length,
                    itemBuilder: (context, index) {
                      final item = nearbyVenues[index];
                      final venue = item.venue;
                      final distanceStr = _formatDistance(item.distanceKm);
                      final isFavorite = favorites.contains(venue.id);

                      return Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: 12),
                        child: VenueCard(
                          id: venue.id,
                          name: venue.nameAr,
                          category: venue.categories.isNotEmpty
                              ? venue.categories.first
                              : AppLocalizations.of(context)!.categoryGeneral,
                          rating: venue.rating,
                          distance: distanceStr,
                          isFavorite: isFavorite,
                          lastStoryAt: venue.lastStoryAt,
                          imageUrl: venue.photos.isNotEmpty
                              ? venue.photos.first
                              : null,
                          onTap: () => context.push('/venue/${venue.id}'),
                          onFavoriteToggle: () {
                            ref
                                .read(favoritesListProvider.notifier)
                                .toggle(venue.id);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Center(child: WainLoadingIndicator()),
    );
  }

  String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
  }
}
