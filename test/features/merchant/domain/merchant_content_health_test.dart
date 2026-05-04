import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_content_health.dart';

void main() {
  group('buildMerchantContentHealth', () {
    test('marks menu critical when no active menu exists', () {
      final health = buildMerchantContentHealth(
        hasActiveMenu: false,
        menuPublishedAt: null,
        photoCount: 5,
        hasActiveStory: true,
        lastStoryAt: DateTime(2026, 4, 4),
        is24Hours: false,
        validHoursDays: 5,
        hasName: true,
        hasCity: true,
        hasPhone: true,
        hasCategory: true,
        hasPhoto: true,
        now: DateTime(2026, 4, 5),
      );

      expect(health.menu.status, MerchantContentHealthStatus.critical);
    });

    test(
      'marks stories critical when no active story exists and publish is old',
      () {
        final health = buildMerchantContentHealth(
          hasActiveMenu: true,
          menuPublishedAt: DateTime(2026, 4, 1),
          photoCount: 5,
          hasActiveStory: false,
          lastStoryAt: DateTime(2026, 3, 15),
          is24Hours: false,
          validHoursDays: 5,
          hasName: true,
          hasCity: true,
          hasPhone: true,
          hasCategory: true,
          hasPhoto: true,
          now: DateTime(2026, 4, 5),
        );

        expect(health.stories.status, MerchantContentHealthStatus.critical);
        expect(health.stories.ageDays, 20);
      },
    );

    test('marks hours warning when only some days are configured', () {
      final health = buildMerchantContentHealth(
        hasActiveMenu: true,
        menuPublishedAt: DateTime(2026, 4, 3),
        photoCount: 5,
        hasActiveStory: false,
        lastStoryAt: DateTime(2026, 4, 2),
        is24Hours: false,
        validHoursDays: 3,
        hasName: true,
        hasCity: true,
        hasPhone: true,
        hasCategory: true,
        hasPhoto: true,
        now: DateTime(2026, 4, 5),
      );

      expect(health.hours.status, MerchantContentHealthStatus.warning);
      expect(health.hours.count, 3);
    });

    test(
      'marks profile critical when two or more required fields are missing',
      () {
        final health = buildMerchantContentHealth(
          hasActiveMenu: true,
          menuPublishedAt: DateTime(2026, 4, 3),
          photoCount: 2,
          hasActiveStory: true,
          lastStoryAt: DateTime(2026, 4, 4),
          is24Hours: true,
          validHoursDays: 0,
          hasName: true,
          hasCity: false,
          hasPhone: false,
          hasCategory: true,
          hasPhoto: false,
          now: DateTime(2026, 4, 5),
        );

        expect(health.profile.status, MerchantContentHealthStatus.critical);
        expect(health.profile.missingCount, 3);
        expect(health.photos.status, MerchantContentHealthStatus.critical);
      },
    );
  });
}
