import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wain_app/core/constants/app_constants.dart';
import 'package:wain_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';

// ============ CONSTANTS ============

const kThemeModeKey = 'theme_mode';
const kLanguageKey = 'lang';
const kCityKey = 'city';
const kNotificationsKey = 'notifications_enabled';
const kWalletNotificationsEnabledField = 'wallet_notifications_enabled';
const kWalletExpiryRemindersEnabledField = 'wallet_expiry_reminders_enabled';
const kAdminWalletNotificationsEnabledField =
    'admin_wallet_notifications_enabled';

const kDefaultCity = AppConstants.defaultCity;
const kDefaultLang = 'ar';

final List<String> kAvailableCities = AppConstants.cities.keys.toList(
  growable: false,
);

const Map<String, String> _legacyCityAliases = {
  'رام الله': 'ramallah',
  'القدس': 'jerusalem',
  'نابلس': 'nablus',
  'بيت لحم': 'bethlehem',
  'الخليل': 'ramallah',
};

String normalizeCityKey(String city) {
  final normalized = city.trim().toLowerCase();
  if (AppConstants.cities.containsKey(normalized)) {
    return normalized;
  }

  final alias = _legacyCityAliases[city.trim()];
  if (alias != null) {
    return alias;
  }

  return AppConstants.defaultCity;
}

String cityLabel(String cityKey) {
  return AppConstants.cities[normalizeCityKey(cityKey)] ?? cityKey;
}

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
    this.notificationsEnabled = true,
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

class WalletNotificationPreferences {
  final bool walletNotificationsEnabled;
  final bool walletExpiryRemindersEnabled;
  final bool adminWalletNotificationsEnabled;

  const WalletNotificationPreferences({
    this.walletNotificationsEnabled = true,
    this.walletExpiryRemindersEnabled = true,
    this.adminWalletNotificationsEnabled = true,
  });

  factory WalletNotificationPreferences.fromFirestore(
    Map<String, dynamic>? data,
  ) {
    final source = data ?? const <String, dynamic>{};
    return WalletNotificationPreferences(
      walletNotificationsEnabled:
          source[kWalletNotificationsEnabledField] != false,
      walletExpiryRemindersEnabled:
          source[kWalletExpiryRemindersEnabledField] != false,
      adminWalletNotificationsEnabled:
          source[kAdminWalletNotificationsEnabledField] != false,
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
  FirebaseFirestore get _firestore => ref.read(settingsFirestoreProvider);
  String? get _currentUserUid => ref.read(settingsCurrentUserUidProvider);

  void _loadFromPrefs() {
    final savedTheme = _prefs.getString(kThemeModeKey);
    final savedLang = _prefs.getString(kLanguageKey);
    final savedCity = _prefs.getString(kCityKey);
    final savedNotifications = _prefs.getBool(kNotificationsKey);

    state = SettingsState(
      themeMode: savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light,
      language: savedLang ?? kDefaultLang,
      city: normalizeCityKey(savedCity ?? kDefaultCity),
      notificationsEnabled: savedNotifications ?? true,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(
      kThemeModeKey,
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  Future<void> toggleTheme() async {
    final newMode = state.themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
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
    final cityKey = normalizeCityKey(city);
    state = state.copyWith(city: cityKey);
    await _prefs.setString(kCityKey, cityKey);
  }

  Future<void> toggleNotifications() async {
    final newVal = !state.notificationsEnabled;
    state = state.copyWith(notificationsEnabled: newVal);
    await _prefs.setBool(kNotificationsKey, newVal);
  }

  Future<void> setWalletNotificationsEnabled(bool enabled) async {
    await _updateWalletPreferences({kWalletNotificationsEnabledField: enabled});
  }

  Future<void> setWalletExpiryRemindersEnabled(bool enabled) async {
    await _updateWalletPreferences({
      kWalletExpiryRemindersEnabledField: enabled,
    });
  }

  Future<void> setAdminWalletNotificationsEnabled(bool enabled) async {
    await _updateWalletPreferences({
      kAdminWalletNotificationsEnabledField: enabled,
    });
  }

  Future<void> _updateWalletPreferences(Map<String, bool> updates) async {
    final uid = _currentUserUid;
    if (uid == null || uid.isEmpty) {
      return;
    }

    final userRef = _firestore.collection('users').doc(uid);
    try {
      await userRef.update(updates);
    } on FirebaseException catch (error) {
      if (error.code != 'not-found') {
        rethrow;
      }

      await userRef.set({
        'uid': uid,
        'created_at': FieldValue.serverTimestamp(),
        ...updates,
      }, SetOptions(merge: true));
    }
  }
}

// ============ PROVIDER ============

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});

final settingsFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final settingsCurrentUserUidProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.asData?.value?.uid;
});

final walletNotificationPreferencesProvider =
    StreamProvider<WalletNotificationPreferences>((ref) {
      final uid = ref.watch(settingsCurrentUserUidProvider);
      if (uid == null || uid.isEmpty) {
        return Stream.value(const WalletNotificationPreferences());
      }

      final firestore = ref.watch(settingsFirestoreProvider);
      return firestore.collection('users').doc(uid).snapshots().map((doc) {
        return WalletNotificationPreferences.fromFirestore(doc.data());
      });
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
