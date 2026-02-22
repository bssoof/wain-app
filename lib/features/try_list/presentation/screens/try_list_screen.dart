import 'package:flutter/material.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/shared/widgets/venue_card.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';
import '../providers/try_list_provider.dart';

/// Try List Screen — "أماكن بدي أجرّب"
/// Venues the user wants to visit but hasn't tried yet
class TryListScreen extends ConsumerWidget {
  const TryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tryListAsync = ref.watch(tryListNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(AppLocalizations.of(context)!.tryListTitle),
        actions: [
          // Info tooltip
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: tryListAsync.when(
        loading: () => const Center(child: WainLoadingIndicator()),
        error: (err, stack) => Center(child: Text(AppLocalizations.of(context)!.tryListError(err.toString()))),
        data: (venueIds) {
          if (venueIds.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: venueIds.length,
            itemBuilder: (context, index) {
              final venueId = venueIds[index];
              final venueAsync = ref.watch(venueByIdProvider(venueId));

              return venueAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: SizedBox(
                      height: 200,
                      child: Center(child: WainLoadingIndicator()),
                    ),
                  ),
                ),
                error: (_, _) => const SizedBox.shrink(),
                data: (venue) {
                  if (venue == null) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Stack(
                      children: [
                        VenueCard(
                          id: venue.id,
                          name: venue.nameAr,
                          category: venue.categories.isNotEmpty
                              ? venue.categories.first
                              : AppLocalizations.of(context)!.categoryGeneral,
                          rating: venue.rating,
                          distance: '0.0 km',
                          isFavorite: false,
                          lastStoryAt: venue.lastStoryAt,
                          imageUrl: venue.photos.isNotEmpty ? venue.photos.first : null,
                          onTap: () => context.push('/venue/${venue.id}'),
                          onFavoriteToggle: () {
                            // Move to favorites
                            ref
                                .read(favoritesListProvider.notifier)
                                .add(venueId);
                            ref
                                .read(tryListNotifierProvider.notifier)
                                .remove(venueId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    AppLocalizations.of(context)!.tryListMovedToFav(venue.nameAr)),
                                backgroundColor: AppTheme.successColor,
                                action: SnackBarAction(
                                  label: AppLocalizations.of(context)!.tryListUndo,
                                  textColor: Colors.white,
                                  onPressed: () {
                                    ref
                                        .read(
                                            tryListNotifierProvider.notifier)
                                        .add(venueId);
                                    ref
                                        .read(
                                            favoritesListProvider.notifier)
                                        .remove(venueId);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        // Remove from try list button
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Material(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                ref
                                    .read(tryListNotifierProvider.notifier)
                                    .remove(venueId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        AppLocalizations.of(context)!.tryListRemoved(venue.nameAr)),
                                    action: SnackBarAction(
                                      label: AppLocalizations.of(context)!.tryListUndo,
                                      textColor: Colors.white,
                                      onPressed: () {
                                        ref
                                            .read(tryListNotifierProvider
                                                .notifier)
                                            .add(venueId);
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.close,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ),
                        // "Tried it" badge
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                // Move to favorites (tried it!)
                                ref
                                    .read(favoritesListProvider.notifier)
                                    .add(venueId);
                                ref
                                    .read(tryListNotifierProvider.notifier)
                                    .remove(venueId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        AppLocalizations.of(context)!.tryListTriedIt(venue.nameAr)),
                                    backgroundColor: AppTheme.successColor,
                                  ),
                                );
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.white, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      AppLocalizations.of(context)!.tryListTriedItBtn,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.explore_outlined,
                size: 50,
                color: AppTheme.primaryColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.tryListEmptyTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.tryListEmptySubtitle,
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
              label: Text(AppLocalizations.of(context)!.tryListExploreBtn),
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

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.tryListInfoTitle),
        content: Text(
          AppLocalizations.of(context)!.tryListInfoBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.tryListInfoDismiss),
          ),
        ],
      ),
    );
  }
}
