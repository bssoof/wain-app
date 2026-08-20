import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/services/analytics_service.dart';
import 'package:wain_app/features/demo/demo_mode.dart';
import 'package:wain_app/features/menu/domain/entities/menu_item.dart';
import 'package:wain_app/features/menu/domain/entities/menu_section.dart';
import 'package:wain_app/features/demo/presentation/demo_badge.dart';
import 'package:wain_app/features/menu/data/demo_menu_catalog.dart';
import 'package:wain_app/features/menu/presentation/providers/menu_providers.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_menu_item_details_sheet.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_menu_section.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_ui_constants.dart';

/// Tolerance for "the list is parked at its end", in logical pixels.
const double _kMenuScrollExtentEpsilon = 1.0;

/// Slack added below the pinned header before a section counts as "crossed".
const double _kMenuActiveSectionLineSlack = 4.0;

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

  /// Drives the highlighted chip only. Written by scroll-sync *and* by taps.
  final ValueNotifier<String> _activeCategoryNotifier = ValueNotifier('all');

  /// Drives section expansion. Written **only** by an explicit chip tap, never
  /// by scrolling, so passing over a section while dragging can no longer
  /// expand it and change the list geometry mid-motion.
  final ValueNotifier<_MenuExpandRequest> _expandRequestNotifier =
      ValueNotifier(const _MenuExpandRequest('all', 0));
  int _expandRequestSerial = 0;

  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier('');
  final List<String> _visibleSectionIds = <String>[];
  final Map<String, List<MenuItem>> _visibleSectionItemsById =
      <String, List<MenuItem>>{};

  Timer? _menuSearchDebounce;
  Timer? _menuNoInteractionTimer;
  bool _scrollSyncEnabled = false;
  bool _hasMenuInteraction = false;
  String? _lastMenuViewAnalyticsKey;

  /// Non-null while a chip-initiated jump owns the selection. Scroll-sync is
  /// inhibited for as long as it is set; it is released as soon as the
  /// programmatic motion settles, never by a timer and never lazily.
  String? _programmaticTargetSectionId;

  /// Bumped whenever a jump is superseded (new tap, or the target disappearing
  /// from the list) so a stale in-flight jump can never pin the selection.
  int _programmaticScrollSerial = 0;

  // Cached computed data — only recomputed when items change
  Map<String, String>? _cachedSearchableText;
  int _lastItemsHash = 0;

  @override
  void dispose() {
    _menuSearchDebounce?.cancel();
    _menuNoInteractionTimer?.cancel();
    _menuScrollController.dispose();
    _menuSearchController.dispose();
    _activeCategoryNotifier.dispose();
    _expandRequestNotifier.dispose();
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

        // A search or a provider update can drop the section a jump is aimed
        // at. Release the lock (and invalidate the in-flight jump) instead of
        // leaving the selection frozen on something that no longer exists.
        // Only plain fields are touched here — never a ValueNotifier — so this
        // cannot mark an already-built descendant dirty during this build.
        final pendingTarget = _programmaticTargetSectionId;
        if (pendingTarget != null &&
            pendingTarget != 'all' &&
            !activeSectionIds.contains(pendingTarget)) {
          _programmaticTargetSectionId = null;
          _programmaticScrollSerial += 1;
        }

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (shouldUseDemoMenu(venue.id)) ...[
                    const DemoModeBadge(),
                    const SizedBox(height: 14),
                  ],
                  VenueMenuSearchField(
                    controller: _menuSearchController,
                    onChanged: _onMenuSearchChanged,
                    countLabel:
                        '${availableItems.length} ${l10n.menuItemCounter}',
                    onClear: _menuSearchController.text.isEmpty
                        ? null
                        : () {
                            _menuSearchController.clear();
                            _onMenuSearchChanged('');
                          },
                  ),
                ],
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
                    valueListenable: _activeCategoryNotifier,
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
            // Listens to the *expand request*, not the active section, so a
            // scroll-driven highlight change no longer rebuilds the whole
            // SliverList (and no longer expands anything).
            ValueListenableBuilder<_MenuExpandRequest>(
              valueListenable: _expandRequestNotifier,
              builder: (context, expandRequest, _) {
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
                      final isExpandTarget = expandRequest.matches(
                        group.section.id,
                      );
                      return VenueMenuSectionBlock(
                        key: _menuSectionKeys[group.section.id],
                        section: group.section,
                        items: group.items,
                        // `shouldExpand` is only read in didUpdateWidget, so a
                        // section built for the first time while it is the
                        // target — the normal case for anything outside the
                        // cache extent — would ignore it. `initiallyExpanded`
                        // covers that first build.
                        initiallyExpanded: isExpandTarget,
                        previewLimit: kVenueMenuPreviewLimit,
                        shouldExpand: isExpandTarget,
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
    if (DemoMode.isDemoVenue(venueId)) return;

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

      unawaited(
        ref
            .read(analyticsServiceProvider)
            .logVenueMenuView(
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
    if (DemoMode.isDemoVenue(widget.venue.id)) return;
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
    if (clearViewKey) _lastMenuViewAnalyticsKey = null;
  }

  void _logMenuSearchAfterRebuild(String normalizedQuery) {
    if (DemoMode.isDemoVenue(widget.venue.id)) return;
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
    if (DemoMode.isDemoVenue(widget.venue.id)) return;
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
    if (DemoMode.isDemoVenue(widget.venue.id)) return;
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
        _cancelProgrammaticTarget();
        _activeCategoryNotifier.value = 'all';
        _expandRequestNotifier.value = _MenuExpandRequest(
          'all',
          ++_expandRequestSerial,
        );
        _logMenuSearchAfterRebuild(normalizedQuery);
      }
      // No setState needed — ValueListenableBuilder rebuilds automatically
    });
  }

  void _onMenuSectionSelected(String sectionId) {
    _recordMenuInteraction();
    _logMenuCategorySelect(sectionId);
    unawaited(_runMenuSectionJump(sectionId));
  }

  Future<void> _runMenuSectionJump(String sectionId) async {
    // Expansion is an explicit user intent, so it is requested here and only
    // here. The serial makes a repeat tap on an already-selected chip a fresh
    // request, which is what re-opens a section the user collapsed by hand.
    final expandSerial = ++_expandRequestSerial;
    _expandRequestNotifier.value = _MenuExpandRequest(sectionId, expandSerial);
    _activeCategoryNotifier.value = sectionId;

    // The target is claimed *before* any motion starts, and a fresh serial
    // supersedes whatever jump was previously in flight.
    _programmaticTargetSectionId = sectionId;
    final serial = ++_programmaticScrollSerial;

    try {
      // Let the expand request lay out before anything is measured.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || serial != _programmaticScrollSerial) return;

      if (sectionId == 'all') {
        await _scrollToMenuTop();
      } else {
        await _scrollToSectionWithFallback(sectionId);
      }

      if (!mounted || serial != _programmaticScrollSerial) return;
      // A manual drag during the animation clears the target; in that case the
      // user owns the position now and geometry decides the selection.
      if (_programmaticTargetSectionId != sectionId) return;

      // Pin, then release. The lock never survives the motion that created it,
      // so it can never wait around for some later drag.
      _activeCategoryNotifier.value = sectionId;
      _programmaticTargetSectionId = null;
    } finally {
      // Runs on the happy path *and* on every abandoned path (drag cancel,
      // target removed, widget disposed), so a stale request is never left
      // behind to be replayed.
      _retireExpandRequest(expandSerial);
    }
  }

  /// Retires an expand request once the jump that issued it has finished.
  ///
  /// By this point the target has been scrolled into view, so it is built and
  /// the expansion has already been applied. Resetting to a neutral request
  /// does **not** close anything — [VenueMenuSectionBlock] only ever expands on
  /// `shouldExpand`, it never collapses on its absence — it merely stops an
  /// unrelated rebuild (a provider update, a menu refresh) from replaying the
  /// request and re-opening a section the user has since closed by hand.
  void _retireExpandRequest(int expandSerial) {
    if (!mounted) return;
    final current = _expandRequestNotifier.value;
    // A newer tap already owns the notifier — leave its request alone.
    if (current.serial != expandSerial) return;
    if (current.sectionId == 'all') return;
    _expandRequestNotifier.value = _MenuExpandRequest(
      'all',
      ++_expandRequestSerial,
    );
  }

  void _cancelProgrammaticTarget() {
    if (_programmaticTargetSectionId == null) return;
    _programmaticTargetSectionId = null;
    _programmaticScrollSerial += 1;
  }

  Future<void> _scrollToMenuTop() async {
    if (!_menuScrollController.hasClients) return;

    final topContext = _menuTopAnchorKey.currentContext;
    if (topContext != null && topContext.mounted) {
      await Scrollable.ensureVisible(
        topContext,
        duration: kVenueUiMotionDuration,
        curve: Curves.easeOut,
        alignment: 0.0,
      );
      return;
    }

    await _menuScrollController.animateTo(
      _menuScrollController.position.minScrollExtent,
      duration: kVenueUiMotionDuration,
      curve: Curves.easeOutCubic,
    );
  }

  /// Measured on Flutter 3.41.7: `getOffsetToReveal(box, 0.0)` already
  /// subtracts the pinned header's obstruction extent (delta was exactly
  /// -[kVenueMenuPinnedHeaderHeight]). So `alignment: 0.0` lands the section
  /// top precisely on the line the active-section predicate uses, and
  /// subtracting the header again here would push the target too far down.
  Future<void> _scrollToSectionWithFallback(String sectionId) async {
    final sectionContext = _menuSectionKeys[sectionId]?.currentContext;
    if (sectionContext != null) {
      if (!sectionContext.mounted) return;
      await Scrollable.ensureVisible(
        sectionContext,
        duration: kVenueUiMotionDuration,
        curve: Curves.easeOut,
        alignment: 0.0,
      );
      return;
    }

    await _scrollToSectionByEstimate(sectionId);
    if (!mounted) return;

    await Future<void>.delayed(const Duration(milliseconds: 16));
    if (!mounted) return;

    final sectionContextAfterEstimate =
        _menuSectionKeys[sectionId]?.currentContext;
    if (sectionContextAfterEstimate == null) return;
    if (!sectionContextAfterEstimate.mounted) return;
    await Scrollable.ensureVisible(
      sectionContextAfterEstimate,
      duration: kVenueUiMotionDuration,
      curve: Curves.easeOut,
      alignment: 0.0,
    );
  }

  Future<void> _scrollToSectionByEstimate(String sectionId) async {
    if (!_menuScrollController.hasClients) return;
    final targetIndex = _visibleSectionIds.indexOf(sectionId);
    if (targetIndex < 0) return;

    final position = _menuScrollController.position;
    final range = position.maxScrollExtent - position.minScrollExtent;
    if (range <= 0) return;

    final anchor = _findClosestBuiltSectionAnchor(targetIndex);
    double targetOffset;

    if (anchor == null) {
      final progress = _visibleSectionIds.length <= 1
          ? 0.0
          : targetIndex / (_visibleSectionIds.length - 1);
      targetOffset = position.minScrollExtent + (range * progress);
    } else {
      final anchorIndex = anchor.$1;
      var estimatedOffset = anchor.$2;
      if (targetIndex > anchorIndex) {
        for (var i = anchorIndex; i < targetIndex; i += 1) {
          estimatedOffset += _estimateCollapsedSectionExtent(
            _visibleSectionIds[i],
          );
        }
      } else if (targetIndex < anchorIndex) {
        for (var i = targetIndex; i < anchorIndex; i += 1) {
          estimatedOffset -= _estimateCollapsedSectionExtent(
            _visibleSectionIds[i],
          );
        }
      }
      targetOffset = estimatedOffset;
    }

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

  (int, double)? _findClosestBuiltSectionAnchor(int targetIndex) {
    var bestDistance = 1 << 30;
    (int, double)? best;

    for (var i = 0; i < _visibleSectionIds.length; i += 1) {
      final key = _menuSectionKeys[_visibleSectionIds[i]];
      final sectionContext = key?.currentContext;
      if (sectionContext == null) continue;
      final renderObject = sectionContext.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.attached) continue;

      final viewport = RenderAbstractViewport.of(renderObject);
      final offset = viewport.getOffsetToReveal(renderObject, 0.0).offset;
      final distance = (i - targetIndex).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = (i, offset);
      }
    }
    return best;
  }

  double _estimateCollapsedSectionExtent(String sectionId) {
    final items = _visibleSectionItemsById[sectionId] ?? const <MenuItem>[];
    final visibleCount = items.length > kVenueMenuPreviewLimit
        ? kVenueMenuPreviewLimit
        : items.length;

    final dividerHeights = visibleCount <= 1
        ? 0.0
        : (visibleCount - 1).toDouble();
    final tileHeights = visibleCount * kVenueMenuItemRowEstimatedHeight;

    final hasHidden = items.length > visibleCount;
    final showAllHeight = hasHidden ? kVenueMenuShowAllEstimatedHeight : 0.0;

    return kVenueMenuSectionHeaderEstimatedHeight +
        kVenueMenuSectionHeaderGap +
        tileHeights +
        dividerHeights +
        showAllHeight +
        kVenueMenuSectionBottomSpacing;
  }

  bool _onMenuScrollNotification(ScrollNotification notification) {
    // Only the menu's own vertical viewport may drive the selection. Without
    // this the horizontal chip strip — which lives inside the pinned header and
    // therefore bubbles through here — would feed its own notifications back
    // into the vertical sync.
    if (notification.depth != 0) return false;
    if (notification.metrics.axis != Axis.vertical) return false;
    if (!_scrollSyncEnabled) return false;

    // `dragDetails` is non-null only for genuine user drags, so this is an
    // unambiguous "the user has taken over" signal.
    if (notification is ScrollStartNotification) {
      if (notification.dragDetails != null) _cancelProgrammaticTarget();
      return false;
    }
    if (notification is ScrollUpdateNotification) {
      if (notification.dragDetails != null) _cancelProgrammaticTarget();
      _syncActiveSectionFromScroll();
      return false;
    }
    if (notification is ScrollEndNotification) {
      _syncActiveSectionFromScroll();
      return false;
    }
    return false;
  }

  void _syncActiveSectionFromScroll() {
    if (!mounted) return;
    // A chip-initiated jump owns the selection until it settles.
    if (_programmaticTargetSectionId != null) return;

    final resolved = _resolveActiveSectionFromGeometry();
    if (resolved == null) return;
    if (resolved == _activeCategoryNotifier.value) return;
    _activeCategoryNotifier.value = resolved;
  }

  /// Resolves the active section from viewport-relative geometry.
  ///
  /// The rule is "the last section whose top has crossed the line just below
  /// the pinned header", measured against the viewport's own [RenderBox] rather
  /// than absolute screen coordinates.
  ///
  /// At the very end of the list the trailing sections can never cross that
  /// line, so the last section owns the remaining scroll range outright —
  /// without this the predicate would keep selecting an earlier section while
  /// the user is looking at the bottom of the menu.
  String? _resolveActiveSectionFromGeometry() {
    if (_visibleSectionIds.isEmpty) return null;
    if (!_menuScrollController.hasClients) return null;

    final position = _menuScrollController.position;
    if (position.pixels >=
        position.maxScrollExtent - _kMenuScrollExtentEpsilon) {
      return _visibleSectionIds.last;
    }

    final viewportBox = _menuViewportBox();
    if (viewportBox == null || !viewportBox.attached) return null;

    final line = kVenueMenuPinnedHeaderHeight + _kMenuActiveSectionLineSlack;
    String? activeSectionId;

    for (final sectionId in _visibleSectionIds) {
      final sectionContext = _menuSectionKeys[sectionId]?.currentContext;
      if (sectionContext == null) continue;

      final renderObject = sectionContext.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.attached) continue;

      final topY = renderObject
          .localToGlobal(Offset.zero, ancestor: viewportBox)
          .dy;
      if (topY > line) break;
      activeSectionId = sectionId;
    }

    // Nothing has reached the line yet: the user is still on the search header
    // above the first section, which is exactly what "all" means.
    return activeSectionId ?? 'all';
  }

  RenderBox? _menuViewportBox() {
    if (!_menuScrollController.hasClients) return null;
    final viewportContext =
        _menuScrollController.position.context.storageContext;
    final renderObject = viewportContext.findRenderObject();
    return renderObject is RenderBox ? renderObject : null;
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
    if (!DemoMode.isDemoVenue(widget.venue.id)) {
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
    }
    showVenueMenuItemDetailsSheet(context: context, item: item);
  }
}

/// A one-shot request to expand a section.
///
/// A bare section id cannot express this: after the user collapses a section by
/// hand, tapping the same chip again carries the identical id, so a
/// `ValueNotifier<String>` would not notify and the section would stay closed.
/// The serial makes every tap a distinct value.
@immutable
class _MenuExpandRequest {
  final String sectionId;
  final int serial;

  const _MenuExpandRequest(this.sectionId, this.serial);

  bool matches(String id) => sectionId != 'all' && sectionId == id;

  @override
  bool operator ==(Object other) =>
      other is _MenuExpandRequest &&
      other.sectionId == sectionId &&
      other.serial == serial;

  @override
  int get hashCode => Object.hash(sectionId, serial);
}

class _MenuSectionGroup {
  final MenuSection section;
  final List<MenuItem> items;

  const _MenuSectionGroup({required this.section, required this.items});
}
