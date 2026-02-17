/// App-wide constants
library;

class AppConstants {
  AppConstants._();
  
  // App Info
  static const String appName = 'وين';
  static const String appNameEn = 'WAIN';
  static const String appVersion = '1.0.0';
  
  // Default City (MVP)
  static const String defaultCity = 'ramallah';
  
  // Supported Cities (key -> label)
  static const Map<String, String> cities = {
    'ramallah': 'رام الله',
    'jerusalem': 'القدس',
    'nablus': 'نابلس',
    'bethlehem': 'بيت لحم',
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
