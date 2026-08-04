import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/menu/domain/entities/menu_item.dart';
import 'package:wain_app/features/menu/domain/entities/menu_section.dart';
import 'package:wain_app/features/menu/data/demo_menu_catalog.dart';
import 'package:wain_app/features/menu/presentation/providers/menu_providers.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_menu_section.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_menu_item_image.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_ui_constants.dart';

/// Tolerance for "the list is parked at its end", in logical pixels.
const double _kMenuScrollExtentEpsilon = 1.0;

/// Slack added below the pinned header before a section counts as "crossed".
const double _kMenuActiveSectionLineSlack = 4.0;

final RegExp _categoryNonWordRegex = RegExp(r'[^a-z0-9_]+');
final RegExp _categoryMultiUnderscoreRegex = RegExp(r'_+');
final RegExp _categoryTrimUnderscoreRegex = RegExp(r'^_|_$');

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
  bool _scrollSyncEnabled = false;

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
    _menuScrollController.dispose();
    _menuSearchController.dispose();
    _activeCategoryNotifier.dispose();
    _expandRequestNotifier.dispose();
    _searchQueryNotifier.dispose();
    super.dispose();
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
        _scrollSyncEnabled =
            activeSections.length <= 8 && availableItems.length <= 120;

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

        final visibleItemsCount = filteredSections.fold<int>(
          0,
          (sum, g) => sum + g.items.length,
        );

        final slivers = <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              key: _menuTopAnchorKey,
              padding: const EdgeInsets.fromLTRB(
                kVenueHorizontalPadding,
                24,
                kVenueHorizontalPadding,
                10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 16),
                  if (kDebugMode && shouldUseDemoMenu(venue.id)) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.22),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 20,
                            color: AppTheme.primaryColor,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'منيو تجريبي للعرض — الأسعار والأصناف قابلة للتعديل',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  VenueMenuHeader(itemCount: availableItems.length),
                  const SizedBox(height: 12),
                  VenueMenuSearchField(
                    controller: _menuSearchController,
                    onChanged: _onMenuSearchChanged,
                    onClear: _menuSearchController.text.isEmpty
                        ? null
                        : () {
                            _menuSearchController.clear();
                            _onMenuSearchChanged('');
                          },
                  ),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: kVenueUiMotionDuration,
                    child: Text(
                      key: ValueKey<String>(
                        '$visibleItemsCount:${filteredSections.length}',
                      ),
                      l10n.menuResultsSummary(
                        visibleItemsCount,
                        filteredSections.length,
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF616161),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                        onItemTap: _showMenuItemDetailsSheet,
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
                child: VenueMenuImageGallery(images: venue.menuImages),
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
    final fallbackItemCount = venue.menuImages.length;

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
              const Divider(),
              const SizedBox(height: 16),
              VenueMenuHeader(
                itemCount: fallbackItemCount,
                counterLabel: fallbackItemCount == 1
                    ? l10n.photoSingle
                    : l10n.photoPlural,
              ),
              const SizedBox(height: 12),
              VenueMenuEmptyState(
                message: message ?? l10n.noMenuAvailable,
                icon: isError ? Icons.error_outline : Icons.info_outline,
                iconColor: isError ? Colors.red.shade400 : null,
                backgroundColor: isError ? Colors.red.shade50 : null,
              ),
              if (venue.menuImages.isNotEmpty) ...[
                const SizedBox(height: 12),
                VenueMenuImageGallery(images: venue.menuImages),
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

  void _onMenuSearchChanged(String query) {
    _menuSearchDebounce?.cancel();
    _menuSearchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted || _searchQueryNotifier.value == query) return;
      _searchQueryNotifier.value = query;
      if (query.isNotEmpty) {
        _cancelProgrammaticTarget();
        _activeCategoryNotifier.value = 'all';
        _expandRequestNotifier.value = _MenuExpandRequest(
          'all',
          ++_expandRequestSerial,
        );
      }
      // No setState needed — ValueListenableBuilder rebuilds automatically
    });
  }

  void _onMenuSectionSelected(String sectionId) {
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

  void _showMenuItemDetailsSheet(MenuItem item) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final bottomPadding = MediaQuery.of(sheetContext).viewPadding.bottom;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.68,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomPadding),
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (item.photoUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: VenueMenuItemImage(
                        imageUrl: item.photoUrl,
                        height: 210,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        cacheWidth: kMenuDetailsImageCacheWidth,
                        placeholder: Container(
                          height: 210,
                          color: Colors.grey.shade200,
                          alignment: Alignment.center,
                          child: const Icon(Icons.fastfood, size: 36),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.restaurant_menu, size: 38),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    item.nameAr,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (item.nameEn.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.nameEn,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (item.descriptionAr.isNotEmpty)
                    Text(
                      item.descriptionAr,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  if (item.descriptionAr.isNotEmpty) const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.sell_outlined, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          l10n.priceLabel,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          '${formatVenueMenuPrice(item.price)} ${item.currency}',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
