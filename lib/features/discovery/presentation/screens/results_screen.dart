import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/errors/app_exceptions.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/widgets/app_button.dart';
import 'package:wain_app/core/widgets/app_empty_state.dart';
import 'package:wain_app/core/widgets/app_error_widget.dart';
import 'package:wain_app/core/widgets/app_skeleton.dart';
import 'package:wain_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:wain_app/features/discovery/presentation/providers/search_state.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wain_app/features/profile/presentation/providers/user_benefit_insights_provider.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/nearby_venues_section.dart';
import 'package:wain_app/shared/widgets/venue_card.dart';

import '../widgets/filter_bottom_sheet.dart';

/// Results screen that shows venue suggestions based on the discovery flow.
class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final searchState = ref.watch(searchProvider);
    final searchNotifier = ref.watch(searchProvider.notifier);
    final authState = ref.watch(authStateProvider);
    final user = authState.asData?.value;
    final benefitInsightsAsync = user != null && !user.isAnonymous
        ? ref.watch(userBenefitInsightsProvider(user.uid))
        : const AsyncValue<UserBenefitInsights>.data(
            UserBenefitInsights.empty(),
          );

    final favoritesAsync = ref.watch(favoritesListProvider);
    final favorites = favoritesAsync.when(
      data: (list) => list,
      loading: () => <String>[],
      error: (_, _) => <String>[],
    );

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
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.resultsSuggestions),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () => showFilterBottomSheet(context),
                  icon: const Icon(Icons.tune_rounded),
                ),
                if (searchNotifier.hasActiveFilters)
                  PositionedDirectional(
                    top: 8,
                    end: 8,
                    child: Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: AppSpacing.radiusFull,
                      ),
                      child: Text(
                        '${searchNotifier.activeFilterCount}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: recommendationsAsync.when(
        loading: () => const VenueListSkeleton(count: 5),
        error: (err, _) => AppErrorWidget(
          exception: _asAppException(err),
          onRetry: () => ref.invalidate(recommendationsRequest),
        ),
        data: (venues) {
          if (venues.isEmpty) {
            return AppEmptyState.noResults(
              context,
              onClearFilters: () {
                searchNotifier.reset(city: searchState.city);
                context.go('/home');
              },
            );
          }

          return ListView(
            padding: AppSpacing.screenPadding,
            children: [
              if (user != null && !user.isAnonymous) ...[
                _buildBenefitsStrip(context, theme, l10n, benefitInsightsAsync),
                const SizedBox(height: AppSpacing.xl),
              ],
              const NearbyVenuesSection(),
              const SizedBox(height: AppSpacing.xxl),
              _buildBestMatchHeader(context, theme),
              const SizedBox(height: AppSpacing.lg),
              ...List.generate(venues.length, (index) {
                final venue = venues[index];
                final isFavorite = favorites.contains(venue.id);

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: VenueCard(
                    id: venue.id,
                    name: venue.nameAr,
                    category: venue.categories.isNotEmpty
                        ? venue.categories.first
                        : l10n.categoryGeneral,
                    rating: venue.rating,
                    distance: '0.0 km',
                    isBestMatch: index == 0,
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
              const SizedBox(height: AppSpacing.md),
              AppButton.secondary(
                label: l10n.resultsChangeChoices,
                onPressed: () => context.go('/home'),
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

  Widget _buildBestMatchHeader(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppTheme.primarySurfaceColor,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: AppShadows.elevated,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: AppSpacing.radiusMd,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: theme.colorScheme.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.resultsBestMatch,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.resultsBestMatchSub,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsStrip(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    AsyncValue<UserBenefitInsights> insightsAsync,
  ) {
    return insightsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (insights) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppSpacing.radiusLg,
          border: Border.all(color: theme.colorScheme.outline),
          boxShadow: AppShadows.elevated,
        ),
        child: Row(
          children: [
            Expanded(
              child: _BenefitMetric(
                icon: Icons.savings_outlined,
                label: l10n.statsConfirmedSavings,
                value: insights.formattedSavings(),
                accent: AppTheme.successColor,
              ),
            ),
            Container(
              width: 1,
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              color: theme.colorScheme.outline,
            ),
            Expanded(
              child: _BenefitMetric(
                icon: Icons.local_offer_rounded,
                label: l10n.statsUsedOffers,
                value: '${insights.redeemedClaims}',
                accent: AppTheme.warningColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _BenefitMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accent.withAlpha(18),
            borderRadius: AppSpacing.radiusMd,
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(value, style: theme.textTheme.titleLarge),
            ],
          ),
        ),
      ],
    );
  }
}
