/// App-wide constants
library;

class CityCoordinates {
  final double latitude;
  final double longitude;

  const CityCoordinates({required this.latitude, required this.longitude});
}

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'وين';
  static const String appNameEn = 'WAIN';
  static const String appVersion = '1.0.2';

  // Default City (MVP)
  static const String defaultCity = 'ramallah';

  // Supported Cities (key -> label)
  static const Map<String, String> cities = {
    'ramallah': 'رام الله',
    'jerusalem': 'القدس',
    'nablus': 'نابلس',
    'bethlehem': 'بيت لحم',
  };

  static const Map<String, CityCoordinates> cityCenters = {
    'ramallah': CityCoordinates(latitude: 31.9038, longitude: 35.2034),
    'jerusalem': CityCoordinates(latitude: 31.7683, longitude: 35.2137),
    'nablus': CityCoordinates(latitude: 32.2211, longitude: 35.2544),
    'bethlehem': CityCoordinates(latitude: 31.7054, longitude: 35.2024),
  };

  // Currency
  static const String defaultCurrency = 'ILS';

  // Discovery Output
  static const int maxSuggestions = 3; // 1 best + 2 alternatives

  // Pagination
  static const int venuesPerPage = 20;

  // Timeouts
  static const Duration networkTimeout = Duration(seconds: 15);
  static const Duration cacheExpiry = Duration(hours: 24);
}
