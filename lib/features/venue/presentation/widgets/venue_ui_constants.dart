const Duration kVenueUiMotionDuration = Duration(milliseconds: 200);
const double kVenueHorizontalPadding = 20;

const int kVenueMenuPreviewLimit = 4;

const double kVenueMenuChipHeight = 36;
const double kVenueMenuChipRadius = 20;
const double kVenueMenuChipHorizontalPadding = 14;
const double kVenueMenuPinnedHeaderHeight = 50;

const double kVenueMenuSectionHeaderRadius = 12;
const double kVenueMenuSectionHeaderVerticalPadding = 14;
const double kVenueMenuSectionHeaderHorizontalPadding = 14;
const double kVenueMenuSectionHeaderEstimatedHeight = 56;
const double kVenueMenuSectionHeaderGap = 6;
const double kVenueMenuSectionBottomSpacing = 20;
const double kVenueMenuShowAllEstimatedHeight = 38;
const double kVenueMenuProgressBadgeMinHeight = 28;

const double kVenueMenuItemThumbnailSize = 92;
const double kVenueMenuItemThumbnailRadius = 16;
const double kVenueMenuItemGap = 12;
const double kVenueMenuItemRowVerticalPadding = 10;
const double kVenueMenuItemRowEstimatedHeight = 112;

const double kVenueMenuSectionTitleFontSize = 19;
const double kVenueMenuItemTitleFontSize = 16;
const double kVenueMenuItemDescriptionFontSize = 12.5;
const double kVenueMenuPriceFontSize = 18;
const double kVenueMenuCurrencyFontSize = 11.5;

const double kVenueFeaturedCardWidth = 160;
const double kVenueFeaturedCardHeight = 188;
const double kVenueFeaturedCardImageHeight = 104;

const int kMenuItemThumbnailCacheSize = 176;
const int kMenuFeaturedImageCacheWidth = 300;
const int kMenuFeaturedImageCacheHeight = 200;
const int kMenuGalleryImageCacheWidth = 320;
const int kMenuGalleryImageCacheHeight = 420;
const int kMenuDetailsImageCacheWidth = 1080;

final RegExp kVenueWhitespaceRegex = RegExp(r'\s+');
final RegExp kVenueTrailingZeroesRegex = RegExp(r'0+$');
final RegExp kVenueTrailingDotRegex = RegExp(r'[.]$');

String formatVenueMenuPrice(double value) {
  if (!value.isFinite) return '0';
  if ((value - value.roundToDouble()).abs() < 0.000001) {
    return value.toStringAsFixed(0);
  }
  return value
      .toStringAsFixed(2)
      .replaceFirst(kVenueTrailingZeroesRegex, '')
      .replaceFirst(kVenueTrailingDotRegex, '');
}
