import 'package:flutter/material.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/errors/app_exceptions.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/widgets/app_empty_state.dart';
import 'package:wain_app/core/widgets/app_error_widget.dart';
import 'package:wain_app/core/widgets/app_skeleton.dart';
import 'package:wain_app/features/discovery/presentation/providers/search_state.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wain_app/shared/widgets/nearby_venues_section.dart';
import 'package:wain_app/shared/widgets/venue_card.dart';
import '../widgets/filter_bottom_sheet.dart';

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
    final recommendationsRequest = recommendationsProvider(
      city: searchState.city,
      moodTags: searchState.moodTags,
      occasionTags: searchState.occasionTags,
      timeTags: searchState.timeTags,
      minBudget: searchState.minBudget,
      maxBudget: searchState.maxBudget,
      cuisineTypes: searchState.cuisineTypes,
    );
    final recommendationsAsync = ref.watch(recommendationsRequest);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(AppLocalizations.of(context)!.resultsSuggestions),
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
        loading: () => const VenueListSkeleton(count: 5),
        error: (err, stack) => AppErrorWidget(
          exception: _asAppException(err),
          onRetry: () => ref.invalidate(recommendationsRequest),
        ),
        data: (venues) {
          if (venues.isEmpty) {
            return AppEmptyState.noResults(context,
              onClearFilters: () {
                searchNotifier.reset(city: searchState.city);
                context.go('/home');
              },
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Nearby Venues Section (horizontal scroll)
              const NearbyVenuesSection(),

              const SizedBox(height: 24),

              // Best Match Header
              if (venues.isNotEmpty) _buildBestMatchHeader(context),

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
                    category: venue.categories.isNotEmpty
                        ? venue.categories.first
                        : AppLocalizations.of(context)!.categoryGeneral,
                    rating: venue.rating,
                    distance: '0.0 km',
                    isBestMatch: isBest,
                    isFavorite: isFavorite,
                    lastStoryAt: venue.lastStoryAt,
                    imageUrl: venue.photos.isNotEmpty
                        ? venue.photos.first
                        : null,
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
                  label: Text(AppLocalizations.of(context)!.resultsChangeChoices),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  AppException _asAppException(Object error) {
    if (error is AppException) return error;
    return ServerException(message: error.toString());
  }

  Widget _buildBestMatchHeader(BuildContext context) {
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
                Text(
                  AppLocalizations.of(context)!.resultsBestMatch,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.resultsBestMatchSub,
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
