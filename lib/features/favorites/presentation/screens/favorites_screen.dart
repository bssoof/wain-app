import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/errors/app_exceptions.dart';
import 'package:wain_app/core/widgets/app_empty_state.dart';
import 'package:wain_app/core/widgets/app_error_widget.dart';
import 'package:wain_app/core/widgets/app_skeleton.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
import 'package:wain_app/shared/widgets/venue_card.dart';
import 'package:wain_app/shared/widgets/shimmer_venue_card.dart';

/// Favorites Screen
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get favorites list
    final favoritesAsync = ref.watch(favoritesListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('المفضلة'),
      ),
      body: favoritesAsync.when(
        loading: () => const VenueListSkeleton(count: 3),
        error: (err, stack) => AppErrorWidget(
          exception: _asAppException(err),
          onRetry: () => ref.invalidate(favoritesListProvider),
        ),
        data: (favoriteIds) {
          if (favoriteIds.isEmpty) {
            return AppEmptyState.noFavorites(context,
              onExplore: () => context.go('/home'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favoriteIds.length,
            itemBuilder: (context, index) {
              final venueId = favoriteIds[index];
              final venueAsync = ref.watch(venueByIdProvider(venueId));

              return venueAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: ShimmerVenueCard(),
                ),
                error: (_, _) => const SizedBox.shrink(),
                data: (venue) {
                  if (venue == null) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: VenueCard(
                      id: venue.id,
                      name: venue.nameAr,
                      category: venue.categories.isNotEmpty
                          ? venue.categories.first
                          : 'عام',
                      rating: venue.rating,
                      distance: '0.0 كم',
                      isFavorite: true,
                      lastStoryAt: venue.lastStoryAt,
                      imageUrl: venue.photos.isNotEmpty
                          ? venue.photos.first
                          : null,
                      onTap: () => context.push('/venue/${venue.id}'),
                      onFavoriteToggle: () {
                        ref
                            .read(favoritesListProvider.notifier)
                            .remove(venueId);
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  AppException _asAppException(Object error) {
    if (error is AppException) return error;
    return ServerException(message: error.toString());
  }
}
