import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/errors/app_exceptions.dart';
import 'package:wain_app/core/routing/navigation_extensions.dart';
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
import 'package:wain_app/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:wain_app/features/profile/presentation/providers/settings_providers.dart';
import 'package:wain_app/features/profile/presentation/providers/user_benefit_insights_provider.dart';
import 'package:wain_app/core/providers/location_provider.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/nearby_venues_section.dart';
import 'package:wain_app/shared/widgets/venue_card.dart';

import 'package:wain_app/features/map/presentation/providers/map_providers.dart';
import '../widgets/filter_bottom_sheet.dart';

/// Results screen that shows venue suggestions based on the discovery flow.
///
/// When `discoveryCompleted` is true and the user has no back history,
/// this screen acts as the app's primary landing page — showing a search bar,
/// map action, and compact venue cards.
class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        setState(() => _searchQuery = _searchController.text.trim());
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Whether this screen is acting as the root landing page.
  bool get _isRootLanding {
    final discoveryDone = ref.read(discoveryCompletedProvider);
    return discoveryDone && !GoRouter.of(context).canPop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final searchState = ref.watch(searchProvider);
    final city = ref.watch(cityProvider);
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

    // User location for distance calculation
    final userLocationAsync = ref.watch(userLocationProvider);
    final userLocation = userLocationAsync.when(
      data: (loc) => loc,
      loading: () => null,
      error: (_, _) => null,
    );
    final realUserLocation = userLocation?.isRealLocation == true
        ? userLocation
        : null;

    final recommendationsRequest = recommendationsProvider(
      city: city,
      moodTags: searchState.moodTags,
      occasionTags: searchState.occasionTags,
      timeTags: searchState.timeTags,
      minBudget: searchState.minBudget,
      maxBudget: searchState.maxBudget,
      cuisineTypes: searchState.cuisineTypes,
      sortBy: searchState.sortBy,
      userLat: realUserLocation?.latitude,
      userLng: realUserLocation?.longitude,
    );
    final recommendationsAsync = ref.watch(recommendationsRequest);

    return Scaffold(
      appBar: AppBar(
        leading: _isRootLanding
            ? IconButton(
                onPressed: () => context.push('/profile'),
                icon: const Icon(Icons.person_outline_rounded),
              )
            : IconButton(
                onPressed: () => context.popOrGo('/home'),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
        title: Text(l10n.resultsSuggestions),
        actions: [
          // Map action
          IconButton(
            onPressed: () {
              // Sync discovery filters to map before navigating
              final searchState = ref.read(searchProvider);
              ref
                  .read(mapFilterProvider.notifier)
                  .applyFromSearchState(
                    moodTags: searchState.moodTags,
                    occasionTags: searchState.occasionTags,
                    timeTags: searchState.timeTags,
                    categories: searchState.cuisineTypes,
                    minBudget: searchState.minBudget,
                    maxBudget: searchState.maxBudget,
                    sortBy: searchState.sortBy,
                  );
              context.push('/map');
            },
            icon: const Icon(Icons.map_outlined),
            tooltip: l10n.mapSearchHint,
          ),
          // Filter action with badge
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
      body: Column(
        children: [
          // ── Search Bar ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.mapSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────
          Expanded(
            child: recommendationsAsync.when(
              loading: () => const VenueListSkeleton(count: 5),
              error: (err, _) => AppErrorWidget(
                exception: _asAppException(err),
                onRetry: () => ref.invalidate(recommendationsRequest),
              ),
              data: (venues) {
                // Apply client-side search filter
                final filteredVenues = _searchQuery.isEmpty
                    ? venues
                    : venues
                          .where(
                            (v) =>
                                v.nameAr.contains(_searchQuery) ||
                                v.nameEn.toLowerCase().contains(
                                  _searchQuery.toLowerCase(),
                                ),
                          )
                          .toList();

                if (filteredVenues.isEmpty) {
                  return AppEmptyState.noResults(
                    context,
                    onClearFilters: () {
                      _searchController.clear();
                      searchNotifier.reset(city: city);
                      context.go('/home');
                    },
                  );
                }

                return ListView(
                  padding: AppSpacing.screenPadding,
                  children: [
                    if (user != null && !user.isAnonymous) ...[
                      _buildBenefitsStrip(
                        context,
                        theme,
                        l10n,
                        benefitInsightsAsync,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                    const NearbyVenuesSection(),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildBestMatchHeader(context, theme),
                    const SizedBox(height: AppSpacing.lg),
                    ...List.generate(filteredVenues.length, (index) {
                      final venue = filteredVenues[index];
                      final isFavorite = favorites.contains(venue.id);

                      String? distanceText;
                      if (realUserLocation != null) {
                        final distKm = ref.read(
                          distanceToVenueProvider(
                            venueLat: venue.lat,
                            venueLng: venue.lng,
                            userLat: realUserLocation.latitude,
                            userLng: realUserLocation.longitude,
                          ),
                        );
                        distanceText = formatDistance(distKm, l10n);
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: VenueCard(
                          id: venue.id,
                          name: venue.nameAr,
                          category: venue.categories.isNotEmpty
                              ? venue.categories.first
                              : l10n.categoryGeneral,
                          rating: venue.rating,
                          distance: distanceText,
                          isBestMatch: index == 0,
                          isFavorite: isFavorite,
                          lastStoryAt: venue.lastStoryAt,
                          imageUrl: venue.photos.isNotEmpty
                              ? venue.photos.first
                              : null,
                          compact: true,
                          onTap: () => context.push('/venue/${venue.id}'),
                          onFavoriteToggle: () {
                            ref
                                .read(favoritesListProvider.notifier)
                                .toggle(venue.id);
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
          ),
        ],
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
        child: Column(
          children: [
            Row(
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
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () => context.push('/stats'),
                icon: const Icon(Icons.bar_chart_rounded, size: 18),
                label: Text(l10n.resultsStatsShowMore),
                style: TextButton.styleFrom(
                  textStyle: theme.textTheme.labelMedium,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                ),
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
