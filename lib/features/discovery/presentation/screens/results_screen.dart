import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/errors/app_exceptions.dart';
import 'package:wain_app/core/routing/navigation_extensions.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/widgets/app_button.dart';
import 'package:wain_app/core/widgets/app_empty_state.dart';
import 'package:wain_app/core/widgets/app_error_widget.dart';
import 'package:wain_app/core/widgets/app_skeleton.dart';
import 'package:wain_app/features/discovery/presentation/providers/search_state.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wain_app/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:wain_app/features/profile/presentation/providers/settings_providers.dart';
import 'package:wain_app/features/stories/presentation/widgets/stories_bar.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/core/providers/location_provider.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/nearby_venues_section.dart';
import 'package:wain_app/shared/widgets/venue_card.dart';

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
  static const double _controlsToggleScrollThreshold = 18;

  String _searchQuery = '';
  bool _showDiscoveryControls = true;
  double _controlsScrollDelta = 0;

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
    final allVenuesState = ref.watch(cachedVenuesProvider(city: city));
    final isSearching = _searchQuery.isNotEmpty;

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
            ? null
            : IconButton(
                onPressed: () => context.popOrGo('/home'),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
        title: Text(l10n.resultsSuggestions),
      ),
      body: Column(
        children: [
          _buildCollapsibleDiscoveryControls(
            context,
            theme,
            l10n,
            searchState,
          ),

          // ── Body ────────────────────────────────────────
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: _handleResultsScroll,
              child: recommendationsAsync.when(
                loading: () => const VenueListSkeleton(count: 5),
                error: (err, _) => AppErrorWidget(
                  exception: _asAppException(err),
                  onRetry: () => ref.invalidate(recommendationsRequest),
                ),
                data: (venues) {
                  final hasVenueLoadError =
                      allVenuesState.error != null &&
                      allVenuesState.venues.isEmpty;

                  if (hasVenueLoadError) {
                    return AppErrorWidget(
                      exception: const ServerException(),
                      onRetry: () {
                        ref
                            .read(cachedVenuesProvider(city: city).notifier)
                            .refresh();
                        ref.invalidate(recommendationsRequest);
                      },
                    );
                  }

                  if (allVenuesState.isLoading &&
                      allVenuesState.venues.isEmpty) {
                    return const VenueListSkeleton(count: 5);
                  }

                  // Search is intentionally strict and city-wide: when the user
                  // searches for a place, do not mix in nearby/recommendation
                  // sections that can make the result feel unrelated.
                  final filteredVenues = isSearching
                      ? allVenuesState.venues
                            .where((venue) => _matchesVenueSearch(venue))
                            .toList()
                      : venues;

                  if (filteredVenues.isEmpty) {
                    return AppEmptyState.noResults(
                      context,
                      onClearFilters: () {
                        _searchController.clear();
                        if (!isSearching) {
                          searchNotifier.reset(city: city);
                          context.go('/home');
                        }
                      },
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.sm,
                      AppSpacing.xl,
                      AppSpacing.xl,
                    ),
                    children: [
                      if (!isSearching) ...[
                        const NearbyVenuesSection(),
                        const SizedBox(height: AppSpacing.xxl),
                        _buildBestMatchHeader(context, theme),
                        const SizedBox(height: AppSpacing.lg),
                      ],
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
                      if (!isSearching) ...[
                        const SizedBox(height: AppSpacing.md),
                        AppButton.secondary(
                          label: l10n.resultsChangeChoices,
                          onPressed: () => context.go('/home'),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _matchesVenueSearch(Venue venue) {
    final query = _normalizeSearch(_searchQuery);
    if (query.isEmpty) return true;

    return _normalizeSearch(venue.nameAr).contains(query) ||
        _normalizeSearch(venue.nameEn).contains(query) ||
        _normalizeSearch(venue.nameArNorm).contains(query) ||
        _normalizeSearch(venue.nameEnNorm).contains(query);
  }

  String _normalizeSearch(String value) => value.trim().toLowerCase();

  AppException _asAppException(Object error) {
    if (error is AppException) return error;
    return ServerException(message: error.toString());
  }

  bool _handleResultsScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification.metrics.maxScrollExtent <=
        notification.metrics.minScrollExtent) {
      return false;
    }

    if (notification.metrics.pixels <=
        notification.metrics.minScrollExtent + AppSpacing.sm) {
      _setDiscoveryControlsVisible(true);
      return false;
    }

    if (notification is! ScrollUpdateNotification) return false;

    final delta = notification.scrollDelta ?? 0;
    if (delta == 0) return false;

    if (delta > 0) {
      _controlsScrollDelta = _controlsScrollDelta < 0
          ? delta
          : _controlsScrollDelta + delta;
      if (_controlsScrollDelta >= _controlsToggleScrollThreshold) {
        _setDiscoveryControlsVisible(false);
      }
    } else {
      _controlsScrollDelta = _controlsScrollDelta > 0
          ? delta
          : _controlsScrollDelta + delta;
      if (_controlsScrollDelta <= -_controlsToggleScrollThreshold) {
        _setDiscoveryControlsVisible(true);
      }
    }

    return false;
  }

  void _setDiscoveryControlsVisible(bool visible) {
    if (_showDiscoveryControls == visible) return;
    _controlsScrollDelta = 0;
    if (mounted) {
      setState(() => _showDiscoveryControls = visible);
    }
  }

  Widget _buildCollapsibleDiscoveryControls(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    SearchState searchState,
  ) {
    return ClipRect(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: _showDiscoveryControls
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: _buildFilterDropdownBar(
                      context,
                      theme,
                      l10n,
                      searchState,
                    ),
                  ),
                  // ── Search + promoted stories rail ───────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      0,
                    ),
                    child: _buildSearchStoriesRail(context, theme, l10n),
                  ),
                ],
              )
            : const SizedBox(width: double.infinity),
      ),
    );
  }

  Widget _buildSearchStoriesRail(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return SizedBox(
      height: 90,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CompactSearchButton(
            isActive: _searchQuery.isNotEmpty,
            onTap: () => _showSearchSheet(context, l10n),
            onClear: _searchQuery.isEmpty ? null : _searchController.clear,
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            width: 1,
            height: 64,
            margin: const EdgeInsets.only(top: 4),
            color: theme.colorScheme.outlineVariant,
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(child: CompactPromotedStoriesStrip()),
        ],
      ),
    );
  }

  Future<void> _showSearchSheet(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final sheetController = TextEditingController(text: _searchController.text);

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) {
          final theme = Theme.of(sheetContext);
          return Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              bottom:
                  MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.xl,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.mapSearchHint,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: sheetController,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: l10n.mapSearchHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                    ),
                    onSubmitted: (_) {
                      _applySearchQuery(sheetController.text);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                          },
                          child: Text(l10n.cancel),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            _applySearchQuery(sheetController.text);
                            Navigator.of(sheetContext).pop();
                          },
                          child: Text(l10n.filterApply),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    } finally {
      sheetController.dispose();
    }
  }

  void _applySearchQuery(String value) {
    _searchController.text = value.trim();
  }

  Widget _buildFilterDropdownBar(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    SearchState searchState,
  ) {
    final destinationSelection = _selectedOptions(
      searchState.occasionTags,
      _destinationOptions(l10n),
    );
    final companionSelection = _selectedOptions(
      searchState.occasionTags,
      _companionOptions(l10n),
    );
    final moodSelection = _selectedOptions(
      searchState.moodTags,
      _moodOptions(l10n),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _DropdownFilterChip(
            label: _selectionLabel(
              l10n.filterDestination,
              destinationSelection,
            ),
            icon: Icons.place_outlined,
            isActive: destinationSelection.isNotEmpty,
            onTap: _showDestinationFilterSheet,
          ),
          const SizedBox(width: AppSpacing.sm),
          _DropdownFilterChip(
            label: _selectionLabel(l10n.filterMood, moodSelection),
            icon: Icons.auto_awesome_rounded,
            isActive: moodSelection.isNotEmpty,
            onTap: _showMoodFilterSheet,
          ),
          const SizedBox(width: AppSpacing.sm),
          _DropdownFilterChip(
            label: _selectionLabel(l10n.filterCompanion, companionSelection),
            icon: Icons.group_outlined,
            isActive: companionSelection.isNotEmpty,
            onTap: _showCompanionFilterSheet,
          ),
          const SizedBox(width: AppSpacing.sm),
          _DropdownFilterChip(
            label: l10n.filterTitle,
            icon: Icons.tune_rounded,
            isActive:
                searchState.minBudget != 30 ||
                searchState.maxBudget != 200 ||
                searchState.sortBy != SortBy.rating ||
                searchState.cuisineTypes.isNotEmpty ||
                searchState.timeTags.isNotEmpty,
            onTap: () => showFilterBottomSheet(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showDestinationFilterSheet() {
    final l10n = AppLocalizations.of(context)!;
    final options = _destinationOptions(l10n);
    return _showMultiSelectSheet(
      title: l10n.filterDestination,
      initialValues: _selectedOptionIds(
        ref.read(searchProvider).occasionTags,
        options,
      ),
      options: options,
      onApply: (values) => _setOccasionGroup(values, options),
    );
  }

  Future<void> _showMoodFilterSheet() {
    final l10n = AppLocalizations.of(context)!;
    final options = _moodOptions(l10n);
    return _showMultiSelectSheet(
      title: l10n.filterMood,
      initialValues: ref.read(searchProvider).moodTags,
      options: options,
      onApply: (values) => ref.read(searchProvider.notifier).setMoods(values),
    );
  }

  Future<void> _showCompanionFilterSheet() {
    final l10n = AppLocalizations.of(context)!;
    final options = _companionOptions(l10n);
    return _showMultiSelectSheet(
      title: l10n.filterCompanion,
      initialValues: _selectedOptionIds(
        ref.read(searchProvider).occasionTags,
        options,
      ),
      options: options,
      onApply: (values) => _setOccasionGroup(values, options),
    );
  }

  void _setOccasionGroup(
    List<String> selectedValues,
    List<_FilterOption> groupOptions,
  ) {
    final groupIds = groupOptions.map((option) => option.id).toSet();
    final current = ref.read(searchProvider).occasionTags;
    final next = [
      ...current.where((id) => !groupIds.contains(id)),
      ...selectedValues,
    ];
    ref.read(searchProvider.notifier).setOccasions(next);
  }

  Future<void> _showMultiSelectSheet({
    required String title,
    required List<String> initialValues,
    required List<_FilterOption> options,
    required ValueChanged<List<String>> onApply,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final selectedValues = Set<String>.from(initialValues);

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: options.map((option) {
                    final isSelected = selectedValues.contains(option.id);
                    return FilterChip(
                      label: Text(option.label),
                      selected: isSelected,
                      onSelected: (selected) {
                        setSheetState(() {
                          if (selected) {
                            selectedValues.add(option.id);
                          } else {
                            selectedValues.remove(option.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      onApply(selectedValues.toList());
                      Navigator.of(sheetContext).pop();
                    },
                    child: Text(l10n.filterApply),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_FilterOption> _destinationOptions(AppLocalizations l10n) => [
    _FilterOption('birthday', l10n.optionBirthday),
    _FilterOption('anniversary', l10n.optionAnniversary),
    _FilterOption('meeting', l10n.optionMeeting),
    _FilterOption('fast_food', l10n.optionFastFood),
    _FilterOption('solo_time', l10n.optionSoloTime),
  ];

  List<_FilterOption> _moodOptions(AppLocalizations l10n) => [
    _FilterOption('outdoor', l10n.optionOutdoor),
    _FilterOption('couples', l10n.optionCouples),
    _FilterOption('family', l10n.optionFamily),
    _FilterOption('work', l10n.optionWork),
    _FilterOption('chill', l10n.optionChill),
    _FilterOption('fun', l10n.optionFun),
  ];

  List<_FilterOption> _companionOptions(AppLocalizations l10n) => [
    _FilterOption('friends', l10n.optionFriends),
    _FilterOption('partner', l10n.optionPartner),
    _FilterOption('family_kids', l10n.optionFamilyKids),
    _FilterOption('solo', l10n.optionSolo),
    _FilterOption('business', l10n.optionBusiness),
  ];

  List<_FilterOption> _selectedOptions(
    List<String> selectedIds,
    List<_FilterOption> options,
  ) {
    final selected = selectedIds.toSet();
    return options.where((option) => selected.contains(option.id)).toList();
  }

  List<String> _selectedOptionIds(
    List<String> selectedIds,
    List<_FilterOption> options,
  ) {
    return _selectedOptions(
      selectedIds,
      options,
    ).map((option) => option.id).toList();
  }

  String _selectionLabel(String fallback, List<_FilterOption> selected) {
    if (selected.isEmpty) return fallback;
    if (selected.length == 1) return selected.first.label;
    return '$fallback (${selected.length})';
  }

  Widget _buildBestMatchHeader(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.resultsBestMatch,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.resultsBestMatchSub, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _CompactSearchButton extends StatelessWidget {
  const _CompactSearchButton({
    required this.isActive,
    required this.onTap,
    required this.onClear,
  });

  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = isActive
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;
    final background = isActive
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surface;

    return SizedBox(
      width: 56,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Material(
              color: background,
              borderRadius: AppSpacing.radiusFull,
              elevation: 0,
              child: InkWell(
                borderRadius: AppSpacing.radiusFull,
                onTap: onTap,
                child: Icon(Icons.search_rounded, color: foreground, size: 30),
              ),
            ),
          ),
          if (onClear != null)
            PositionedDirectional(
              top: -4,
              start: -4,
              child: Material(
                color: theme.colorScheme.errorContainer,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onClear,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DropdownFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _DropdownFilterChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = isActive
        ? theme.colorScheme.primary.withAlpha(24)
        : theme.colorScheme.surface;
    final foreground = isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      borderRadius: AppSpacing.radiusFull,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 34),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppSpacing.radiusFull,
          border: Border.all(
            color: isActive
                ? theme.colorScheme.primary.withAlpha(120)
                : theme.colorScheme.outline.withAlpha(85),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: foreground,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterOption {
  final String id;
  final String label;

  const _FilterOption(this.id, this.label);
}
