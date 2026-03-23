import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/providers/location_provider.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wain_app/features/profile/presentation/providers/settings_providers.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/venue_card.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

/// Section that displays the nearest venues based on user location.
class NearbyVenuesSection extends ConsumerWidget {
  const NearbyVenuesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final city = ref.watch(cityProvider);
    final locationAsync = ref.watch(userLocationProvider);

    return locationAsync.when(
      loading: () => _buildLoading(theme),
      error: (_, _) => const SizedBox.shrink(),
      data: (userLocation) {
        final nearbyAsync = ref.watch(
          nearbyVenuesProvider(
            userLat: userLocation.latitude,
            userLng: userLocation.longitude,
            city: city,
          ),
        );

        return nearbyAsync.when(
          loading: () => _buildLoading(theme),
          error: (_, _) => const SizedBox.shrink(),
          data: (nearbyVenues) {
            if (nearbyVenues.isEmpty) return const SizedBox.shrink();

            final favoritesAsync = ref.watch(favoritesListProvider);
            final favorites = favoritesAsync.when(
              data: (list) => list,
              loading: () => <String>[],
              error: (_, _) => <String>[],
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppTheme.primarySurfaceColor,
                        borderRadius: AppSpacing.radiusMd,
                      ),
                      child: Icon(
                        Icons.near_me_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.nearbyVenuesTitle,
                            style: theme.textTheme.titleLarge,
                          ),
                          Text(
                            userLocation.isRealLocation
                                ? _formatDistance(nearbyVenues.first.distanceKm)
                                : l10n.nearbyApproxLocation,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: userLocation.isRealLocation
                                  ? theme.colorScheme.onSurfaceVariant
                                  : AppTheme.warningColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 292,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: nearbyVenues.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final item = nearbyVenues[index];
                      final venue = item.venue;
                      final isFavorite = favorites.contains(venue.id);

                      return SizedBox(
                        width: 286,
                        child: VenueCard(
                          id: venue.id,
                          name: venue.nameAr,
                          category: venue.categories.isNotEmpty
                              ? venue.categories.first
                              : l10n.categoryGeneral,
                          rating: venue.rating,
                          distance: _formatDistance(item.distanceKm),
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

  Widget _buildLoading(ThemeData theme) {
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const WainLoadingIndicator(),
            const SizedBox(height: AppSpacing.md),
            Text('...', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }
}
