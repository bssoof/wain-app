import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/menu/domain/entities/menu_item.dart';
import 'package:wain_app/features/menu/domain/entities/menu_section.dart';
import 'package:wain_app/features/menu/presentation/providers/menu_providers.dart';
import 'package:wain_app/features/offers/domain/entities/offer.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_menu_section.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_offers_section.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_ui_constants.dart';
import 'package:cached_network_image/cached_network_image.dart';

final RegExp _categoryNonWordRegex = RegExp(r'[^a-z0-9_]+');
final RegExp _categoryMultiUnderscoreRegex = RegExp(r'_+');
final RegExp _categoryTrimUnderscoreRegex = RegExp(r'^_|_$');

class VenueMenuTab extends ConsumerStatefulWidget {
  final Venue venue;
  final ValueChanged<Offer> onClaimOffer;

  const VenueMenuTab({
    super.key,
    required this.venue,
    required this.onClaimOffer,
  });

  @override
  ConsumerState<VenueMenuTab> createState() => _VenueMenuTabState();
}

class _VenueMenuTabState extends ConsumerState<VenueMenuTab> {
  final TextEditingController _menuSearchController = TextEditingController();
  final Map<String, GlobalKey> _menuSectionKeys = {};
  final ValueNotifier<String> _selectedCategoryNotifier = ValueNotifier('all');
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier('');

  Timer? _menuSearchDebounce;
  Timer? _programmaticScrollResetTimer;
  bool _isProgrammaticMenuScroll = false;
  int _lastScrollSyncTimestampMs = 0;
  bool _scrollSyncEnabled = false;

  // Cached computed data — only recomputed when items change
  Map<String, String>? _cachedSearchableText;
  int _lastItemsHash = 0;

  @override
  void dispose() {
    _menuSearchDebounce?.cancel();
    _programmaticScrollResetTimer?.cancel();
    _menuSearchController.dispose();
    _selectedCategoryNotifier.dispose();
    _searchQueryNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onMenuScrollNotification,
      child: ValueListenableBuilder<String>(
        valueListenable: _searchQueryNotifier,
        builder: (context, searchQuery, _) {
          return CustomScrollView(
            key: const PageStorageKey<String>('menu_tab'),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    kVenueHorizontalPadding,
                    kVenueHorizontalPadding,
                    kVenueHorizontalPadding,
                    16,
                  ),
                  child: VenueOffersSection(
                    venue: widget.venue,
                    onClaimOffer: widget.onClaimOffer,
                  ),
                ),
              ),
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
    final sections = ref.watch(menuSectionsProvider(venueCategory));

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

        final selectedSectionId =
            activeSections.any((s) => s.id == _selectedCategoryNotifier.value)
            ? _selectedCategoryNotifier.value
            : 'all';

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
        _menuSectionKeys.removeWhere(
          (sectionId, _) => !activeSectionIds.contains(sectionId),
        );

        final featuredItems =
            availableItems
                .where(
                  (item) =>
                      item.isFeatured &&
                      _matchesNormalizedMenuQuery(
                        item: item,
                        normalizedQuery: normalizedQuery,
                        searchableTextByItemId: searchableTextByItemId,
                      ),
                )
                .toList()
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        final visibleItemsCount = filteredSections.fold<int>(
          0,
          (sum, g) => sum + g.items.length,
        );

        final slivers = <Widget>[
          SliverToBoxAdapter(
            child: Padding(
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
                  const SizedBox(height: 8),
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
                  if (selectedSectionId == 'all' &&
                      featuredItems.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    VenueFeaturedItemsRow(
                      items: featuredItems,
                      onItemTap: _showMenuItemDetailsSheet,
                    ),
                  ],
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
                height: 60,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  padding: const EdgeInsets.fromLTRB(
                    kVenueHorizontalPadding,
                    6,
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
              builder: (context, selectedId, _) {
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
                        previewLimit: 4,
                        shouldExpand:
                            selectedId != 'all' &&
                            selectedId == group.section.id,
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
        _selectedCategoryNotifier.value = 'all';
      }
      // No setState needed — ValueListenableBuilder rebuilds automatically
    });
  }

  void _onMenuSectionSelected(String sectionId) {
    if (_selectedCategoryNotifier.value != sectionId) {
      _selectedCategoryNotifier.value = sectionId;
    }

    if (sectionId == 'all') return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sectionContext = _menuSectionKeys[sectionId]?.currentContext;
      if (sectionContext == null) return;
      _isProgrammaticMenuScroll = true;
      try {
        await Scrollable.ensureVisible(
          sectionContext,
          duration: kVenueUiMotionDuration,
          curve: Curves.easeOut,
          alignment: 0.10,
        );
      } finally {
        _programmaticScrollResetTimer?.cancel();
        _programmaticScrollResetTimer = Timer(
          const Duration(milliseconds: 120),
          () {
            if (!mounted) return;
            _isProgrammaticMenuScroll = false;
            _syncSelectedMenuSectionFromScroll(force: true);
          },
        );
      }
    });
  }

  bool _onMenuScrollNotification(ScrollNotification notification) {
    if (!_scrollSyncEnabled) return false;
    if (_isProgrammaticMenuScroll) return false;
    if (notification is! ScrollUpdateNotification) return false;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - _lastScrollSyncTimestampMs < 100) return false;
    _lastScrollSyncTimestampMs = nowMs;

    _syncSelectedMenuSectionFromScroll();
    return false;
  }

  void _syncSelectedMenuSectionFromScroll({bool force = false}) {
    if (!mounted) return;
    if (_isProgrammaticMenuScroll && !force) return;
    if (_menuSectionKeys.isEmpty) return;

    String? visibleSectionId;
    double bestVisibleTop = double.infinity;

    _menuSectionKeys.forEach((sectionId, key) {
      final sectionContext = key.currentContext;
      if (sectionContext == null) return;

      final renderObject = sectionContext.findRenderObject() as RenderBox?;
      if (renderObject == null || !renderObject.attached) return;

      final topY = renderObject.localToGlobal(Offset.zero).dy;
      if (topY < bestVisibleTop && topY > -renderObject.size.height) {
        bestVisibleTop = topY;
        visibleSectionId = sectionId;
      }
    });

    if (visibleSectionId == null ||
        visibleSectionId == _selectedCategoryNotifier.value) {
      return;
    }

    _selectedCategoryNotifier.value = visibleSectionId!;
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

  String _formatPrice(double value) {
    if (!value.isFinite) return '0';
    if ((value - value.roundToDouble()).abs() < 0.000001) {
      return value.toStringAsFixed(0);
    }
    return value
        .toStringAsFixed(2)
        .replaceFirst(kVenueTrailingZeroesRegex, '')
        .replaceFirst(kVenueTrailingDotRegex, '');
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
                      child: CachedNetworkImage(
                        imageUrl: item.photoUrl,
                        height: 210,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        memCacheWidth: kMenuDetailsImageCacheWidth,
                        maxWidthDiskCache: kMenuDetailsImageCacheWidth,
                        placeholder: (context, url) =>
                            Container(height: 210, color: Colors.grey.shade200),
                        errorWidget: (context, url, error) => Container(
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
                          '${_formatPrice(item.price)} ${item.currency}',
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

class _MenuSectionGroup {
  final MenuSection section;
  final List<MenuItem> items;

  const _MenuSectionGroup({required this.section, required this.items});
}
