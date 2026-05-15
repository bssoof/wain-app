const Duration kVenueUiMotionDuration = Duration(milliseconds: 200);
const double kVenueHorizontalPadding = 20;

const int kVenueMenuPreviewLimit = 4;
const int kVenueMenuAutoExpandItemLimit = 120;

const double kVenueMenuChipHeight = 34;
const double kVenueMenuChipRadius = 0;
const double kVenueMenuChipHorizontalPadding = 14;
const double kVenueMenuPinnedHeaderHeight = 46;

const double kVenueMenuSectionHeaderRadius = 12;
const double kVenueMenuSectionHeaderVerticalPadding = 14;
const double kVenueMenuSectionHeaderHorizontalPadding = 14;
const double kVenueMenuSectionHeaderEstimatedHeight = 56;
const double kVenueMenuSectionHeaderGap = 6;
const double kVenueMenuSectionBottomSpacing = 20;
const double kVenueMenuShowAllEstimatedHeight = 38;
const double kVenueMenuProgressBadgeMinHeight = 28;

const double kVenueMenuItemThumbnailSize = 72;
const double kVenueMenuItemThumbnailRadius = 12;
const double kVenueMenuItemGap = 10;
const double kVenueMenuItemRowVerticalPadding = 8;
const double kVenueMenuItemRowEstimatedHeight = 88;

const double kVenueMenuSectionTitleFontSize = 19;
const double kVenueMenuItemTitleFontSize = 15;
const double kVenueMenuItemDescriptionFontSize = 12.5;
const double kVenueMenuPriceFontSize = 15;
const double kVenueMenuCurrencyFontSize = 11.5;

const double kVenueFeaturedCardWidth = 142;
const double kVenueFeaturedCardHeight = 132;
const double kVenueFeaturedCardImageHeight = 72;
const int kVenueFeaturedPreviewLimit = 3;
const int kVenueFeaturedFullMenuLimit = 8;
const int kVenueFeaturedFullMenuMinItems = 3;

const double kVenueMenuGalleryImageWidth = 154;
const double kVenueMenuGalleryImageHeight = 204;
const double kVenueMenuGalleryImageRadius = 14;
const double kVenueMenuPreviewImageThumbSize = 48;
const int kVenueMenuPreviewImageLimit = 3;

const int kMenuItemThumbnailCacheSize = 176;
const int kMenuFeaturedImageCacheWidth = 300;
const int kMenuFeaturedImageCacheHeight = 200;
const int kMenuGalleryImageCacheWidth = 320;
const int kMenuGalleryImageCacheHeight = 420;
const int kMenuDetailsImageCacheWidth = 1080;

const double kDetailsSheetTopRadius = 24;
const double kDetailsSheetHorizontalPadding = 20;
const double kDetailsSheetImageHeight = 220;
const double kDetailsSheetImageRadius = 18;
const double kDetailsSheetPlaceholderHeight = 160;
const double kDetailsSheetTitleFontSize = 22;
const double kDetailsSheetSubtitleFontSize = 14;
const double kDetailsSheetDescriptionFontSize = 15;
const double kDetailsSheetPriceFontSize = 19;

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

String venueMenuCurrencyLabel(String currency, {String languageCode = 'ar'}) {
  final code = currency.trim().toUpperCase();
  final isArabic = languageCode.toLowerCase().startsWith('ar');
  return switch (code) {
    'ILS' => isArabic ? '₪' : 'ILS',
    'JOD' => isArabic ? 'د.أ' : 'JOD',
    'USD' => isArabic ? r'US$' : r'$',
    '' => 'ILS',
    _ => code.length <= 8 ? code : code.substring(0, 8),
  };
}

String formatVenueMenuPriceWithCurrency(
  double value,
  String currency, {
  String languageCode = 'ar',
}) {
  final formattedPrice = formatVenueMenuPrice(value);
  final code = currency.trim().toUpperCase();
  final isArabic = languageCode.toLowerCase().startsWith('ar');
  final label = venueMenuCurrencyLabel(currency, languageCode: languageCode);
  if (!isArabic && code == 'USD') return '$label$formattedPrice';
  return '$formattedPrice $label';
}
