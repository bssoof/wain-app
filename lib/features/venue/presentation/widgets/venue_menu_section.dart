import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/menu/domain/entities/menu_item.dart';
import 'package:wain_app/features/menu/domain/entities/menu_section.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_ui_constants.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_menu_item_image.dart';
import 'package:wain_app/l10n/app_localizations.dart';

String _displayMenuItemName(MenuItem item) {
  final trimmedAr = item.nameAr.trim();
  if (trimmedAr.isNotEmpty) return trimmedAr;
  final trimmedEn = item.nameEn.trim();
  if (trimmedEn.isNotEmpty) return trimmedEn;
  return '-';
}

String? _secondaryMenuItemText(MenuItem item, String displayName) {
  final trimmedDescription = item.descriptionAr.trim();
  if (trimmedDescription.isNotEmpty) return trimmedDescription;
  final trimmedEn = item.nameEn.trim();
  if (trimmedEn.isNotEmpty && trimmedEn != displayName) return trimmedEn;
  return null;
}

List<MenuItem> selectVenueFeaturedMenuItems(
  Iterable<MenuItem> items, {
  required int limit,
}) {
  if (limit <= 0) return const <MenuItem>[];
  final featuredItems =
      items.where((item) => item.isAvailable && item.isFeatured).toList()
        ..sort(_compareFeaturedMenuItems);
  if (featuredItems.length <= limit) {
    return List<MenuItem>.unmodifiable(featuredItems);
  }
  return List<MenuItem>.unmodifiable(featuredItems.take(limit));
}

int _compareFeaturedMenuItems(MenuItem a, MenuItem b) {
  final sortOrderComparison = a.sortOrder.compareTo(b.sortOrder);
  if (sortOrderComparison != 0) return sortOrderComparison;
  return a.id.compareTo(b.id);
}

IconData venueMenuSectionIcon(String value) {
  return switch (value.trim().toLowerCase()) {
    'restaurant_menu' => Icons.restaurant_menu_rounded,
    'coffee' ||
    'local_cafe' ||
    'hot_drinks' ||
    'hot_drink' => Icons.coffee_rounded,
    'local_drink' ||
    'cold_drinks' ||
    'cold_drink' ||
    'drinks' => Icons.local_drink_rounded,
    'bakery_dining' => Icons.bakery_dining_rounded,
    'cake' || 'desserts' || 'dessert' || 'sweets' => Icons.cake_rounded,
    'lunch_dining' ||
    'main_courses' ||
    'main_course' ||
    'mains' => Icons.lunch_dining_rounded,
    'fastfood' || 'fast_food' => Icons.fastfood_rounded,
    _ => Icons.restaurant_menu_rounded,
  };
}

class _VenueMenuPalette {
  final bool isDark;
  final Color surface;
  final Color surfaceMuted;
  final Color subtleSurface;
  final Color border;
  final Color divider;
  final Color itemName;
  final Color itemDescription;
  final Color itemPrice;
  final Color itemCurrency;
  final Color icon;
  final Color progressBackground;
  final Color progressText;
  final Color expandedHeaderBackground;
  final Color expandedHeaderBorder;
  final Color collapsedHeaderBorder;
  final Color chipSelectedBackground;
  final Color chipUnselectedBackground;
  final Color chipSelectedText;
  final Color chipUnselectedText;
  final Color chipUnselectedBorder;

  const _VenueMenuPalette({
    required this.isDark,
    required this.surface,
    required this.surfaceMuted,
    required this.subtleSurface,
    required this.border,
    required this.divider,
    required this.itemName,
    required this.itemDescription,
    required this.itemPrice,
    required this.itemCurrency,
    required this.icon,
    required this.progressBackground,
    required this.progressText,
    required this.expandedHeaderBackground,
    required this.expandedHeaderBorder,
    required this.collapsedHeaderBorder,
    required this.chipSelectedBackground,
    required this.chipUnselectedBackground,
    required this.chipSelectedText,
    required this.chipUnselectedText,
    required this.chipUnselectedBorder,
  });

  factory _VenueMenuPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return _VenueMenuPalette(
      isDark: isDark,
      surface: colorScheme.surface,
      surfaceMuted: AppTheme.primarySurfaceColor,
      subtleSurface: theme.colorScheme.surfaceContainerHighest,
      border: colorScheme.outline,
      divider: colorScheme.outline.withAlpha(120),
      itemName: colorScheme.onSurface,
      itemDescription: colorScheme.onSurfaceVariant,
      itemPrice: colorScheme.onSurface,
      itemCurrency: colorScheme.onSurfaceVariant,
      icon: colorScheme.onSurfaceVariant,
      progressBackground: AppTheme.primarySurfaceColor,
      progressText: colorScheme.primary,
      expandedHeaderBackground: colorScheme.primary.withAlpha(isDark ? 22 : 12),
      expandedHeaderBorder: colorScheme.primary.withAlpha(isDark ? 110 : 70),
      collapsedHeaderBorder: colorScheme.outline,
      chipSelectedBackground: colorScheme.primary,
      chipUnselectedBackground: colorScheme.surface,
      chipSelectedText: colorScheme.onPrimary,
      chipUnselectedText: colorScheme.onSurface,
      chipUnselectedBorder: colorScheme.outline,
    );
  }
}

class VenueMenuLoadingSkeleton extends StatefulWidget {
  const VenueMenuLoadingSkeleton({super.key});

  @override
  State<VenueMenuLoadingSkeleton> createState() =>
      _VenueMenuLoadingSkeletonState();
}

class _VenueMenuLoadingSkeletonState extends State<VenueMenuLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _VenueMenuPalette.of(context);
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _shimmerBox(
              width: 168,
              height: 18,
              colors: _skeletonColors(palette),
            ),
            const SizedBox(height: 12),
            _shimmerBox(
              width: double.infinity,
              height: 50,
              colors: _skeletonColors(palette),
            ),
            const SizedBox(height: 14),
            _shimmerBox(
              width: 116,
              height: 14,
              colors: _skeletonColors(palette),
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(
                3,
                (index) => Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 8,
                    right: index == 2 ? 0 : 0,
                  ),
                  child: _shimmerBox(
                    width: index == 0 ? 84 : 104,
                    height: kVenueMenuChipHeight,
                    radius: kVenueMenuChipRadius,
                    colors: _skeletonColors(palette),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            for (var i = 0; i < 3; i++) ...[
              _buildItemSkeletonRow(palette),
              if (i < 2) const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }

  List<Color> _skeletonColors(_VenueMenuPalette palette) {
    return [palette.subtleSurface, palette.surfaceMuted, palette.subtleSurface];
  }

  Widget _buildItemSkeletonRow(_VenueMenuPalette palette) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _shimmerBox(
          width: kVenueMenuItemThumbnailSize,
          height: kVenueMenuItemThumbnailSize,
          radius: kVenueMenuItemThumbnailRadius,
          colors: _skeletonColors(palette),
        ),
        const SizedBox(width: kVenueMenuItemGap),
        Expanded(
          child: SizedBox(
            height: kVenueMenuItemThumbnailSize,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(
                  width: double.infinity,
                  height: 16,
                  colors: _skeletonColors(palette),
                ),
                const SizedBox(height: 10),
                _shimmerBox(
                  width: 140,
                  height: 12,
                  colors: _skeletonColors(palette),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: kVenueMenuItemGap),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _shimmerBox(
              width: 44,
              height: 18,
              colors: _skeletonColors(palette),
            ),
            const SizedBox(height: 8),
            _shimmerBox(
              width: 28,
              height: 10,
              colors: _skeletonColors(palette),
            ),
          ],
        ),
      ],
    );
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    required List<Color> colors,
    double radius = 10,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(-1.0 + 2.0 * _shimmer.value, 0),
          end: Alignment(-1.0 + 2.0 * _shimmer.value + 1.0, 0),
          colors: colors,
        ),
      ),
    );
  }
}

class VenueMenuHeader extends StatelessWidget {
  final int? itemCount;
  final String? counterLabel;

  const VenueMenuHeader({super.key, this.itemCount, this.counterLabel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final effectiveCounterLabel = counterLabel ?? l10n.menuItemCounter;
    final palette = _VenueMenuPalette.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border.withAlpha(120)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.restaurant_menu_rounded,
              color: AppTheme.warningColor,
              size: 23,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.menuTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: palette.itemName,
              ),
            ),
          ),
          if (itemCount != null) ...[
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 132, minHeight: 30),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: palette.progressBackground,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: palette.border.withAlpha(80)),
                ),
                child: Text(
                  '$itemCount $effectiveCounterLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.2,
                    color: palette.progressText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _sectionIconKey(MenuSection section) {
  final icon = section.icon.trim();
  if (icon.isEmpty || icon == 'restaurant_menu') return section.id;
  return icon;
}

class _SectionHeaderIcon extends StatelessWidget {
  final MenuSection section;
  final _VenueMenuPalette palette;

  const _SectionHeaderIcon({required this.section, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: palette.progressBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.border.withAlpha(80)),
      ),
      child: Icon(
        venueMenuSectionIcon(_sectionIconKey(section)),
        size: 19,
        color: palette.progressText,
      ),
    );
  }
}

class VenueMenuSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final String? countLabel;

  const VenueMenuSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onClear,
    this.countLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = _VenueMenuPalette.of(context);

    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: l10n.searchInMenuHint,
        hintStyle: TextStyle(color: palette.itemDescription),
        prefixIcon: Icon(Icons.search, color: palette.icon),
        suffixIcon: countLabel == null && onClear == null
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (countLabel != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: Text(
                        countLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.itemDescription,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (onClear != null)
                    IconButton(
                      onPressed: onClear,
                      icon: Icon(Icons.close, color: palette.icon),
                    ),
                ],
              ),
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: palette.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.border),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      onChanged: onChanged,
    );
  }
}

class VenueFeaturedItemsRow extends StatelessWidget {
  final List<MenuItem> items;
  final ValueChanged<MenuItem>? onItemTap;

  const VenueFeaturedItemsRow({super.key, required this.items, this.onItemTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = _VenueMenuPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.featuredItems,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: palette.itemName,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: kVenueFeaturedCardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (_, i) => VenueMenuFeaturedCard(
              item: items[i],
              onTap: onItemTap == null ? null : () => onItemTap!(items[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class VenueMenuFeaturedCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback? onTap;

  const VenueMenuFeaturedCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = _VenueMenuPalette.of(context);
    final displayName = _displayMenuItemName(item);
    final formattedPrice = formatVenueMenuPriceWithCurrency(
      item.price,
      item.currency,
      languageCode: Localizations.localeOf(context).languageCode,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kVenueMenuItemThumbnailRadius),
        child: Container(
          width: kVenueFeaturedCardWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kVenueMenuItemThumbnailRadius),
            color: palette.surface,
            border: Border.all(color: palette.border),
            boxShadow: AppShadows.elevated,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(kVenueMenuItemThumbnailRadius),
                ),
                child: _MenuItemThumbnail(
                  url: item.photoUrl,
                  iconKey: item.category,
                  width: kVenueFeaturedCardWidth,
                  height: kVenueFeaturedCardImageHeight,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          height: 1.16,
                          color: palette.itemName,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 54),
                      child: Text(
                        formattedPrice,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          height: 1.16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VenueMenuCategoryChips extends StatefulWidget {
  final List<MenuSection> sections;
  final String selectedSectionId;
  final ValueChanged<String> onSelected;
  final int totalCount;
  final Map<String, int> sectionItemCounts;

  const VenueMenuCategoryChips({
    super.key,
    required this.sections,
    required this.selectedSectionId,
    required this.onSelected,
    this.totalCount = 0,
    this.sectionItemCounts = const {},
  });

  @override
  State<VenueMenuCategoryChips> createState() => _VenueMenuCategoryChipsState();
}

class _VenueMenuCategoryChipsState extends State<VenueMenuCategoryChips> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _chipKeys = {};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant VenueMenuCategoryChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSectionId != widget.selectedSectionId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToSelectedChip();
      });
    }
  }

  void _scrollToSelectedChip() {
    final chipKey = _chipKeys[widget.selectedSectionId];
    final chipContext = chipKey?.currentContext;
    if (chipContext == null || !_scrollController.hasClients) return;

    final chipBox = chipContext.findRenderObject();
    if (chipBox is! RenderBox || !chipBox.attached) return;

    // The offset is delegated to the scroll position instead of being computed
    // by hand. The previous arithmetic added the chip's `dx` — its distance
    // from the strip's *left* edge — to the current offset, which only equals
    // the distance along the scroll axis when that axis runs left-to-right.
    // Under Directionality.rtl the strip's AxisDirection is `left`, so the term
    // carried the wrong sign and the auto-scroll travelled away from the chip.
    //
    // `getOffsetToReveal`, which backs this call, is written in scroll-axis
    // coordinates and is therefore correct in both directions; it also clamps
    // to the scroll extents itself, so the first and last chips settle flush
    // against their edge rather than overshooting.
    //
    // This is deliberately the *position's* `ensureVisible` and not
    // `Scrollable.ensureVisible`: the latter walks every ancestor scrollable
    // and would drag the vertical menu viewport along with the chip strip.
    _scrollController.position.ensureVisible(
      chipBox,
      alignment: 0.5,
      duration: kVenueUiMotionDuration,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = _VenueMenuPalette.of(context);

    _chipKeys.putIfAbsent('all', () => GlobalKey());
    for (final section in widget.sections) {
      _chipKeys.putIfAbsent(section.id, () => GlobalKey());
    }

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTab(
            key: _chipKeys['all']!,
            label: l10n.all,
            selected: widget.selectedSectionId == 'all',
            onSelected: () => widget.onSelected('all'),
            palette: palette,
          ),
          const SizedBox(width: 18),
          ...widget.sections.map((section) {
            return Padding(
              key: _chipKeys[section.id],
              padding: const EdgeInsetsDirectional.only(end: 18),
              child: _buildTab(
                label: section.nameAr,
                selected: widget.selectedSectionId == section.id,
                onSelected: () => widget.onSelected(section.id),
                palette: palette,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
    required _VenueMenuPalette palette,
    Key? key,
  }) {
    final labelColor = selected ? AppTheme.primaryColor : palette.itemName;

    return Semantics(
      key: key,
      label: label,
      button: true,
      selected: selected,
      child: SizedBox(
        height: kVenueMenuChipHeight,
        child: InkWell(
          onTap: onSelected,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: labelColor,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  AnimatedContainer(
                    duration: kVenueUiMotionDuration,
                    curve: Curves.easeOutCubic,
                    width: selected ? 24 : 0,
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VenueMenuSectionBlock extends StatefulWidget {
  final MenuSection section;
  final List<MenuItem> items;
  final ValueChanged<MenuItem>? onItemTap;
  final bool initiallyExpanded;
  final int previewLimit;
  final bool shouldExpand;
  final ValueChanged<bool>? onExpansionChanged;

  const VenueMenuSectionBlock({
    super.key,
    required this.section,
    required this.items,
    this.onItemTap,
    this.initiallyExpanded = false,
    this.previewLimit = kVenueMenuPreviewLimit,
    this.shouldExpand = false,
    this.onExpansionChanged,
  });

  @override
  State<VenueMenuSectionBlock> createState() => _VenueMenuSectionBlockState();
}

class _VenueMenuSectionBlockState extends State<VenueMenuSectionBlock> {
  late bool _isExpanded = widget.initiallyExpanded;
  final GlobalKey _headerKey = GlobalKey();

  @override
  void didUpdateWidget(covariant VenueMenuSectionBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset expand state when switching to a completely different section key/id.
    if (oldWidget.section.id != widget.section.id) {
      _isExpanded = widget.initiallyExpanded;
    }
    if (widget.shouldExpand && !_isExpanded) {
      _isExpanded = true;
    }
  }

  void _setExpanded(bool value) {
    if (_isExpanded == value) return;
    setState(() => _isExpanded = value);
    widget.onExpansionChanged?.call(value);
  }

  Future<void> _expandAndScrollToHeader() async {
    if (!_isExpanded) {
      _setExpanded(true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _headerKey.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: kVenueUiMotionDuration,
        curve: Curves.easeOut,
        alignment: 0.08,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = _VenueMenuPalette.of(context);
    final totalItems = widget.items.length;
    final visibleCount = _isExpanded
        ? totalItems
        : (totalItems > widget.previewLimit ? widget.previewLimit : totalItems);
    final hasHiddenItems = totalItems > visibleCount;
    final progressLabel = !_isExpanded && hasHiddenItems
        ? '$visibleCount/$totalItems'
        : '$totalItems';
    final hiddenCount = totalItems - visibleCount;
    final headerBackground = _isExpanded
        ? palette.expandedHeaderBackground
        : palette.surface;
    final headerBorder = _isExpanded
        ? palette.expandedHeaderBorder
        : palette.collapsedHeaderBorder;
    final headerShadow = _isExpanded ? AppShadows.elevated : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          key: _headerKey,
          borderRadius: BorderRadius.circular(kVenueMenuSectionHeaderRadius),
          onTap: () => _setExpanded(!_isExpanded),
          child: AnimatedContainer(
            duration: kVenueUiMotionDuration,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              vertical: kVenueMenuSectionHeaderVerticalPadding,
              horizontal: kVenueMenuSectionHeaderHorizontalPadding,
            ),
            decoration: BoxDecoration(
              color: headerBackground,
              borderRadius: BorderRadius.circular(
                kVenueMenuSectionHeaderRadius,
              ),
              border: Border.all(
                color: headerBorder,
                width: _isExpanded ? 1.2 : 1,
              ),
              boxShadow: headerShadow,
            ),
            child: Row(
              children: [
                _SectionHeaderIcon(section: widget.section, palette: palette),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.section.nameAr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: kVenueMenuSectionTitleFontSize,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                      color: palette.itemName,
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    maxWidth: 64,
                    minHeight: kVenueMenuProgressBadgeMinHeight,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: palette.progressBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Center(
                      child: Text(
                        progressLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.progressText,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: kVenueUiMotionDuration,
                  child: Icon(Icons.expand_more_rounded, color: palette.icon),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: kVenueMenuSectionHeaderGap),
        for (int i = 0; i < visibleCount; i++) ...[
          VenueMenuItemTile(
            item: widget.items[i],
            onTap: widget.onItemTap == null
                ? null
                : () => widget.onItemTap!(widget.items[i]),
          ),
          if (i < visibleCount - 1) Divider(height: 1, color: palette.divider),
        ],
        if (!_isExpanded && hasHiddenItems)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _expandAndScrollToHeader,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppTheme.primaryColor,
              ),
              child: Text(
                l10n.menuShowAll(hiddenCount),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        if (_isExpanded && totalItems > widget.previewLimit)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => _setExpanded(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: palette.itemDescription,
              ),
              child: Text(
                l10n.menuShowLess,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        const SizedBox(height: kVenueMenuSectionBottomSpacing),
      ],
    );
  }
}

class VenueMenuItemTile extends StatelessWidget {
  final MenuItem item;
  final VoidCallback? onTap;

  const VenueMenuItemTile({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = _VenueMenuPalette.of(context);
    final displayName = _displayMenuItemName(item);
    final secondaryText = _secondaryMenuItemText(item, displayName);
    final formattedPrice = formatVenueMenuPriceWithCurrency(
      item.price,
      item.currency,
      languageCode: Localizations.localeOf(context).languageCode,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: kVenueMenuItemRowVerticalPadding,
            horizontal: 2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MenuItemThumbnail(url: item.photoUrl, iconKey: item.category),
              const SizedBox(width: kVenueMenuItemGap),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: kVenueMenuItemThumbnailSize,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: kVenueMenuItemTitleFontSize,
                                height: 1.22,
                                color: palette.itemName,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 88),
                            child: Text(
                              formattedPrice,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: kVenueMenuPriceFontSize,
                                height: 1.2,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (item.isFeatured) ...[
                        const SizedBox(height: 6),
                        _FeaturedMenuItemBadge(palette: palette),
                      ],
                      if (secondaryText != null) ...[
                        SizedBox(height: item.isFeatured ? 5 : 6),
                        Text(
                          secondaryText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: kVenueMenuItemDescriptionFontSize,
                            height: 1.28,
                            color: palette.itemDescription,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItemThumbnail extends StatelessWidget {
  final String url;
  final double width;
  final double height;
  final String iconKey;

  const _MenuItemThumbnail({
    required this.url,
    this.iconKey = 'restaurant_menu',
    this.width = kVenueMenuItemThumbnailSize,
    this.height = kVenueMenuItemThumbnailSize,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _VenueMenuPalette.of(context);
    final hasUrl = url.trim().isNotEmpty;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kVenueMenuItemThumbnailRadius),
        border: Border.all(color: palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasUrl
          ? VenueMenuItemImage(
              imageUrl: url,
              width: width,
              height: height,
              cacheWidth: kMenuItemThumbnailCacheSize,
              placeholder: _ThumbnailPlaceholder(
                palette: palette,
                iconKey: iconKey,
              ),
            )
          : _ThumbnailPlaceholder(palette: palette, iconKey: iconKey),
    );
  }
}

class _FeaturedMenuItemBadge extends StatelessWidget {
  final _VenueMenuPalette palette;

  const _FeaturedMenuItemBadge({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withAlpha(palette.isDark ? 42 : 28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppTheme.warningColor.withAlpha(palette.isDark ? 120 : 80),
        ),
      ),
      child: Text(
        'مميز',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: palette.itemName,
          fontSize: 11,
          height: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  final _VenueMenuPalette palette;
  final String iconKey;

  const _ThumbnailPlaceholder({required this.palette, required this.iconKey});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.subtleSurface.withAlpha(palette.isDark ? 160 : 120),
        border: Border.all(color: palette.border.withAlpha(60)),
      ),
      child: Center(
        child: Icon(
          venueMenuSectionIcon(iconKey),
          size: 22,
          color: palette.icon,
        ),
      ),
    );
  }
}

class VenueMenuImageGallery extends StatelessWidget {
  final List<String> images;
  final ValueChanged<int>? onImageOpen;

  const VenueMenuImageGallery({
    super.key,
    required this.images,
    this.onImageOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final palette = _VenueMenuPalette.of(context);
    final countLabel =
        '${images.length} ${images.length == 1 ? l10n.photoSingle : l10n.photoPlural}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: palette.progressBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.border.withAlpha(80)),
              ),
              child: Icon(
                Icons.photo_library_rounded,
                size: 18,
                color: palette.progressText,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.menuPhotosTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: palette.itemName,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: palette.progressBackground,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: palette.border.withAlpha(80)),
              ),
              child: Text(
                countLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.progressText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: kVenueMenuGalleryImageHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final url = images[index];
              return _MenuGalleryImageCard(
                url: url,
                onTap: () {
                  onImageOpen?.call(index);
                  _openImagePreview(context, url);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _openImagePreview(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: url,
            memCacheWidth: kMenuDetailsImageCacheWidth,
            maxWidthDiskCache: kMenuDetailsImageCacheWidth,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
          ),
        ),
      ),
    );
  }
}

class _MenuGalleryImageCard extends StatelessWidget {
  final String url;
  final VoidCallback onTap;

  const _MenuGalleryImageCard({required this.url, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = _VenueMenuPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kVenueMenuGalleryImageRadius),
        child: Container(
          width: kVenueMenuGalleryImageWidth,
          height: kVenueMenuGalleryImageHeight,
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(kVenueMenuGalleryImageRadius),
            border: Border.all(color: palette.border.withAlpha(130)),
            boxShadow: AppShadows.elevated,
          ),
          clipBehavior: Clip.antiAlias,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.low,
            memCacheWidth: kMenuGalleryImageCacheWidth,
            memCacheHeight: kMenuGalleryImageCacheHeight,
            maxWidthDiskCache: kMenuGalleryImageCacheWidth,
            maxHeightDiskCache: kMenuGalleryImageCacheHeight,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholder: (context, url) => _MenuGalleryImagePlaceholder(
              palette: palette,
              showSpinner: true,
            ),
            errorWidget: (context, url, error) =>
                _MenuGalleryImagePlaceholder(palette: palette),
          ),
        ),
      ),
    );
  }
}

class _MenuGalleryImagePlaceholder extends StatelessWidget {
  final _VenueMenuPalette palette;
  final bool showSpinner;

  const _MenuGalleryImagePlaceholder({
    required this.palette,
    this.showSpinner = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: palette.subtleSurface),
      child: Center(
        child: showSpinner
            ? SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: palette.progressText.withAlpha(130),
                ),
              )
            : Icon(Icons.broken_image_rounded, color: palette.icon, size: 28),
      ),
    );
  }
}

class VenueMenuEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;

  const VenueMenuEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _VenueMenuPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? palette.subtleSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? palette.itemDescription),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: palette.icon, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class PinnedMenuHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  const PinnedMenuHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant PinnedMenuHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
