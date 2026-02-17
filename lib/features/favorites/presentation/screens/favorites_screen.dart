import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/shared/widgets/venue_card.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
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
        loading: () => const ShimmerVenueList(itemCount: 3),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (favoriteIds) {
          if (favoriteIds.isEmpty) {
            return _buildEmptyState(context);
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
                      category: venue.categories.isNotEmpty ? venue.categories.first : 'عام',
                      rating: venue.rating,
                      distance: '0.0 كم',
                      isFavorite: true,
                      lastStoryAt: venue.lastStoryAt,
                      imageUrl: venue.photos.isNotEmpty ? venue.photos.first : null,
                      onTap: () => context.push('/venue/${venue.id}'),
                      onFavoriteToggle: () {
                        ref.read(favoritesListProvider.notifier).remove(venueId);
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border,
                size: 50,
                color: Colors.red.shade300,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'لسا ما حفظت أماكن',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط على القلب في أي مكان عشان تحفظه هون',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.explore),
              label: const Text('اكتشف أماكن'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
