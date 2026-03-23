import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/widgets/app_button.dart';
import 'package:wain_app/core/widgets/app_empty_state.dart';
import 'package:wain_app/core/widgets/app_skeleton.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/venue_card.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

import '../providers/try_list_provider.dart';

class TryListScreen extends ConsumerWidget {
  const TryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tryListAsync = ref.watch(tryListNotifierProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.tryListTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: tryListAsync.when(
        loading: () => const Center(child: WainLoadingIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              l10n.tryListError(err.toString()),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (venueIds) {
          if (venueIds.isEmpty) {
            return _TryListEmptyState(onExplore: () => context.go('/home'));
          }

          return ListView.separated(
            padding: AppSpacing.screenPadding,
            itemCount: venueIds.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final venueId = venueIds[index];
              final venueAsync = ref.watch(venueByIdProvider(venueId));

              return venueAsync.when(
                loading: () => const VenueCardSkeleton(),
                error: (_, _) => const SizedBox.shrink(),
                data: (venue) {
                  if (venue == null) {
                    return const SizedBox.shrink();
                  }

                  return Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: VenueCard(
                          id: venue.id,
                          name: venue.nameAr,
                          category: venue.categories.isNotEmpty
                              ? venue.categories.first
                              : l10n.categoryGeneral,
                          rating: venue.rating,
                          distance: '0.0 km',
                          isFavorite: false,
                          lastStoryAt: venue.lastStoryAt,
                          imageUrl: venue.photos.isNotEmpty
                              ? venue.photos.first
                              : null,
                          onTap: () => context.push('/venue/${venue.id}'),
                          onFavoriteToggle: () {
                            ref
                                .read(favoritesListProvider.notifier)
                                .add(venueId);
                            ref
                                .read(tryListNotifierProvider.notifier)
                                .remove(venueId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.tryListMovedToFav(venue.nameAr),
                                ),
                                action: SnackBarAction(
                                  label: l10n.tryListUndo,
                                  onPressed: () {
                                    ref
                                        .read(tryListNotifierProvider.notifier)
                                        .add(venueId);
                                    ref
                                        .read(favoritesListProvider.notifier)
                                        .remove(venueId);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      PositionedDirectional(
                        top: 0,
                        start: AppSpacing.sm,
                        child: _QuickActionChip(
                          icon: Icons.close_rounded,
                          label: '',
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onSurface,
                          borderColor: Theme.of(context).colorScheme.outline,
                          onTap: () {
                            ref
                                .read(tryListNotifierProvider.notifier)
                                .remove(venueId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.tryListRemoved(venue.nameAr),
                                ),
                                action: SnackBarAction(
                                  label: l10n.tryListUndo,
                                  onPressed: () {
                                    ref
                                        .read(tryListNotifierProvider.notifier)
                                        .add(venueId);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      PositionedDirectional(
                        top: 0,
                        end: AppSpacing.sm,
                        child: _QuickActionChip(
                          icon: Icons.check_circle_rounded,
                          label: l10n.tryListTriedItBtn,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          borderColor: Colors.transparent,
                          onTap: () {
                            ref
                                .read(favoritesListProvider.notifier)
                                .add(venueId);
                            ref
                                .read(tryListNotifierProvider.notifier)
                                .remove(venueId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.tryListTriedIt(venue.nameAr),
                                ),
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
        },
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.tryListInfoTitle),
        content: Text(l10n.tryListInfoBody),
        actions: [
          AppButton.tertiary(
            label: l10n.tryListInfoDismiss,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _TryListEmptyState extends StatelessWidget {
  final VoidCallback onExplore;

  const _TryListEmptyState({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppEmptyState(
          icon: Icons.explore_outlined,
          message: '${l10n.tryListEmptyTitle}\n\n${l10n.tryListEmptySubtitle}',
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton.primary(
          label: l10n.tryListExploreBtn,
          onPressed: onExplore,
          icon: const Icon(Icons.explore_rounded, size: 18),
          expanded: false,
        ),
      ],
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppSpacing.radiusFull,
        border: Border.all(color: borderColor),
        boxShadow: AppShadows.elevated,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppSpacing.radiusFull,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: label.isEmpty ? AppSpacing.sm : AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: foregroundColor),
                if (label.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    label,
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: foregroundColor),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
