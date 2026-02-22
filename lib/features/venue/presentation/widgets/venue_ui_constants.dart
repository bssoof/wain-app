const Duration kVenueUiMotionDuration = Duration(milliseconds: 220);
const double kVenueHorizontalPadding = 20;

const int kMenuItemThumbnailCacheSize = 176;
const int kMenuFeaturedImageCacheWidth = 300;
const int kMenuFeaturedImageCacheHeight = 200;
const int kMenuGalleryImageCacheWidth = 320;
const int kMenuGalleryImageCacheHeight = 420;
const int kMenuDetailsImageCacheWidth = 1080;

final RegExp kVenueWhitespaceRegex = RegExp(r'\s+');
final RegExp kVenueTrailingZeroesRegex = RegExp(r'0+$');
final RegExp kVenueTrailingDotRegex = RegExp(r'[.]$');
