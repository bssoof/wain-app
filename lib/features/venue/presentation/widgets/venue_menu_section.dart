import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/menu/domain/entities/menu_item.dart';
import 'package:wain_app/features/menu/domain/entities/menu_section.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_ui_constants.dart';
import 'package:wain_app/l10n/app_localizations.dart';

// ── Static colors (avoid recomputing on every build) ──
final Color _expandedHeaderBg = AppTheme.primaryColor.withAlpha(14);
final Color _expandedHeaderBorder = AppTheme.primaryColor.withAlpha(48);
final Color _collapsedHeaderBorder = Colors.grey.shade200;
final Color _progressLabelColor = Colors.grey.shade600;
final Color _expandIconColor = Colors.grey.shade700;
final Color _descriptionColor = Colors.grey.shade600;
final Color _placeholderColor = Colors.grey.shade100;
final Color _priceChipBg = AppTheme.primaryColor.withAlpha(20);
const Divider _itemDivider = Divider(height: 1, color: Color(0xFFE0E0E0));

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
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            _shimmerBox(width: 180, height: 18),
            const SizedBox(height: 12),
            _shimmerBox(width: double.infinity, height: 48),
            const SizedBox(height: 14),
            _shimmerBox(width: 140, height: 16),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _shimmerBox(width: double.infinity, height: 88),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _shimmerBox(width: double.infinity, height: 88),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _shimmerBox({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment(-1.0 + 2.0 * _shimmer.value, 0),
          end: Alignment(-1.0 + 2.0 * _shimmer.value + 1.0, 0),
          colors: const [
            Color(0xFFE0E0E0),
            Color(0xFFF5F5F5),
            Color(0xFFE0E0E0),
          ],
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

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.restaurant_menu,
            color: Colors.orange.shade800,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          l10n.menuTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        if (itemCount != null)
          Text(
            '$itemCount $effectiveCounterLabel',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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

    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: l10n.searchInMenuHint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: onClear == null
            ? null
            : IconButton(onPressed: onClear, icon: const Icon(Icons.close)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.featuredItems,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 180,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: item.photoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.photoUrl,
                        height: 100,
                        width: 150,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.low,
                        memCacheWidth: kMenuFeaturedImageCacheWidth,
                        memCacheHeight: kMenuFeaturedImageCacheHeight,
                        maxWidthDiskCache: kMenuFeaturedImageCacheWidth,
                        maxHeightDiskCache: kMenuFeaturedImageCacheHeight,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        placeholder: (context, url) =>
                            Container(height: 100, color: Colors.grey.shade200),
                        errorWidget: (context, url, error) => Container(
                          height: 100,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.fastfood, color: Colors.grey),
                        ),
                      )
                    : Container(
                        height: 100,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.fastfood, color: Colors.grey),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nameAr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.price} ${item.currency}',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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

    _chipKeys.putIfAbsent('all', () => GlobalKey());
    for (final section in widget.sections) {
      _chipKeys.putIfAbsent(section.id, () => GlobalKey());
    }

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            key: _chipKeys['all'],
            label: Text('${l10n.all} (${widget.totalCount})'),
            selected: widget.selectedSectionId == 'all',
            onSelected: (_) => widget.onSelected('all'),
          ),
          const SizedBox(width: 8),
          ...widget.sections.map((section) {
            final sectionCount = widget.sectionItemCounts[section.id] ?? 0;
            return Padding(
              key: _chipKeys[section.id],
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('${section.nameAr} ($sectionCount)'),
                selected: widget.selectedSectionId == section.id,
                onSelected: (_) => widget.onSelected(section.id),
              ),
            );
          }),
        ],
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
    this.previewLimit = 4,
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
        ? _expandedHeaderBg
        : Colors.transparent;
    final headerBorder = _isExpanded
        ? _expandedHeaderBorder
        : _collapsedHeaderBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          key: _headerKey,
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
            decoration: BoxDecoration(
              color: headerBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: headerBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.section.nameAr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Text(
                  progressLabel,
                  style: TextStyle(
                    color: _progressLabelColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: kVenueUiMotionDuration,
                  child: Icon(Icons.expand_more, color: _expandIconColor),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        for (int i = 0; i < visibleCount; i++) ...[
          VenueMenuItemTile(
            item: widget.items[i],
            onTap: widget.onItemTap == null
                ? null
                : () => widget.onItemTap!(widget.items[i]),
          ),
          if (i < visibleCount - 1) _itemDivider,
        ],
        if (!_isExpanded && hasHiddenItems)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _expandAndScrollToHeader,
              child: Text(l10n.menuShowAll(hiddenCount)),
            ),
          ),
        if (_isExpanded && totalItems > widget.previewLimit)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _isExpanded = false),
              child: Text(l10n.menuShowLess),
            ),
          ),
        const SizedBox(height: 18),
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
    final formattedPrice = _formatPrice(item.price);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (item.photoUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: item.photoUrl,
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                    memCacheWidth: kMenuItemThumbnailCacheSize,
                    memCacheHeight: kMenuItemThumbnailCacheSize,
                    maxWidthDiskCache: kMenuItemThumbnailCacheSize,
                    maxHeightDiskCache: kMenuItemThumbnailCacheSize,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    placeholder: (context, url) => Container(
                      width: 88,
                      height: 88,
                      color: _placeholderColor,
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 88,
                      height: 88,
                      color: _placeholderColor,
                      child: const Icon(
                        Icons.fastfood,
                        size: 24,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.nameAr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (item.descriptionAr.isNotEmpty)
                      Text(
                        item.descriptionAr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _descriptionColor,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _priceChipBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$formattedPrice ${item.currency}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                  color: Colors.grey.shade200,
                ),
                errorWidget: (context, url, error) => Container(
                  width: 150,
                  height: 200,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? _placeholderColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? _descriptionColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: _expandIconColor, fontSize: 14),
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
