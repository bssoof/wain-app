import 'package:flutter/material.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/profile/presentation/providers/settings_providers.dart';
import 'package:wain_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_dashboard_providers.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

/// Profile/Settings Screen
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final authStateAsync = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(AppLocalizations.of(context)!.profileTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Header - Dynamic based on auth state
          authStateAsync.when(
            data: (user) => _buildProfileHeader(context, ref, user),
            loading: () => const Center(child: WainLoadingIndicator()),
            error: (_, _) => _buildGuestHeader(context),
          ),

          const SizedBox(height: 32),

          // My Activity
          _buildSectionTitle(AppLocalizations.of(context)!.profileSectionActivity),
          const SizedBox(height: 12),

          _buildSettingItem(
            context,
            icon: Icons.confirmation_number_outlined,
            title: AppLocalizations.of(context)!.profileMyOffers,
            subtitle: AppLocalizations.of(context)!.profileMyOffersSubtitle,
            onTap: () => context.push('/my-claims'),
          ),

          _buildSettingItem(
            context,
            icon: Icons.bookmark_outlined,
            title: AppLocalizations.of(context)!.profileSavedOffers,
            subtitle: AppLocalizations.of(context)!.profileSavedOffersSubtitle,
            onTap: () => context.push('/saved-offers'),
          ),

          _buildSettingItem(
            context,
            icon: Icons.bar_chart_rounded,
            title: AppLocalizations.of(context)!.profileMyStats,
            subtitle: AppLocalizations.of(context)!.profileMyStatsSubtitle,
            onTap: () => context.push('/stats'),
          ),

          _buildSettingItem(
            context,
            icon: Icons.flag_outlined,
            title: AppLocalizations.of(context)!.profileTryList,
            subtitle: AppLocalizations.of(context)!.profileTryListSubtitle,
            onTap: () => context.push('/try-list'),
          ),

          // Merchant Section
          ref
              .watch(merchantVenueIdProvider)
              .when(
                data: (venueId) => venueId != null
                    ? _buildSettingItem(
                        context,
                        icon: Icons.dashboard_rounded,
                        title: AppLocalizations.of(context)!.profileMerchantDashboard,
                        subtitle: AppLocalizations.of(context)!.profileMerchantDashboardSubtitle,
                        onTap: () => context.push('/merchant/dashboard'),
                      )
                    : _buildSettingItem(
                        context,
                        icon: Icons.store_outlined,
                        title: AppLocalizations.of(context)!.profileJoinMerchant,
                        subtitle: AppLocalizations.of(context)!.profileJoinMerchantSubtitle,
                        onTap: () => context.push('/merchant/invite'),
                      ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),

          const SizedBox(height: 24),

          // Settings Section
          _buildSectionTitle(AppLocalizations.of(context)!.profileSectionSettings),
          const SizedBox(height: 12),

          // City Picker
          _buildSettingItem(
            context,
            icon: Icons.location_on_outlined,
            title: AppLocalizations.of(context)!.profileCity,
            subtitle: settings.city,
            onTap: () => _showCityPicker(context, ref),
          ),

          // Language Toggle
          _buildSettingItem(
            context,
            icon: Icons.language,
            title: AppLocalizations.of(context)!.profileLanguage,
            subtitle: settings.language == 'ar' ? AppLocalizations.of(context)!.profileLanguageAr : 'English',
            trailing: Switch(
              value: settings.language == 'ar',
              onChanged: (_) =>
                  ref.read(settingsProvider.notifier).toggleLanguage(),
              activeTrackColor: AppTheme.primaryColor,
            ),
            onTap: () => ref.read(settingsProvider.notifier).toggleLanguage(),
          ),

          // Theme Toggle
          _buildSettingItem(
            context,
            icon: settings.themeMode == ThemeMode.dark
                ? Icons.dark_mode
                : Icons.light_mode_outlined,
            title: AppLocalizations.of(context)!.profileTheme,
            subtitle: settings.themeMode == ThemeMode.dark ? AppLocalizations.of(context)!.profileThemeDark : AppLocalizations.of(context)!.profileThemeLight,
            trailing: Switch(
              value: settings.themeMode == ThemeMode.dark,
              onChanged: (_) =>
                  ref.read(settingsProvider.notifier).toggleTheme(),
              activeTrackColor: AppTheme.primaryColor,
            ),
            onTap: () => ref.read(settingsProvider.notifier).toggleTheme(),
          ),

          // Geofence toggle
          _buildSettingItem(
            context,
            icon: Icons.near_me_outlined,
            title: AppLocalizations.of(context)!.profileGeofenceNotifs,
            subtitle: AppLocalizations.of(context)!.profileGeofenceNotifsSubtitle,
            trailing: Switch(
              value: settings.notificationsEnabled,
              onChanged: (_) =>
                  ref.read(settingsProvider.notifier).toggleNotifications(),
              activeTrackColor: AppTheme.primaryColor,
            ),
            onTap: () =>
                ref.read(settingsProvider.notifier).toggleNotifications(),
          ),

          const SizedBox(height: 24),

          // About Section
          _buildSectionTitle(AppLocalizations.of(context)!.profileSectionAbout),
          const SizedBox(height: 12),

          _buildSettingItem(
            context,
            icon: Icons.info_outline,
            title: AppLocalizations.of(context)!.profileAboutWain,
            onTap: () => context.push('/about'),
          ),
          _buildSettingItem(
            context,
            icon: Icons.privacy_tip_outlined,
            title: AppLocalizations.of(context)!.profilePrivacy,
            onTap: () => context.push('/privacy'),
          ),
          _buildSettingItem(
            context,
            icon: Icons.help_outline,
            title: AppLocalizations.of(context)!.profileHelp,
            onTap: () => context.push('/help'),
          ),

          const SizedBox(height: 32),

          // Version
          Center(
            child: Text(
               AppLocalizations.of(context)!.profileVersion('1.0.0'),
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 32),

          // Merchant Access (MVP)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: () => context.push('/merchant/scan'),
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(AppLocalizations.of(context)!.profileMerchantScan),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.grey.shade400),
                foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: AppTheme.textSecondary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }

  void _showCityPicker(BuildContext context, WidgetRef ref) {
    final currentCity = ref.read(settingsProvider).city;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
               AppLocalizations.of(context)!.profileChooseCity,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            ...kAvailableCities.map(
              (city) => ListTile(
                onTap: () {
                  ref.read(settingsProvider.notifier).setCity(city);
                  Navigator.pop(ctx);
                },
                leading: Icon(
                  city == currentCity
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: city == currentCity
                      ? AppTheme.primaryColor
                      : Colors.grey,
                ),
                title: Text(city),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Build profile header for logged-in user or guest
  Widget _buildProfileHeader(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
  ) {
    if (user == null || user.isAnonymous == true) {
      return _buildGuestHeader(context);
    }

    // Logged-in user UI
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.primaryColor.withAlpha(25),
                backgroundImage: user.photoUrl != null
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: user.photoUrl == null
                    ? const Icon(
                        Icons.person,
                        size: 30,
                        color: AppTheme.primaryColor,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? user.email ?? AppLocalizations.of(context)!.profileUser,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (user.username != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@${user.username}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (user.email != null && user.username == null) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.email!,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Edit Profile Button
              IconButton(
                onPressed: () => context.push('/edit-profile'),
                icon: const Icon(Icons.edit, size: 20),
                color: AppTheme.primaryColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Sign Out Button
        OutlinedButton.icon(
          onPressed: () async {
            await ref.read(authActionsProvider.notifier).signOut();
          },
          icon: const Icon(Icons.logout, color: Colors.red),
           label: Text(
             AppLocalizations.of(context)!.profileSignOut,
             style: const TextStyle(color: Colors.red),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  /// Build guest header with login prompt
  Widget _buildGuestHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 30,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                       AppLocalizations.of(context)!.profileGuestUser,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                       AppLocalizations.of(context)!.profileGuestSubtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Login Button
        ElevatedButton.icon(
          onPressed: () => context.push('/login'),
          icon: const Icon(Icons.phone),
           label: Text(AppLocalizations.of(context)!.profileSignIn),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
