import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/core/constants/app_constants.dart';
import 'package:wain_app/features/profile/presentation/providers/settings_providers.dart';

void main() {
  group('normalizeCityKey', () {
    test('keeps supported city keys unchanged', () {
      expect(normalizeCityKey('ramallah'), 'ramallah');
      expect(normalizeCityKey('nablus'), 'nablus');
    });

    test('migrates legacy Arabic labels to city keys', () {
      expect(normalizeCityKey('رام الله'), 'ramallah');
      expect(normalizeCityKey('القدس'), 'jerusalem');
      expect(normalizeCityKey('نابلس'), 'nablus');
      expect(normalizeCityKey('بيت لحم'), 'bethlehem');
    });

    test('falls back to default city for unknown values', () {
      expect(normalizeCityKey('unknown-city'), AppConstants.defaultCity);
      expect(normalizeCityKey(''), AppConstants.defaultCity);
    });
  });

  group('cityLabel', () {
    test('returns Arabic label for normalized key', () {
      expect(cityLabel('ramallah'), 'رام الله');
      expect(cityLabel('jerusalem'), 'القدس');
    });

    test('returns label after normalizing legacy values', () {
      expect(cityLabel('رام الله'), 'رام الله');
      expect(cityLabel('نابلس'), 'نابلس');
    });
  });
}
