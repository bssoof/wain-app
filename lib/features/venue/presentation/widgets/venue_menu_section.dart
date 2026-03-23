import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/menu/domain/entities/menu_item.dart';
import 'package:wain_app/features/menu/domain/entities/menu_section.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_ui_constants.dart';
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

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: palette.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.restaurant_menu,
            color: AppTheme.warningColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          l10n.menuTitle,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: palette.itemName,
          ),
        ),
        const Spacer(),
        if (itemCount != null)
          Text(
            '$itemCount $effectiveCounterLabel',
            style: TextStyle(
              fontSize: 12,
              color: palette.itemDescription,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class VenueMenuSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const VenueMenuSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onClear,
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
        suffixIcon: onClear == null
            ? null
            : IconButton(
                onPressed: onClear,
                icon: Icon(Icons.close, color: palette.icon),
              ),
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
    final formattedPrice = formatVenueMenuPrice(item.price);

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
                  width: kVenueFeaturedCardWidth,
                  height: kVenueFeaturedCardImageHeight,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 1.2,
                        color: palette.itemName,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$formattedPrice ${item.currency}',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
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

    final chipBox = chipContext.findRenderObject() as RenderBox?;
    if (chipBox == null || !chipBox.attached) return;

    final scrollableContext = _scrollController.position.context.storageContext;
    final scrollBox = scrollableContext.findRenderObject() as RenderBox?;
    if (scrollBox == null) return;

    final chipOffset = chipBox.localToGlobal(Offset.zero, ancestor: scrollBox);
    final viewportWidth = _scrollController.position.viewportDimension;
    final targetScroll =
        _scrollController.offset + chipOffset.dx - (viewportWidth * 0.3);

    final clampedScroll = targetScroll.clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      clampedScroll,
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
          _buildChip(
            key: _chipKeys['all']!,
            label: '${l10n.all} (${widget.totalCount})',
            selected: widget.selectedSectionId == 'all',
            onSelected: () => widget.onSelected('all'),
            palette: palette,
          ),
          const SizedBox(width: 8),
          ...widget.sections.map((section) {
            final sectionCount = widget.sectionItemCounts[section.id] ?? 0;
            return Padding(
              key: _chipKeys[section.id],
              padding: const EdgeInsets.only(right: 8),
              child: _buildChip(
                label: '${section.nameAr} ($sectionCount)',
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

  Widget _buildChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
    required _VenueMenuPalette palette,
    Key? key,
  }) {
    return SizedBox(
      key: key,
      height: kVenueMenuChipHeight,
      child: ChoiceChip(
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        selected: selected,
        onSelected: (_) => onSelected(),
        showCheckmark: false,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
        side: BorderSide(
          color: selected
              ? AppTheme.primaryColor
              : palette.chipUnselectedBorder,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: kVenueMenuChipHorizontalPadding,
        ),
        backgroundColor: palette.chipUnselectedBackground,
        selectedColor: palette.chipSelectedBackground,
        labelStyle: TextStyle(
          fontSize: 13.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          color: selected
              ? palette.chipSelectedText
              : palette.chipUnselectedText,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kVenueMenuChipRadius),
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

  const VenueMenuSectionBlock({
    super.key,
    required this.section,
    required this.items,
    this.onItemTap,
    this.initiallyExpanded = false,
    this.previewLimit = kVenueMenuPreviewLimit,
    this.shouldExpand = false,
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

  Future<void> _expandAndScrollToHeader() async {
    if (!_isExpanded) {
      setState(() => _isExpanded = true);
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
        : Colors.transparent;
    final headerBorder = _isExpanded
        ? palette.expandedHeaderBorder
        : palette.collapsedHeaderBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          key: _headerKey,
          borderRadius: BorderRadius.circular(kVenueMenuSectionHeaderRadius),
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: kVenueMenuSectionHeaderVerticalPadding,
              horizontal: kVenueMenuSectionHeaderHorizontalPadding,
            ),
            decoration: BoxDecoration(
              color: headerBackground,
              borderRadius: BorderRadius.circular(
                kVenueMenuSectionHeaderRadius,
              ),
              border: Border.all(color: headerBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.section.nameAr,
                    style: TextStyle(
                      fontSize: kVenueMenuSectionTitleFontSize,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: palette.itemName,
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(
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
              onPressed: () => setState(() => _isExpanded = false),
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
    final formattedPrice = formatVenueMenuPrice(item.price);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kVenueMenuItemThumbnailRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: kVenueMenuItemRowVerticalPadding,
            horizontal: 2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MenuItemThumbnail(url: item.photoUrl),
              const SizedBox(width: kVenueMenuItemGap),
              Expanded(
                child: SizedBox(
                  height: kVenueMenuItemThumbnailSize,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: secondaryText == null
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      Text(
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
                      if (secondaryText != null) ...[
                        const SizedBox(height: 6),
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
              const SizedBox(width: kVenueMenuItemGap),
              SizedBox(
                width: 82,
                height: kVenueMenuItemThumbnailSize,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: secondaryText == null
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.end,
                  children: [
                    Text(
                      formattedPrice,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: kVenueMenuPriceFontSize,
                        height: 1.1,
                        color: palette.itemPrice,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.currency,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: kVenueMenuCurrencyFontSize,
                        height: 1.2,
                        color: palette.itemCurrency,
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

class _MenuItemThumbnail extends StatelessWidget {
  final String url;
  final double width;
  final double height;

  const _MenuItemThumbnail({
    required this.url,
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
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              memCacheWidth: kMenuItemThumbnailCacheSize,
              memCacheHeight: kMenuItemThumbnailCacheSize,
              maxWidthDiskCache: kMenuItemThumbnailCacheSize,
              maxHeightDiskCache: kMenuItemThumbnailCacheSize,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              placeholder: (context, _) =>
                  ColoredBox(color: palette.subtleSurface),
              errorWidget: (context, url, error) =>
                  _ThumbnailPlaceholder(palette: palette),
            )
          : _ThumbnailPlaceholder(palette: palette),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  final _VenueMenuPalette palette;

  const _ThumbnailPlaceholder({required this.palette});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: palette.subtleSurface,
      child: Center(
        child: Icon(Icons.fastfood_rounded, size: 24, color: palette.icon),
      ),
    );
  }
}

class VenueMenuImageGallery extends StatelessWidget {
  final List<String> images;

  const VenueMenuImageGallery({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final url = images[index];
          return GestureDetector(
            onTap: () => _openImagePreview(context, url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: url,
                width: 150,
                height: 200,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
                memCacheWidth: kMenuGalleryImageCacheWidth,
                memCacheHeight: kMenuGalleryImageCacheHeight,
                maxWidthDiskCache: kMenuGalleryImageCacheWidth,
                maxHeightDiskCache: kMenuGalleryImageCacheHeight,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                placeholder: (context, url) => Container(
                  width: 150,
                  height: 200,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                errorWidget: (context, url, error) => Container(
                  width: 150,
                  height: 200,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        },
      ),
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
