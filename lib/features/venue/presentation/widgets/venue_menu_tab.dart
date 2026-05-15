import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/services/analytics_service.dart';
import 'package:wain_app/features/menu/domain/entities/menu_item.dart';
import 'package:wain_app/features/menu/domain/entities/menu_section.dart';
import 'package:wain_app/features/menu/presentation/providers/menu_providers.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_menu_item_details_sheet.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_menu_section.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_ui_constants.dart';

final RegExp _categoryNonWordRegex = RegExp(r'[^a-z0-9_]+');
final RegExp _categoryMultiUnderscoreRegex = RegExp(r'_+');
final RegExp _categoryTrimUnderscoreRegex = RegExp(r'^_|_$');
const Duration _menuNoInteractionTimeout = Duration(seconds: 10);
const String _menuAnalyticsSourceFullMenu = 'full_menu';

class VenueMenuTab extends ConsumerStatefulWidget {
  final Venue venue;

  const VenueMenuTab({super.key, required this.venue});

  @override
  ConsumerState<VenueMenuTab> createState() => _VenueMenuTabState();
}

class _VenueMenuTabState extends ConsumerState<VenueMenuTab> {
  final ScrollController _menuScrollController = ScrollController();
  final TextEditingController _menuSearchController = TextEditingController();
  final GlobalKey _menuTopAnchorKey = GlobalKey();
  final Map<String, GlobalKey> _menuSectionKeys = {};
  final ValueNotifier<String> _selectedCategoryNotifier = ValueNotifier('all');
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier('');
  final List<String> _visibleSectionIds = <String>[];
  final Map<String, double> _measuredSectionOffsets = <String, double>{};
  final Set<String> _expandedSectionIds = <String>{};
  final Map<String, List<MenuItem>> _visibleSectionItemsById =
      <String, List<MenuItem>>{};

  Timer? _menuSearchDebounce;
  Timer? _programmaticScrollResetTimer;
  Timer? _menuNoInteractionTimer;
  bool _isProgrammaticMenuScroll = false;
  bool _pendingScrollSync = false;
  bool _scrollSyncEnabled = false;
  bool _hasMenuInteraction = false;
  double? _menuListStartOffset;
  String? _lastMenuViewAnalyticsKey;
  String _visibleSectionSignature = '';

  // Cached computed data — only recomputed when items change
  Map<String, String>? _cachedSearchableText;
  int _lastItemsHash = 0;

  @override
  void initState() {
    super.initState();
    _menuScrollController.addListener(_onMenuScrollPositionChanged);
  }

  @override
  void dispose() {
    _menuSearchDebounce?.cancel();
    _programmaticScrollResetTimer?.cancel();
    _menuNoInteractionTimer?.cancel();
    _menuScrollController
      ..removeListener(_onMenuScrollPositionChanged)
      ..dispose();
    _menuSearchController.dispose();
    _selectedCategoryNotifier.dispose();
    _searchQueryNotifier.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant VenueMenuTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.venue.id != widget.venue.id) {
      _resetMenuAnalyticsSession(clearViewKey: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onMenuScrollNotification,
      child: ValueListenableBuilder<String>(
        valueListenable: _searchQueryNotifier,
        builder: (context, _, child) {
          return CustomScrollView(
            controller: _menuScrollController,
            key: const PageStorageKey<String>('menu_tab'),
            slivers: [
              ..._buildMenuSlivers(widget.venue),
              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildMenuSlivers(Venue venue) {
    final l10n = AppLocalizations.of(context)!;
    final venueCategory = venue.categories.isNotEmpty
        ? venue.categories.first
        : 'restaurant';
    final menuAsync = ref.watch(menuItemsProvider(venue.id));
    final defaultSections = ref.watch(menuSectionsProvider(venueCategory));
    final sectionsAsync = ref.watch(
      menuActiveSectionsProvider(
        MenuActiveSectionsQuery(
          venueId: venue.id,
          venueCategory: venueCategory,
        ),
      ),
    );

    return menuAsync.when(
      loading: () {
        _scrollSyncEnabled = false;
        return [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                kVenueHorizontalPadding,
                24,
                kVenueHorizontalPadding,
                0,
              ),
              child: VenueMenuLoadingSkeleton(),
            ),
          ),
        ];
      },
      error: (error, stackTrace) {
        _scrollSyncEnabled = false;
        return _buildMenuImageFallbackSlivers(
          venue,
          message: l10n.menuLoadFailed,
          isError: true,
        );
      },
      data: (items) {
        final sections = sectionsAsync.asData?.value ?? defaultSections;
        final availableItems = items.where((i) => i.isAvailable).toList();
        if (availableItems.isEmpty) {
          _scrollSyncEnabled = false;
          return _buildMenuImageFallbackSlivers(venue);
        }
        // Cache searchableTextMap — recompute when item content changes
        final itemsHash = Object.hashAll(
          availableItems.map(
            (i) => '${i.id}:${i.nameAr}:${i.nameEn}:${i.descriptionAr}',
          ),
        );
        if (itemsHash != _lastItemsHash || _cachedSearchableText == null) {
          _lastItemsHash = itemsHash;
          _cachedSearchableText = _buildSearchableTextMap(availableItems);
        }
        final searchableTextByItemId = _cachedSearchableText!;
        final normalizedQuery = _normalizeMenuQuery(_searchQueryNotifier.value);
        final featuredCount = availableItems
            .where((item) => item.isFeatured)
            .length;
        final featuredItems = selectVenueFeaturedMenuItems(
          availableItems,
          limit: kVenueFeaturedFullMenuLimit,
        );
        final shouldShowFeaturedStrip =
            normalizedQuery.isEmpty &&
            featuredItems.length >= kVenueFeaturedFullMenuMinItems;

        final groupedBySection = <String, List<MenuItem>>{};
        for (final item in availableItems) {
          groupedBySection.putIfAbsent(item.category, () => []).add(item);
        }
        for (final sectionItems in groupedBySection.values) {
          sectionItems.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        }
        final normalizedItemsBySection = <String, List<MenuItem>>{};
        final firstRawCategoryByNormalized = <String, String>{};
        for (final entry in groupedBySection.entries) {
          final normalizedSectionId = _normalizeCategoryKey(entry.key);
          firstRawCategoryByNormalized.putIfAbsent(
            normalizedSectionId,
            () => entry.key,
          );
          normalizedItemsBySection
              .putIfAbsent(normalizedSectionId, () => <MenuItem>[])
              .addAll(entry.value);
        }
        for (final sectionItems in normalizedItemsBySection.values) {
          sectionItems.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        }

        final normalizedIdsFromSections = <String>{
          for (final section in sections) _normalizeCategoryKey(section.id),
        };

        final activeSections = <MenuSection>[];
        for (final section in sections) {
          final normalizedSectionId = _normalizeCategoryKey(section.id);
          if (normalizedItemsBySection.containsKey(normalizedSectionId)) {
            activeSections.add(section);
          }
        }

        final unmatchedCategoryIds =
            normalizedItemsBySection.keys
                .where((id) => !normalizedIdsFromSections.contains(id))
                .toList()
              ..sort();

        for (var i = 0; i < unmatchedCategoryIds.length; i += 1) {
          final normalizedCategoryId = unmatchedCategoryIds[i];
          final categoryId =
              firstRawCategoryByNormalized[normalizedCategoryId] ??
              normalizedCategoryId;
          final fallbackName = _humanizeCategoryId(categoryId, l10n);
          activeSections.add(
            MenuSection(
              id: categoryId,
              nameAr: fallbackName,
              nameEn: fallbackName,
              icon: 'restaurant_menu',
              sortOrder: 1000 + i,
            ),
          );
        }

        activeSections.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        if (activeSections.isEmpty) {
          _scrollSyncEnabled = false;
          return _buildMenuImageFallbackSlivers(venue);
        }
        _logMenuViewIfNeeded(
          venueId: venue.id,
          menuMode: 'structured',
          itemCount: availableItems.length,
          sectionCount: activeSections.length,
          featuredCount: featuredCount,
          imageCount: venue.menuImages.length,
        );
        _scrollSyncEnabled = activeSections.isNotEmpty;

        final sectionItemCounts = <String, int>{};
        for (final section in activeSections) {
          final nid = _normalizeCategoryKey(section.id);
          sectionItemCounts[section.id] =
              normalizedItemsBySection[nid]?.length ?? 0;
        }

        final filteredSections = <_MenuSectionGroup>[];
        for (final section in activeSections) {
          final nid = _normalizeCategoryKey(section.id);
          final sorted = normalizedItemsBySection[nid];
          if (sorted == null || sorted.isEmpty) continue;
          final filtered = sorted
              .where(
                (item) => _matchesNormalizedMenuQuery(
                  item: item,
                  normalizedQuery: normalizedQuery,
                  searchableTextByItemId: searchableTextByItemId,
                ),
              )
              .toList();
          if (filtered.isEmpty) continue;
          _menuSectionKeys.putIfAbsent(section.id, () => GlobalKey());
          filteredSections.add(
            _MenuSectionGroup(section: section, items: filtered),
          );
        }
        final activeSectionIds = filteredSections
            .map((g) => g.section.id)
            .toSet();
        _updateVisibleSectionSignature(
          filteredSections,
          shouldShowFeaturedStrip: shouldShowFeaturedStrip,
          normalizedQuery: normalizedQuery,
        );
        _visibleSectionIds
          ..clear()
          ..addAll(filteredSections.map((g) => g.section.id));
        _visibleSectionItemsById
          ..clear()
          ..addEntries(
            filteredSections.map(
              (g) => MapEntry<String, List<MenuItem>>(g.section.id, g.items),
            ),
          );
        _menuSectionKeys.removeWhere(
          (sectionId, _) => !activeSectionIds.contains(sectionId),
        );

        final slivers = <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              key: _menuTopAnchorKey,
              padding: const EdgeInsets.fromLTRB(
                kVenueHorizontalPadding,
                18,
                kVenueHorizontalPadding,
                8,
              ),
              child: VenueMenuSearchField(
                controller: _menuSearchController,
                onChanged: _onMenuSearchChanged,
                countLabel: '${availableItems.length} ${l10n.menuItemCounter}',
                onClear: _menuSearchController.text.isEmpty
                    ? null
                    : () {
                        _menuSearchController.clear();
                        _onMenuSearchChanged('');
                      },
              ),
            ),
          ),
        ];

        if (activeSections.isNotEmpty) {
          slivers.add(
            SliverPersistentHeader(
              pinned: true,
              delegate: PinnedMenuHeaderDelegate(
                height: kVenueMenuPinnedHeaderHeight,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  padding: const EdgeInsets.fromLTRB(
                    kVenueHorizontalPadding,
                    4,
                    kVenueHorizontalPadding,
                    8,
                  ),
                  alignment: Alignment.centerLeft,
                  child: ValueListenableBuilder<String>(
                    valueListenable: _selectedCategoryNotifier,
                    builder: (context, selectedId, _) {
                      final effectiveId =
                          activeSections.any((s) => s.id == selectedId)
                          ? selectedId
                          : 'all';
                      return VenueMenuCategoryChips(
                        sections: activeSections,
                        selectedSectionId: effectiveId,
                        onSelected: _onMenuSectionSelected,
                        totalCount: availableItems.length,
                        sectionItemCounts: sectionItemCounts,
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        }

        if (shouldShowFeaturedStrip) {
          slivers.add(
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  kVenueHorizontalPadding,
                  8,
                  kVenueHorizontalPadding,
                  8,
                ),
                child: VenueFeaturedItemsRow(
                  items: featuredItems,
                  onItemTap: (item) => _showMenuItemDetailsSheet(
                    item,
                    surface: 'featured_strip',
                  ),
                ),
              ),
            ),
          );
        }

        if (filteredSections.isEmpty) {
          slivers.add(
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  kVenueHorizontalPadding,
                  8,
                  kVenueHorizontalPadding,
                  0,
                ),
                child: AnimatedSwitcher(
                  duration: kVenueUiMotionDuration,
                  child: VenueMenuEmptyState(
                    key: ValueKey<String>('empty_menu:$normalizedQuery'),
                    message: l10n.menuNoMatchingResults,
                  ),
                ),
              ),
            ),
          );
        } else {
          slivers.add(
            ValueListenableBuilder<String>(
              valueListenable: _selectedCategoryNotifier,
              builder: (context, selectedSectionId, child) {
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    kVenueHorizontalPadding,
                    8,
                    kVenueHorizontalPadding,
                    0,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final group = filteredSections[index];
                      return VenueMenuSectionBlock(
                        key: _menuSectionKeys[group.section.id],
                        section: group.section,
                        items: group.items,
                        initiallyExpanded: false,
                        previewLimit: kVenueMenuPreviewLimit,
                        onExpansionChanged: (isExpanded) =>
                            _onSectionExpansionChanged(
                              group.section.id,
                              isExpanded,
                            ),
                        onItemTap: (item) => _showMenuItemDetailsSheet(
                          item,
                          surface: 'section_tile',
                        ),
                      );
                    }, childCount: filteredSections.length),
                  ),
                );
              },
            ),
          );
        }

        if (venue.menuImages.isNotEmpty) {
          slivers.add(
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  kVenueHorizontalPadding,
                  16,
                  kVenueHorizontalPadding,
                  0,
                ),
                child: VenueMenuImageGallery(
                  images: venue.menuImages,
                  onImageOpen: _onMenuImageOpen,
                ),
              ),
            ),
          );
        }

        slivers.add(
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                kVenueHorizontalPadding,
                16,
                kVenueHorizontalPadding,
                0,
              ),
              child: Divider(),
            ),
          ),
        );

        return slivers;
      },
    );
  }

  List<Widget> _buildMenuImageFallbackSlivers(
    Venue venue, {
    String? message,
    bool isError = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final hasMenuImages = venue.menuImages.isNotEmpty;
    final shouldShowMessage = message != null || !hasMenuImages;
    final menuMode = isError
        ? 'error'
        : hasMenuImages
        ? 'image_only'
        : 'empty';

    _logMenuViewIfNeeded(
      venueId: venue.id,
      menuMode: menuMode,
      itemCount: 0,
      sectionCount: 0,
      featuredCount: 0,
      imageCount: venue.menuImages.length,
    );

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            kVenueHorizontalPadding,
            24,
            kVenueHorizontalPadding,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (shouldShowMessage) ...[
                VenueMenuEmptyState(
                  message: message ?? l10n.noMenuAvailable,
                  icon: isError ? Icons.error_outline : Icons.info_outline,
                  iconColor: isError ? Colors.red.shade400 : null,
                  backgroundColor: isError ? Colors.red.shade50 : null,
                ),
              ],
              if (hasMenuImages) ...[
                const SizedBox(height: 14),
                VenueMenuImageGallery(
                  images: venue.menuImages,
                  onImageOpen: _onMenuImageOpen,
                ),
              ],
            ],
          ),
        ),
      ),
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            kVenueHorizontalPadding,
            16,
            kVenueHorizontalPadding,
            0,
          ),
          child: Divider(),
        ),
      ),
    ];
  }

  void _logMenuViewIfNeeded({
    required String venueId,
    required String menuMode,
    required int itemCount,
    required int sectionCount,
    required int featuredCount,
    required int imageCount,
  }) {
    final viewKey = [
      venueId,
      menuMode,
      itemCount,
      sectionCount,
      featuredCount,
      imageCount,
    ].join('|');
    if (_lastMenuViewAnalyticsKey == viewKey) return;

    _lastMenuViewAnalyticsKey = viewKey;
    _hasMenuInteraction = false;
    _menuNoInteractionTimer?.cancel();
    _menuNoInteractionTimer = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _lastMenuViewAnalyticsKey != viewKey) return;

      final analytics = ref.read(analyticsServiceProvider);
      unawaited(
        analytics.logVenueMenuView(
          venueId: venueId,
          source: _menuAnalyticsSourceFullMenu,
          menuMode: menuMode,
          itemCount: itemCount,
          sectionCount: sectionCount,
          featuredCount: featuredCount,
          imageCount: imageCount,
        ),
      );
      _startMenuNoInteractionTimer(menuMode);
    });
  }

  void _startMenuNoInteractionTimer(String menuMode) {
    _menuNoInteractionTimer?.cancel();
    _menuNoInteractionTimer = Timer(_menuNoInteractionTimeout, () {
      _menuNoInteractionTimer = null;
      if (!mounted || _hasMenuInteraction) return;

      unawaited(
        ref
            .read(analyticsServiceProvider)
            .logVenueMenuNoInteraction(
              venueId: widget.venue.id,
              menuMode: menuMode,
              timeoutSeconds: _menuNoInteractionTimeout.inSeconds,
            ),
      );
    });
  }

  void _recordMenuInteraction() {
    _hasMenuInteraction = true;
    _menuNoInteractionTimer?.cancel();
    _menuNoInteractionTimer = null;
  }

  void _resetMenuAnalyticsSession({bool clearViewKey = false}) {
    _hasMenuInteraction = false;
    _menuNoInteractionTimer?.cancel();
    _menuNoInteractionTimer = null;
    if (clearViewKey) {
      _lastMenuViewAnalyticsKey = null;
    }
  }

  void _logMenuSearchAfterRebuild(String normalizedQuery) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _normalizeMenuQuery(_searchQueryNotifier.value).isEmpty) {
        return;
      }

      final resultCount = _visibleSectionItemsById.values.fold<int>(
        0,
        (sum, items) => sum + items.length,
      );
      unawaited(
        ref
            .read(analyticsServiceProvider)
            .logVenueMenuSearch(
              venueId: widget.venue.id,
              queryLength: normalizedQuery.length,
              resultCount: resultCount,
              sectionCount: _visibleSectionIds.length,
            ),
      );
    });
  }

  void _logMenuCategorySelect(String sectionId) {
    final itemCount = sectionId == 'all'
        ? _visibleSectionItemsById.values.fold<int>(
            0,
            (sum, items) => sum + items.length,
          )
        : _visibleSectionItemsById[sectionId]?.length ?? 0;

    unawaited(
      ref
          .read(analyticsServiceProvider)
          .logVenueMenuCategorySelect(
            venueId: widget.venue.id,
            sectionId: sectionId,
            itemCount: itemCount,
          ),
    );
  }

  void _onMenuImageOpen(int imageIndex) {
    _recordMenuInteraction();
    unawaited(
      ref
          .read(analyticsServiceProvider)
          .logVenueMenuImageOpen(
            venueId: widget.venue.id,
            imageIndex: imageIndex,
            surface: 'full_menu_gallery',
          ),
    );
  }

  void _onMenuSearchChanged(String query) {
    _menuSearchDebounce?.cancel();
    _menuSearchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted || _searchQueryNotifier.value == query) return;
      final normalizedQuery = _normalizeMenuQuery(query);
      _recordMenuInteraction();
      _searchQueryNotifier.value = query;
      if (normalizedQuery.isNotEmpty) {
        _selectedCategoryNotifier.value = 'all';
        _logMenuSearchAfterRebuild(normalizedQuery);
      }
      // No setState needed — ValueListenableBuilder rebuilds automatically
    });
  }

  void _onMenuSectionSelected(String sectionId) {
    _recordMenuInteraction();
    _logMenuCategorySelect(sectionId);

    if (_selectedCategoryNotifier.value != sectionId) {
      _selectedCategoryNotifier.value = sectionId;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _isProgrammaticMenuScroll = true;
      try {
        if (sectionId == 'all') {
          await _scrollToMenuTop();
        } else {
          await _scrollToSectionWithFallback(sectionId);
        }
      } finally {
        _programmaticScrollResetTimer?.cancel();
        _programmaticScrollResetTimer = Timer(
          const Duration(milliseconds: 200),
          () {
            if (!mounted) return;
            _isProgrammaticMenuScroll = false;
          },
        );
      }
    });
  }

  Future<void> _scrollToMenuTop() async {
    if (!_menuScrollController.hasClients) return;

    await _menuScrollController.animateTo(
      _menuScrollController.position.minScrollExtent,
      duration: kVenueUiMotionDuration,
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _scrollToSectionWithFallback(String sectionId) async {
    await _scrollToSectionByEstimate(sectionId);
  }

  Future<void> _scrollToSectionByEstimate(String sectionId) async {
    if (!_menuScrollController.hasClients) return;
    final targetIndex = _visibleSectionIds.indexOf(sectionId);
    if (targetIndex < 0) return;

    final position = _menuScrollController.position;
    final range = position.maxScrollExtent - position.minScrollExtent;
    if (range <= 0) return;

    final offsets = _computeSectionOffsets();
    final sectionOffset = offsets[sectionId];
    final targetOffset = sectionOffset == null
        ? position.minScrollExtent +
              (range *
                  (_visibleSectionIds.length <= 1
                      ? 0.0
                      : targetIndex / (_visibleSectionIds.length - 1)))
        : sectionOffset - kVenueMenuPinnedHeaderHeight - 8;

    final clampedOffset = targetOffset.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    await _menuScrollController.animateTo(
      clampedOffset,
      duration: kVenueUiMotionDuration,
      curve: Curves.easeOutCubic,
    );
  }

  double _estimateSectionExtent(String sectionId) {
    final items = _visibleSectionItemsById[sectionId] ?? const <MenuItem>[];
    final isExpanded = _expandedSectionIds.contains(sectionId);
    final visibleCount = isExpanded
        ? items.length
        : (items.length > kVenueMenuPreviewLimit
              ? kVenueMenuPreviewLimit
              : items.length);

    final dividerHeights = visibleCount <= 1
        ? 0.0
        : (visibleCount - 1).toDouble();
    final tileHeights = visibleCount * kVenueMenuItemRowEstimatedHeight;

    final hasToggle = items.length > kVenueMenuPreviewLimit;
    final toggleHeight = hasToggle ? kVenueMenuShowAllEstimatedHeight : 0.0;

    return kVenueMenuSectionHeaderEstimatedHeight +
        kVenueMenuSectionHeaderGap +
        tileHeights +
        dividerHeights +
        toggleHeight +
        kVenueMenuSectionBottomSpacing;
  }

  Map<String, double> _computeSectionOffsets() {
    _refreshMeasuredSectionOffsets();
    if (_visibleSectionIds.isEmpty) return const <String, double>{};

    var firstMeasuredIndex = -1;
    for (var i = 0; i < _visibleSectionIds.length; i += 1) {
      if (_measuredSectionOffsets.containsKey(_visibleSectionIds[i])) {
        firstMeasuredIndex = i;
        break;
      }
    }

    double? cursor;
    if (firstMeasuredIndex >= 0) {
      cursor = _measuredSectionOffsets[_visibleSectionIds[firstMeasuredIndex]];
      for (var i = firstMeasuredIndex - 1; i >= 0; i -= 1) {
        cursor = cursor! - _estimateSectionExtent(_visibleSectionIds[i]);
      }
      _menuListStartOffset = cursor;
    } else {
      cursor = _menuListStartOffset;
    }
    if (cursor == null) return const <String, double>{};

    final offsets = <String, double>{};
    for (final sectionId in _visibleSectionIds) {
      final measuredOffset = _measuredSectionOffsets[sectionId];
      if (measuredOffset != null) {
        cursor = measuredOffset;
      }
      offsets[sectionId] = cursor!;
      cursor += _estimateSectionExtent(sectionId);
    }
    return offsets;
  }

  void _refreshMeasuredSectionOffsets() {
    if (!_menuScrollController.hasClients) return;

    for (final sectionId in _visibleSectionIds) {
      final sectionContext = _menuSectionKeys[sectionId]?.currentContext;
      if (sectionContext == null) continue;

      final renderObject = sectionContext.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.attached) continue;

      final viewport = RenderAbstractViewport.of(renderObject);
      final offset = viewport.getOffsetToReveal(renderObject, 0.0).offset;
      if (offset.isFinite) {
        _measuredSectionOffsets[sectionId] = offset;
      }
    }
  }

  void _updateVisibleSectionSignature(
    List<_MenuSectionGroup> filteredSections, {
    required bool shouldShowFeaturedStrip,
    required String normalizedQuery,
  }) {
    final signature = [
      normalizedQuery,
      shouldShowFeaturedStrip ? 'featured' : 'no_featured',
      for (final group in filteredSections)
        '${group.section.id}:${group.items.length}',
    ].join('|');
    if (_visibleSectionSignature == signature) return;

    _visibleSectionSignature = signature;
    _measuredSectionOffsets.clear();
    _menuListStartOffset = null;

    final activeIds = filteredSections.map((group) => group.section.id).toSet();
    _expandedSectionIds.removeWhere(
      (sectionId) => !activeIds.contains(sectionId),
    );
    if (!activeIds.contains(_selectedCategoryNotifier.value) &&
        _selectedCategoryNotifier.value != 'all') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _setSelectedMenuSection('all');
      });
    }
  }

  void _onSectionExpansionChanged(String sectionId, bool isExpanded) {
    final didChange = isExpanded
        ? _expandedSectionIds.add(sectionId)
        : _expandedSectionIds.remove(sectionId);
    if (!didChange) return;

    _invalidateSectionOffsetsFrom(sectionId);
    _scheduleMenuScrollSync(force: true);
  }

  void _invalidateSectionOffsetsFrom(String sectionId) {
    final sectionIndex = _visibleSectionIds.indexOf(sectionId);
    if (sectionIndex < 0) return;

    for (var i = sectionIndex; i < _visibleSectionIds.length; i += 1) {
      _measuredSectionOffsets.remove(_visibleSectionIds[i]);
    }
  }

  bool _onMenuScrollNotification(ScrollNotification notification) {
    if (!_scrollSyncEnabled) return false;
    if (_isProgrammaticMenuScroll) return false;

    if (notification is! ScrollEndNotification) return false;

    _scheduleMenuScrollSync(force: true);
    return false;
  }

  void _onMenuScrollPositionChanged() {
    if (!_scrollSyncEnabled) return;
    if (_isProgrammaticMenuScroll) return;
    _scheduleMenuScrollSync();
  }

  void _scheduleMenuScrollSync({bool force = false}) {
    if (_pendingScrollSync) return;
    _pendingScrollSync = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingScrollSync = false;
      if (!mounted) return;
      _syncSelectedMenuSectionFromScroll(force: force);
    });
  }

  void _syncSelectedMenuSectionFromScroll({bool force = false}) {
    if (!mounted) return;
    if (_isProgrammaticMenuScroll && !force) return;
    if (!_menuScrollController.hasClients) return;
    if (_visibleSectionIds.isEmpty) return;

    final position = _menuScrollController.position;
    final pixels = position.pixels;
    if (pixels <= position.minScrollExtent + 24) {
      _setSelectedMenuSection('all');
      return;
    }

    final offsets = _computeSectionOffsets();
    if (offsets.isEmpty) return;

    final referenceOffset = pixels + kVenueMenuPinnedHeaderHeight + 8;
    String? selectedSectionId;
    var bestOffset = -double.infinity;
    for (final sectionId in _visibleSectionIds) {
      final sectionOffset = offsets[sectionId];
      if (sectionOffset == null) continue;
      if (sectionOffset <= referenceOffset && sectionOffset > bestOffset) {
        bestOffset = sectionOffset;
        selectedSectionId = sectionId;
      }
    }

    if (selectedSectionId == null) {
      _setSelectedMenuSection('all');
      return;
    }
    _setSelectedMenuSection(selectedSectionId);
  }

  void _setSelectedMenuSection(String sectionId) {
    if (_selectedCategoryNotifier.value == sectionId) return;
    _selectedCategoryNotifier.value = sectionId;
  }

  String _normalizeMenuQuery(String query) {
    return query.trim().toLowerCase().replaceAll(kVenueWhitespaceRegex, ' ');
  }

  String _buildSearchableText(MenuItem item) {
    return '${item.nameAr} ${item.nameEn} ${item.descriptionAr}'.toLowerCase();
  }

  Map<String, String> _buildSearchableTextMap(List<MenuItem> availableItems) {
    return <String, String>{
      for (final item in availableItems) item.id: _buildSearchableText(item),
    };
  }

  bool _matchesNormalizedMenuQuery({
    required MenuItem item,
    required String normalizedQuery,
    required Map<String, String> searchableTextByItemId,
  }) {
    if (normalizedQuery.isEmpty) return true;
    final searchableText = searchableTextByItemId[item.id] ?? '';
    return searchableText.contains(normalizedQuery);
  }

  String _normalizeCategoryKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(_categoryNonWordRegex, '_')
        .replaceAll(_categoryMultiUnderscoreRegex, '_')
        .replaceAll(_categoryTrimUnderscoreRegex, '');
  }

  String _humanizeCategoryId(String value, AppLocalizations l10n) {
    final normalized = value.trim().replaceAll('_', ' ');
    if (normalized.isEmpty) return l10n.generalCategory;
    return normalized
        .split(kVenueWhitespaceRegex)
        .where((word) => word.isNotEmpty)
        .map(
          (word) => word.length == 1
              ? word.toUpperCase()
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  void _showMenuItemDetailsSheet(MenuItem item, {required String surface}) {
    _recordMenuInteraction();
    unawaited(
      ref
          .read(analyticsServiceProvider)
          .logVenueMenuItemOpen(
            venueId: widget.venue.id,
            itemId: item.id,
            sectionId: item.category,
            surface: surface,
            isFeatured: item.isFeatured,
          ),
    );
    showVenueMenuItemDetailsSheet(context: context, item: item);
  }
}

class _MenuSectionGroup {
  final MenuSection section;
  final List<MenuItem> items;

  const _MenuSectionGroup({required this.section, required this.items});
}
