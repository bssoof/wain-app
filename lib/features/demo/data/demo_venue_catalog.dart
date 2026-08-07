import 'package:wain_app/features/demo/data/demo_reviews_catalog.dart';
import 'package:wain_app/features/demo/demo_mode.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';

/// The six venue photographs a customer-facing demo requires.
///
/// All six are on disk; [demoVenueAssetPackInstalled] records that, and
/// `demo_isolation_test` fails if a listed file goes missing.
const List<String> demoVenueRequiredPhotoAssets = <String>[
  'assets/images/demo_venue/storefront.jpg',
  'assets/images/demo_venue/indoor_seating.jpg',
  'assets/images/demo_venue/coffee_bar.jpg',
  'assets/images/demo_venue/food_table.jpg',
  'assets/images/demo_venue/workspace.jpg',
  'assets/images/demo_venue/outdoor_terrace.jpg',
];

/// Flip to true once every file in [demoVenueRequiredPhotoAssets] is present.
///
/// Deliberately a hand-set flag: the demo must not silently promote itself to
/// customer-ready just because some files appeared on disk.
///
/// Installed. The six photographs are synthetic — generated for this demo, not
/// photographs of any existing business — which is why the gallery can be shown
/// without impersonating a real venue.
const bool demoVenueAssetPackInstalled = true;

/// Stand-in imagery, used only while the asset pack is missing.
///
/// These are the café food and drink photographs that already ship with the
/// project. **They are not venue photos** — there is no storefront, seating,
/// workspace, or terrace shot among them, and the gallery must not be presented
/// to a customer as if there were.
const List<String> demoVenueStandInPhotos = <String>[
  'asset://assets/images/demo_menu/cafe_latte.jpg',
  'asset://assets/images/demo_menu/iced_spanish_latte.jpg',
  'asset://assets/images/demo_menu/san_sebastian.jpg',
  'asset://assets/images/demo_menu/club_sandwich.jpg',
  'asset://assets/images/demo_menu/berry_mojito.jpg',
  'asset://assets/images/demo_menu/belgian_waffle.jpg',
];

/// What the venue actually renders today.
List<String> get demoVenuePhotos => demoVenueAssetPackInstalled
    ? <String>[
        for (final asset in demoVenueRequiredPhotoAssets) 'asset://$asset',
      ]
    : demoVenueStandInPhotos;

/// Display-only coordinates: a point on open ground in Ramallah, deliberately
/// not the address of any existing business.
const double demoVenueLat = 31.9038;
const double demoVenueLng = 35.2034;

/// Opening hours exercising every branch the hours calculator supports:
/// a split day (Friday), a closed day (Sunday), and a slot that runs past
/// midnight (Thursday).
const Map<String, List<VenueHours>> demoVenueHours = <String, List<VenueHours>>{
  'monday': [VenueHours(open: '08:00', close: '23:00')],
  'tuesday': [VenueHours(open: '08:00', close: '23:00')],
  'wednesday': [VenueHours(open: '08:00', close: '23:00')],
  'thursday': [
    VenueHours(open: '08:00', close: '01:30', spansMidnight: true),
  ],
  'friday': [
    VenueHours(open: '08:00', close: '12:00'),
    VenueHours(open: '14:00', close: '23:59'),
  ],
  'saturday': [VenueHours(open: '09:00', close: '23:00')],
  'sunday': <VenueHours>[],
};

/// Eight attributes spread across all four tag families, so the "+N" overflow
/// control has something real to expand.
const VenueTags demoVenueTags = VenueTags(
  mood: <String>['هادئ', 'عائلي', 'رومانسي'],
  occasion: <String>['شغل', 'لقاء أصدقاء'],
  timeOfDay: <String>['صباحي', 'سهرة'],
  meal: <String>['فطور', 'حلويات'],
);

Venue buildDemoVenue() {
  return Venue(
    id: DemoMode.venueId,
    nameAr: DemoMode.venueNameAr,
    nameEn: DemoMode.venueNameEn,
    lat: demoVenueLat,
    lng: demoVenueLng,
    city: 'رام الله',
    categories: <String>['cafe'],
    tags: demoVenueTags,
    allTags: <String>[
      'هادئ',
      'عائلي',
      'رومانسي',
      'شغل',
      'لقاء أصدقاء',
      'صباحي',
      'سهرة',
      'فطور',
      'حلويات',
    ],
    minPrice: 15,
    maxPrice: 60,
    currency: 'ILS',
    // Derived, never hand-set. This was 4.6 while the six demo reviews average
    // 3.8, so the venue header and the reviews card on the same screen
    // disagreed about the same café — the one thing a walkthrough cannot
    // afford. Deriving it means they can no longer drift apart: change a
    // review and the headline follows.
    rating: demoReviewsAverage(),
    // Reserved, non-routable demo contact details — never a real subscriber.
    phone: '+970000000000',
    whatsapp: '+970000000000',
    instagram: 'https://example.com/wain-demo-cafe',
    facebook: 'https://example.com/wain-demo-cafe',
    website: 'https://example.com/wain-demo-cafe',
    photos: demoVenuePhotos,
    hours: demoVenueHours,
    partner: VenuePartner(isPartner: true, tier: 'A'),
    hasActiveOffers: true,
    transportEnabled: true,
    subscriptionStatus: 'active',
    visibilityStatus: 'visible',
    operationalStatus: 'active',
  );
}
