import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';

// ============ CONSTANTS ============

const kThemeModeKey = 'theme_mode';
const kLanguageKey = 'lang';
const kCityKey = 'city';
const kNotificationsKey = 'notifications_enabled';

const kDefaultCity = 'رام الله';
const kDefaultLang = 'ar';

const List<String> kAvailableCities = [
  'رام الله',
  'نابلس',
  'القدس',
  'الخليل',
  'بيت لحم',
];

// ============ SETTINGS STATE ============

class SettingsState {
  final ThemeMode themeMode;
  final String language;
  final String city;
  final bool notificationsEnabled;

  const SettingsState({
    this.themeMode = ThemeMode.light,
    this.language = kDefaultLang,
    this.city = kDefaultCity,
    this.notificationsEnabled = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? language,
    String? city,
    bool? notificationsEnabled,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      city: city ?? this.city,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

// ============ SETTINGS NOTIFIER ============

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    _loadFromPrefs();
    return const SettingsState();
  }

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  void _loadFromPrefs() {
    final savedTheme = _prefs.getString(kThemeModeKey);
    final savedLang = _prefs.getString(kLanguageKey);
    final savedCity = _prefs.getString(kCityKey);
    final savedNotifications = _prefs.getBool(kNotificationsKey);

    state = SettingsState(
      themeMode: savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light,
      language: savedLang ?? kDefaultLang,
      city: savedCity ?? kDefaultCity,
      notificationsEnabled: savedNotifications ?? false,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(kThemeModeKey, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> toggleTheme() async {
    final newMode = state.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }

  Future<void> setLanguage(String lang) async {
    state = state.copyWith(language: lang);
    await _prefs.setString(kLanguageKey, lang);
  }

  Future<void> toggleLanguage() async {
    await setLanguage(state.language == 'ar' ? 'en' : 'ar');
  }

  Future<void> setCity(String city) async {
    state = state.copyWith(city: city);
    await _prefs.setString(kCityKey, city);
  }

  Future<void> toggleNotifications() async {
    final newVal = !state.notificationsEnabled;
    state = state.copyWith(notificationsEnabled: newVal);
    await _prefs.setBool(kNotificationsKey, newVal);
  }
}

// ============ PROVIDER ============

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});

// ============ CONVENIENCE SELECTORS ============

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider.select((s) => s.themeMode));
});

final languageProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider.select((s) => s.language));
});

final cityProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider.select((s) => s.city));
});
