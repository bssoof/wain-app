import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wain_app/features/menu/domain/entities/menu_item.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_menu_section.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_ui_constants.dart';
import 'package:wain_app/l10n/app_localizations.dart';

void showVenueMenuItemDetailsSheet({
  required BuildContext context,
  required MenuItem item,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final bottomPadding = MediaQuery.of(sheetContext).viewPadding.bottom;
      return VenueMenuItemDetailsSheet(
        item: item,
        bottomPadding: bottomPadding,
      );
    },
  );
}

class _DetailsSheetPalette {
  final bool isDark;
  final Color surface;
  final Color imageBackground;
  final Color titleColor;
  final Color subtitleColor;
  final Color descriptionColor;
  final Color priceBackground;
  final Color priceText;
  final Color priceLabelText;
  final Color badgeBackground;
  final Color badgeText;
  final Color dragHandle;
  final Color placeholderIcon;

  const _DetailsSheetPalette({
    required this.isDark,
    required this.surface,
    required this.imageBackground,
    required this.titleColor,
    required this.subtitleColor,
    required this.descriptionColor,
    required this.priceBackground,
    required this.priceText,
    required this.priceLabelText,
    required this.badgeBackground,
    required this.badgeText,
    required this.dragHandle,
    required this.placeholderIcon,
  });

  factory _DetailsSheetPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return _DetailsSheetPalette(
      isDark: isDark,
      surface: colorScheme.surface,
      imageBackground: isDark
          ? colorScheme.surfaceContainerHighest
          : Colors.grey.shade100,
      titleColor: colorScheme.onSurface,
      subtitleColor: colorScheme.onSurfaceVariant,
      descriptionColor: isDark
          ? colorScheme.onSurface.withAlpha(200)
          : Colors.grey.shade800,
      priceBackground: colorScheme.primary.withAlpha(isDark ? 30 : 20),
      priceText: colorScheme.primary,
      priceLabelText: colorScheme.onSurface,
      badgeBackground: colorScheme.primary,
      badgeText: colorScheme.onPrimary,
      dragHandle: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
      placeholderIcon: isDark
          ? colorScheme.onSurfaceVariant
          : Colors.grey.shade500,
    );
  }
}

class VenueMenuItemDetailsSheet extends StatelessWidget {
  final MenuItem item;
  final double bottomPadding;

  const VenueMenuItemDetailsSheet({
    super.key,
    required this.item,
    this.bottomPadding = 0,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = _DetailsSheetPalette.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.68,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(kDetailsSheetTopRadius),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
              kDetailsSheetHorizontalPadding,
              12,
              kDetailsSheetHorizontalPadding,
              16 + bottomPadding,
            ),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 46,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: palette.dragHandle,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),

              // Image / placeholder area
              _buildImageArea(palette),

              const SizedBox(height: 16),

              // Featured badge
              if (item.isFeatured) ...[
                _buildFeaturedBadge(palette),
                const SizedBox(height: 10),
              ],

              // Title (Arabic primary)
              Text(
                item.nameAr,
                style: TextStyle(
                  fontSize: kDetailsSheetTitleFontSize,
                  fontWeight: FontWeight.w800,
                  color: palette.titleColor,
                  height: 1.3,
                ),
              ),

              // Subtitle (English name)
              if (item.nameEn.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.nameEn,
                  style: TextStyle(
                    color: palette.subtitleColor,
                    fontSize: kDetailsSheetSubtitleFontSize,
                    height: 1.3,
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Description
              if (item.descriptionAr.isNotEmpty) ...[
                Text(
                  item.descriptionAr,
                  style: TextStyle(
                    color: palette.descriptionColor,
                    fontSize: kDetailsSheetDescriptionFontSize,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Price row
              _buildPriceRow(l10n, palette, languageCode),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageArea(_DetailsSheetPalette palette) {
    final hasImage = item.photoUrl.isNotEmpty;
    final categoryIcon = venueMenuSectionIcon(item.category);

    if (hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(kDetailsSheetImageRadius),
        child: CachedNetworkImage(
          imageUrl: item.photoUrl,
          height: kDetailsSheetImageHeight,
          width: double.infinity,
          fit: BoxFit.cover,
          memCacheWidth: kMenuDetailsImageCacheWidth,
          maxWidthDiskCache: kMenuDetailsImageCacheWidth,
          placeholder: (context, url) => Container(
            height: kDetailsSheetImageHeight,
            decoration: BoxDecoration(
              color: palette.imageBackground,
              borderRadius: BorderRadius.circular(kDetailsSheetImageRadius),
            ),
            alignment: Alignment.center,
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: palette.priceText.withAlpha(120),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: kDetailsSheetImageHeight,
            decoration: BoxDecoration(
              color: palette.imageBackground,
              borderRadius: BorderRadius.circular(kDetailsSheetImageRadius),
            ),
            alignment: Alignment.center,
            child: Icon(
              categoryIcon,
              size: 40,
              color: palette.placeholderIcon,
            ),
          ),
        ),
      );
    }

    // No-image placeholder: category-aware styled surface
    return Container(
      height: kDetailsSheetPlaceholderHeight,
      decoration: BoxDecoration(
        color: palette.imageBackground,
        borderRadius: BorderRadius.circular(kDetailsSheetImageRadius),
        border: Border.all(
          color: palette.isDark
              ? Colors.white.withAlpha(12)
              : Colors.black.withAlpha(8),
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        categoryIcon,
        size: 48,
        color: palette.placeholderIcon,
      ),
    );
  }

  Widget _buildFeaturedBadge(_DetailsSheetPalette palette) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: palette.badgeBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              size: 14,
              color: palette.badgeText,
            ),
            const SizedBox(width: 4),
            Text(
              '\u0645\u0645\u064a\u0632', // مميز
              style: TextStyle(
                color: palette.badgeText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    AppLocalizations l10n,
    _DetailsSheetPalette palette,
    String languageCode,
  ) {
    final formattedPrice = formatVenueMenuPriceWithCurrency(
      item.price,
      item.currency,
      languageCode: languageCode,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: palette.priceBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: palette.priceText.withAlpha(30),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sell_outlined,
            color: palette.priceText,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            l10n.priceLabel,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: palette.priceLabelText,
              fontSize: 15,
            ),
          ),
          const Spacer(),
          Text(
            formattedPrice,
            style: TextStyle(
              color: palette.priceText,
              fontSize: kDetailsSheetPriceFontSize,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
