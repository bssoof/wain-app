import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/shared/widgets/venue_card.dart';
import 'package:wain_app/features/discovery/presentation/providers/search_state.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wain_app/shared/widgets/nearby_venues_section.dart';
import 'package:wain_app/features/discovery/presentation/widgets/filter_bottom_sheet.dart';
import 'package:wain_app/shared/widgets/shimmer_venue_card.dart';

/// Results Screen - Show venue suggestions
class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Get Search Criteria
    final searchState = ref.watch(searchProvider);
    final searchNotifier = ref.watch(searchProvider.notifier);
    
    // 2. Get Favorites
    final favoritesAsync = ref.watch(favoritesListProvider);
    final favorites = favoritesAsync.when(
      data: (list) => list,
      loading: () => <String>[],
      error: (_, _) => <String>[],
    );
    
    // 3. Fetch Recommendations
    final recommendationsAsync = ref.watch(recommendationsProvider(
      city: searchState.city,
      moodTags: searchState.moodTags,
      occasionTags: searchState.occasionTags,
      timeTags: searchState.timeTags,
      minBudget: searchState.minBudget,
      maxBudget: searchState.maxBudget,
      cuisineTypes: searchState.cuisineTypes,
    ));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('اقتراحاتنا'),
        actions: [
          // Filter button with badge
          Stack(
            children: [
              IconButton(
                onPressed: () => showFilterBottomSheet(context),
                icon: const Icon(Icons.tune),
              ),
              if (searchNotifier.hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${searchNotifier.activeFilterCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: recommendationsAsync.when(
        loading: () => const ShimmerVenueList(itemCount: 5),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (venues) {
          if (venues.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Nearby Venues Section (horizontal scroll)
              const NearbyVenuesSection(),
              
              const SizedBox(height: 24),
              
              // Best Match Header
              if (venues.isNotEmpty) _buildBestMatchHeader(),
              
              const SizedBox(height: 16),
              
              // Venue Cards
              ...venues.map((venue) {
                final isBest = venues.indexOf(venue) == 0;
                final isFavorite = favorites.contains(venue.id);
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: VenueCard(
                    id: venue.id,
                    name: venue.nameAr,
                    category: venue.categories.isNotEmpty ? venue.categories.first : 'عام',
                    rating: venue.rating,
                    distance: '0.0 كم', // TODO: Calc real distance
                    isBestMatch: isBest,
                    isFavorite: isFavorite,
                    lastStoryAt: venue.lastStoryAt,
                    imageUrl: venue.photos.isNotEmpty ? venue.photos.first : null,
                    onTap: () => context.push('/venue/${venue.id}'),
                    onFavoriteToggle: () {
                      ref.read(favoritesListProvider.notifier).toggle(venue.id);
                    },
                  ),
                );
              }),
              
              const SizedBox(height: 24),
              
              // Try Again Button
              Center(
                child: TextButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.refresh),
                  label: const Text('غيّر الاختيارات'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBestMatchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withAlpha(25),
            AppTheme.secondaryColor.withAlpha(25),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('✨', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'أفضل اقتراح',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const Text(
                  'بناءً على اختياراتك',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'ما لقينا أماكن بهذي المواصفات 😔',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('جرّب تغيّر بعض الخيارات'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('تغيير الاختيارات'),
          ),
        ],
      ),
    );
  }
}
