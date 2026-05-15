import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/errors/app_exceptions.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/widgets/app_empty_state.dart';
import 'package:wain_app/core/widgets/app_error_widget.dart';
import 'package:wain_app/core/widgets/app_skeleton.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/venue_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesListProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.favoritesTitle),
        automaticallyImplyLeading: false,
      ),
      body: favoritesAsync.when(
        loading: () => const VenueListSkeleton(count: 3),
        error: (error, _) => AppErrorWidget(
          exception: _asAppException(error),
          onRetry: () => ref.invalidate(favoritesListProvider),
        ),
        data: (favoriteIds) {
          if (favoriteIds.isEmpty) {
            return AppEmptyState.noFavorites(
              context,
              onExplore: () => context.go('/results'),
            );
          }

          return ListView.separated(
            padding: AppSpacing.screenPadding,
            itemCount: favoriteIds.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final venueId = favoriteIds[index];
              final venueAsync = ref.watch(venueByIdProvider(venueId));

              return venueAsync.when(
                loading: () => const VenueCardSkeleton(),
                error: (_, _) => const SizedBox.shrink(),
                data: (venue) {
                  if (venue == null) {
                    return const SizedBox.shrink();
                  }

                  return VenueCard(
                    id: venue.id,
                    name: venue.nameAr,
                    category: venue.categories.isNotEmpty
                        ? venue.categories.first
                        : l10n.categoryGeneral,
                    rating: venue.rating,
                    distance: '0.0 km',
                    isFavorite: true,
                    lastStoryAt: venue.lastStoryAt,
                    imageUrl: venue.photos.isNotEmpty
                        ? venue.photos.first
                        : null,
                    onTap: () => context.push('/venue/${venue.id}'),
                    onFavoriteToggle: () {
                      ref.read(favoritesListProvider.notifier).remove(venueId);
                    },
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
    if (error is AppException) {
      return error;
    }
    return ServerException(message: error.toString());
  }
}
