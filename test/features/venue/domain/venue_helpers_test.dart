import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_dashboard_providers.dart';

/// Creates a minimal Venue for testing isOpenNow / helpers.
Venue _makeVenue({
  Map<String, List<VenueHours>> hours = const {},
  bool is24h = false,
  String phone = '',
  String whatsapp = '',
  String instagram = '',
  String facebook = '',
  String website = '',
}) {
  return Venue(
    id: 'test-venue',
    nameAr: 'مكان اختبار',
    nameEn: 'Test Venue',
    city: 'Ramallah',
    lat: 31.9,
    lng: 35.2,
    categories: ['مطعم'],
    tags: const VenueTags(),
    minPrice: 10,
    maxPrice: 50,
    currency: 'ILS',
    rating: 4.5,
    phone: phone,
    instagram: instagram,
    whatsapp: whatsapp,
    facebook: facebook,
    website: website,
    hours: hours,
    is24h: is24h,
  );
}

void main() {
  // =============== isOpenNow() ===============
  group('isOpenNow()', () {
    test('is_24h → always true', () {
      final venue = _makeVenue(is24h: true);
      expect(venue.isOpenNow(), isTrue);
    });

    test('empty hours → null (unknown)', () {
      final venue = _makeVenue(hours: {});
      expect(venue.isOpenNow(), isNull);
    });

    test('open during hours → true', () {
      final venue = _makeVenue(hours: {
        'monday': [const VenueHours(open: '09:00', close: '22:00')],
      });
      // Monday Feb 16, 2026 at 14:00
      final monday14 = DateTime(2026, 2, 16, 14, 0);
      expect(venue.isOpenNow(now: monday14), isTrue);
    });

    test('closed after hours → false', () {
      final venue = _makeVenue(hours: {
        'monday': [const VenueHours(open: '09:00', close: '17:00')],
      });
      // Monday at 23:00
      final monday23 = DateTime(2026, 2, 16, 23, 0);
      expect(venue.isOpenNow(now: monday23), isFalse);
    });

    test('spans_midnight — same day late night (23:30) → true', () {
      final venue = _makeVenue(hours: {
        'monday': [
          const VenueHours(open: '22:00', close: '03:00', spansMidnight: true),
        ],
      });
      // Monday at 23:30
      final monday2330 = DateTime(2026, 2, 16, 23, 30);
      expect(venue.isOpenNow(now: monday2330), isTrue);
    });

    test('spans_midnight — NEXT DAY early morning (Tuesday 01:00, Monday shift) → true', () {
      // Monday has 22:00–03:00 shift; at Tuesday 01:00 we should be open
      final venue = _makeVenue(hours: {
        'monday': [
          const VenueHours(open: '22:00', close: '03:00', spansMidnight: true),
        ],
      });
      // Tuesday Feb 17, 2026 at 01:00
      final tuesday1am = DateTime(2026, 2, 17, 1, 0);
      expect(venue.isOpenNow(now: tuesday1am), isTrue);
    });

    test('spans_midnight — NEXT DAY past close (Tuesday 04:00, Monday shift) → false', () {
      final venue = _makeVenue(hours: {
        'monday': [
          const VenueHours(open: '22:00', close: '03:00', spansMidnight: true),
        ],
      });
      // Tuesday Feb 17, 2026 at 04:00 → shift closed at 03:00
      final tuesday4am = DateTime(2026, 2, 17, 4, 0);
      expect(venue.isOpenNow(now: tuesday4am), isFalse);
    });

    test('day not in hours → false (closed today)', () {
      final venue = _makeVenue(hours: {
        'sunday': [const VenueHours(open: '09:00', close: '17:00')],
        // No 'monday' entry
      });
      final monday = DateTime(2026, 2, 16, 12, 0); // Monday
      expect(venue.isOpenNow(now: monday), isFalse);
    });
  });

  // =============== Phone normalization ===============
  group('Phone normalization', () {
    test('strips spaces from phone', () {
      final venue = _makeVenue(phone: '+972 59 123 4567');
      // '+972591234567' = 13 chars (+ plus 12 digits)
      expect(venue.normalizedPhone.contains(' '), isFalse);
      expect(venue.normalizedPhone.length, 13);
      expect(venue.normalizedPhone, '+972591234567');
    });

    test('empty phone stays empty', () {
      final venue = _makeVenue(phone: '');
      expect(venue.normalizedPhone, '');
    });
  });

  // =============== WhatsApp number ===============
  group('WhatsApp number', () {
    test('strips leading 0 and adds country code', () {
      final venue = _makeVenue(whatsapp: '0591234567');
      // Should become 970591234567 (no +)
      expect(venue.whatsappNumber, '970591234567');
    });

    test('does not double-prefix if already has +', () {
      final venue = _makeVenue(whatsapp: '+972591234567');
      expect(venue.whatsappNumber, '972591234567');
    });
  });

  // =============== hasSocialLinks ===============
  group('hasSocialLinks', () {
    test('all empty → false', () {
      final venue = _makeVenue();
      expect(venue.hasSocialLinks, isFalse);
    });

    test('instagram set → true', () {
      final venue = _makeVenue(instagram: 'testuser');
      expect(venue.hasSocialLinks, isTrue);
    });

    test('website set → true', () {
      final venue = _makeVenue(website: 'example.com');
      expect(venue.hasSocialLinks, isTrue);
    });
  });

  // =============== MerchantAnalytics ===============
  group('MerchantAnalytics', () {
    test('fromMap parses all fields correctly', () {
      final analytics = MerchantAnalytics.fromMap({
        'views_total': 500,
        'views_this_week': 120,
        'views_last_week': 100,
        'calls_total': 50,
        'calls_this_week': 15,
        'calls_last_week': 10,
        'navs_total': 30,
        'navs_this_week': 8,
        'navs_last_week': 8,
        'story_views_total': 200,
        'story_views_this_week': 45,
      });

      expect(analytics.viewsTotal, 500);
      expect(analytics.viewsThisWeek, 120);
      expect(analytics.viewsLastWeek, 100);
      expect(analytics.callsTotal, 50);
      expect(analytics.callsThisWeek, 15);
      expect(analytics.navsTotal, 30);
      expect(analytics.storyViewsTotal, 200);
      expect(analytics.storyViewsThisWeek, 45);
    });

    test('fromMap handles missing/null fields gracefully', () {
      final analytics = MerchantAnalytics.fromMap({
        'views_total': 10,
        // All other fields missing
      });

      expect(analytics.viewsTotal, 10);
      expect(analytics.viewsThisWeek, 0);
      expect(analytics.callsTotal, 0);
      expect(analytics.storyViewsTotal, 0);
    });

    test('empty() returns all zeros', () {
      final analytics = MerchantAnalytics.empty();
      expect(analytics.viewsTotal, 0);
      expect(analytics.callsThisWeek, 0);
      expect(analytics.navsTotal, 0);
    });

    test('WoW — positive change (20%)', () {
      final analytics = MerchantAnalytics.fromMap({
        'views_total': 500,
        'views_this_week': 120,
        'views_last_week': 100,
        'calls_total': 0, 'calls_this_week': 0, 'calls_last_week': 0,
        'navs_total': 0, 'navs_this_week': 0, 'navs_last_week': 0,
        'story_views_total': 0, 'story_views_this_week': 0,
      });
      expect(analytics.viewsWoW, 20.0);
    });

    test('WoW — no previous data → 100%', () {
      final analytics = MerchantAnalytics.fromMap({
        'views_total': 5, 'views_this_week': 5, 'views_last_week': 0,
        'calls_total': 0, 'calls_this_week': 0, 'calls_last_week': 0,
        'navs_total': 0, 'navs_this_week': 0, 'navs_last_week': 0,
        'story_views_total': 0, 'story_views_this_week': 0,
      });
      expect(analytics.viewsWoW, 100.0);
    });

    test('WoW — both zero → null', () {
      final analytics = MerchantAnalytics.empty();
      expect(analytics.viewsWoW, isNull);
      expect(analytics.callsWoW, isNull);
    });

    test('WoW — negative change', () {
      final analytics = MerchantAnalytics.fromMap({
        'views_total': 200,
        'views_this_week': 80,
        'views_last_week': 100,
        'calls_total': 0, 'calls_this_week': 0, 'calls_last_week': 0,
        'navs_total': 0, 'navs_this_week': 0, 'navs_last_week': 0,
        'story_views_total': 0, 'story_views_this_week': 0,
      });
      expect(analytics.viewsWoW, -20.0);
    });
  });
}
