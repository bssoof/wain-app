import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/constants/app_constants.dart';
import 'package:wain_app/core/routing/app_router.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/widgets/app_button.dart';
import 'package:wain_app/features/admin/presentation/providers/admin_topup_review_providers.dart';
import 'package:wain_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:wain_app/features/discovery/presentation/providers/search_state.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_dashboard_providers.dart';
import 'package:wain_app/features/profile/presentation/providers/settings_providers.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

/// Profile and settings hub with grouped sections and preserved behavior.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final authStateAsync = ref.watch(authStateProvider);
    final merchantAccessAsync = ref.watch(merchantRouteAccessProvider);
    final theme = Theme.of(context);
    final isLoggedIn = authStateAsync.asData?.value != null;
    final adminAccessAsync = isLoggedIn
        ? ref.watch(adminAccessProvider)
        : const AsyncValue<bool>.data(false);
    final walletPrefsAsync = isLoggedIn
        ? ref.watch(walletNotificationPreferencesProvider)
        : const AsyncValue<WalletNotificationPreferences>.data(
            WalletNotificationPreferences(),
          );
    final hasMerchantWalletSettings =
        merchantAccessAsync.asData?.value.isReady == true;
    final hasAdminWalletSettings = adminAccessAsync.asData?.value == true;
    final walletPrefs =
        walletPrefsAsync.asData?.value ?? const WalletNotificationPreferences();
    final walletPrefsReady = !walletPrefsAsync.isLoading;
    final cityVenueStates = {
      for (final cityKey in kAvailableCities)
        cityKey: ref.watch(cachedVenuesProvider(city: cityKey)),
    };

    final activityTiles = <Widget>[
      _buildSettingItem(
        context,
        icon: Icons.confirmation_number_outlined,
        title: l10n.profileMyOffers,
        subtitle: l10n.profileMyOffersSubtitle,
        onTap: () => context.push('/my-claims'),
      ),
      _buildSettingItem(
        context,
        icon: Icons.bookmark_outline_rounded,
        title: l10n.profileSavedOffers,
        subtitle: l10n.profileSavedOffersSubtitle,
        onTap: () => context.push('/saved-offers'),
      ),
      _buildSettingItem(
        context,
        icon: Icons.bar_chart_rounded,
        title: l10n.profileMyStats,
        subtitle: l10n.profileMyStatsSubtitle,
        onTap: () => context.push('/stats'),
      ),
      _buildSettingItem(
        context,
        icon: Icons.flag_outlined,
        title: l10n.profileTryList,
        subtitle: l10n.profileTryListSubtitle,
        onTap: () => context.push('/try-list'),
      ),
    ];

    final merchantTile = merchantAccessAsync.when<Widget?>(
      data: (access) {
        if (access.isReady) {
          return _buildSettingItem(
            context,
            icon: Icons.dashboard_rounded,
            title: l10n.profileMerchantDashboard,
            subtitle: l10n.profileMerchantDashboardSubtitle,
            onTap: () => context.push('/merchant/dashboard'),
          );
        }
        return _buildSettingItem(
          context,
          icon: Icons.store_outlined,
          title: l10n.profileJoinMerchant,
          subtitle: l10n.profileJoinMerchantSubtitle,
          onTap: () => context.push('/merchant/invite'),
        );
      },
      loading: () => null,
      error: (_, _) => null,
    );

    if (merchantTile != null) {
      activityTiles.add(merchantTile);
    }

    if (adminAccessAsync.asData?.value == true) {
      activityTiles.add(
        _buildSettingItem(
          context,
          icon: Icons.admin_panel_settings_outlined,
          title: l10n.profileAdminTopUpReview,
          subtitle: l10n.profileAdminTopUpReviewSubtitle,
          onTap: () => context.push(AppRoutes.adminTopUps),
        ),
      );
    }

    final settingsTiles = <Widget>[
      _buildSettingItem(
        context,
        icon: Icons.location_on_outlined,
        title: l10n.profileCity,
        subtitle: cityLabel(settings.city),
        onTap: () => _showCityPicker(
          context,
          ref,
          cityVenueStates,
        ),
      ),
      _buildLanguageSettingBox(context, ref, settings.language),
      _buildSettingItem(
        context,
        icon: settings.themeMode == ThemeMode.dark
            ? Icons.dark_mode_rounded
            : Icons.light_mode_outlined,
        title: l10n.profileTheme,
        subtitle: settings.themeMode == ThemeMode.dark
            ? l10n.profileThemeDark
            : l10n.profileThemeLight,
        trailing: Switch.adaptive(
          value: settings.themeMode == ThemeMode.dark,
          onChanged: (_) => ref.read(settingsProvider.notifier).toggleTheme(),
          activeTrackColor: theme.colorScheme.primary,
        ),
        onTap: () => ref.read(settingsProvider.notifier).toggleTheme(),
      ),
      _buildSettingItem(
        context,
        icon: Icons.near_me_outlined,
        title: l10n.profileGeofenceNotifs,
        subtitle: l10n.profileGeofenceNotifsSubtitle,
        trailing: Switch.adaptive(
          value: settings.notificationsEnabled,
          onChanged: (_) =>
              ref.read(settingsProvider.notifier).toggleNotifications(),
          activeTrackColor: theme.colorScheme.primary,
        ),
        onTap: () => ref.read(settingsProvider.notifier).toggleNotifications(),
      ),
    ];

    if (hasMerchantWalletSettings) {
      settingsTiles.addAll([
        _buildSettingItem(
          context,
          icon: Icons.account_balance_wallet_outlined,
          title: l10n.profileWalletNotifications,
          subtitle: l10n.profileWalletNotificationsSubtitle,
          trailing: Switch.adaptive(
            value: walletPrefs.walletNotificationsEnabled,
            onChanged: walletPrefsReady
                ? (value) => ref
                      .read(settingsProvider.notifier)
                      .setWalletNotificationsEnabled(value)
                : null,
            activeTrackColor: theme.colorScheme.primary,
          ),
          onTap: walletPrefsReady
              ? () => ref
                    .read(settingsProvider.notifier)
                    .setWalletNotificationsEnabled(
                      !walletPrefs.walletNotificationsEnabled,
                    )
              : () {},
        ),
        _buildSettingItem(
          context,
          icon: Icons.schedule_outlined,
          title: l10n.profileWalletExpiryReminders,
          subtitle: l10n.profileWalletExpiryRemindersSubtitle,
          trailing: Switch.adaptive(
            value: walletPrefs.walletExpiryRemindersEnabled,
            onChanged: walletPrefsReady
                ? (value) => ref
                      .read(settingsProvider.notifier)
                      .setWalletExpiryRemindersEnabled(value)
                : null,
            activeTrackColor: theme.colorScheme.primary,
          ),
          onTap: walletPrefsReady
              ? () => ref
                    .read(settingsProvider.notifier)
                    .setWalletExpiryRemindersEnabled(
                      !walletPrefs.walletExpiryRemindersEnabled,
                    )
              : () {},
        ),
      ]);
    }

    if (hasAdminWalletSettings) {
      settingsTiles.add(
        _buildSettingItem(
          context,
          icon: Icons.admin_panel_settings_outlined,
          title: l10n.profileAdminWalletNotifications,
          subtitle: l10n.profileAdminWalletNotificationsSubtitle,
          trailing: Switch.adaptive(
            value: walletPrefs.adminWalletNotificationsEnabled,
            onChanged: walletPrefsReady
                ? (value) => ref
                      .read(settingsProvider.notifier)
                      .setAdminWalletNotificationsEnabled(value)
                : null,
            activeTrackColor: theme.colorScheme.primary,
          ),
          onTap: walletPrefsReady
              ? () => ref
                    .read(settingsProvider.notifier)
                    .setAdminWalletNotificationsEnabled(
                      !walletPrefs.adminWalletNotificationsEnabled,
                    )
              : () {},
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/results'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.profileTitle),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          authStateAsync.when(
            data: (user) => _buildProfileHeader(context, ref, user),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: WainLoadingIndicator(),
              ),
            ),
            error: (_, _) => _buildGuestHeader(context),
          ),
          const SizedBox(height: AppSpacing.xxl),
          _buildSectionTitle(context, l10n.profileSectionActivity),
          const SizedBox(height: AppSpacing.md),
          _buildSectionCard(context, activityTiles),
          const SizedBox(height: AppSpacing.xxl),
          _buildSectionTitle(context, l10n.profileSectionSettings),
          const SizedBox(height: AppSpacing.md),
          _buildSectionCard(context, settingsTiles),
          const SizedBox(height: AppSpacing.xxl),
          _buildSectionTitle(context, l10n.profileSectionAbout),
          const SizedBox(height: AppSpacing.md),
          _buildSectionCard(context, [
            _buildSettingItem(
              context,
              icon: Icons.info_outline_rounded,
              title: l10n.profileAboutWain,
              onTap: () => context.push('/about'),
            ),
            _buildSettingItem(
              context,
              icon: Icons.privacy_tip_outlined,
              title: l10n.profilePrivacy,
              onTap: () => context.push('/privacy'),
            ),
            _buildSettingItem(
              context,
              icon: Icons.help_outline_rounded,
              title: l10n.profileHelp,
              onTap: () => context.push('/help'),
            ),
          ]),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Text(
              l10n.profileVersion('1.0.0'),
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildLanguageSettingBox(
    BuildContext context,
    WidgetRef ref,
    String selectedLanguage,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Icon(
              Icons.language_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.profileLanguage, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  selectedLanguage == 'ar' ? l10n.profileLanguageAr : 'English',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _LanguageChoiceBox(
                        label: l10n.profileLanguageAr,
                        selected: selectedLanguage == 'ar',
                        onTap: () => ref
                            .read(settingsProvider.notifier)
                            .setLanguage('ar'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _LanguageChoiceBox(
                        label: 'English',
                        selected: selectedLanguage == 'en',
                        onTap: () => ref
                            .read(settingsProvider.notifier)
                            .setLanguage('en'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, List<Widget> children) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: AppShadows.elevated,
      ),
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              Divider(
                height: 1,
                indent: AppSpacing.xl,
                endIndent: AppSpacing.xl,
                color: theme.colorScheme.outline,
              ),
          ],
        ],
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
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      minVerticalPadding: AppSpacing.sm,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(title, style: theme.textTheme.titleMedium),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: theme.textTheme.bodyMedium),
      trailing:
          trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
    );
  }

  void _showCityPicker(
    BuildContext context,
    WidgetRef ref,
    Map<String, VenuesState> cityVenueStates,
  ) {
    final currentCity = ref.read(settingsProvider).city;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.profileChooseCity,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.md),
                ...kAvailableCities.map(
                  (cityKey) {
                    final venuesState = cityVenueStates[cityKey];
                    final isSelected = cityKey == currentCity;

                    Widget? trailing;
                    if (venuesState == null) {
                      trailing = null;
                    } else if (venuesState.isLoading &&
                        venuesState.venues.isEmpty) {
                      trailing = const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    } else if (venuesState.error != null &&
                        venuesState.venues.isEmpty) {
                      trailing = Icon(
                        Icons.error_outline_rounded,
                        size: 18,
                        color: theme.colorScheme.error,
                      );
                    } else {
                      trailing = _CityCountBadge(count: venuesState.venues.length);
                    }

                    return ListTile(
                      onTap: () async {
                        await _handleCitySelection(
                          context,
                          ref,
                          selectedCity: cityKey,
                          currentCity: currentCity,
                        );
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      title: Text(
                        AppConstants.cities[cityKey] ?? cityLabel(cityKey),
                        style: theme.textTheme.titleMedium,
                      ),
                      trailing: trailing,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleCitySelection(
    BuildContext context,
    WidgetRef ref, {
    required String selectedCity,
    required String currentCity,
  }) async {
    if (selectedCity == currentCity) {
      return;
    }

    final settingsNotifier = ref.read(settingsProvider.notifier);
    final searchNotifier = ref.read(searchProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    await settingsNotifier.setCity(selectedCity);
    searchNotifier.setCity(selectedCity);

    final selectedState = ref.read(cachedVenuesProvider(city: selectedCity));
    if (selectedState.isLoading && selectedState.venues.isEmpty) {
      await ref.read(cachedVenuesProvider(city: selectedCity).notifier).refresh();
    }

    final refreshedSelected = ref.read(cachedVenuesProvider(city: selectedCity));

    if (refreshedSelected.error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errServer)),
      );
      return;
    }

    final selectedCount = refreshedSelected.venues.length;
    if (selectedCount > 0 || !context.mounted) {
      return;
    }

    final selectedLabel = cityLabel(selectedCity);
    final hasFallback = selectedCity != AppConstants.defaultCity;

    if (!hasFallback) {
      final emptyMsg = isArabic
          ? 'لا توجد أماكن متاحة حاليا في $selectedLabel.'
          : 'No venues are currently available in $selectedLabel.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(emptyMsg)));
      return;
    }

    final fallbackCity = AppConstants.defaultCity;
    final fallbackLabel = cityLabel(fallbackCity);
    await settingsNotifier.setCity(fallbackCity);
    searchNotifier.setCity(fallbackCity);
    await ref.read(cachedVenuesProvider(city: fallbackCity).notifier).refresh();

    if (!context.mounted) {
      return;
    }

    final fallbackMsg = isArabic
        ? 'لا توجد أماكن حاليا في $selectedLabel. تم التحويل تلقائيا إلى $fallbackLabel.'
        : 'No venues are currently available in $selectedLabel. Switched to $fallbackLabel automatically.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(fallbackMsg)),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
  ) {
    if (user == null || user.isAnonymous == true) {
      return _buildGuestHeader(context);
    }

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppSpacing.radiusLg,
            border: Border.all(color: theme.colorScheme.outline),
            boxShadow: AppShadows.elevated,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: user.photoUrl != null
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: user.photoUrl == null
                    ? Icon(
                        Icons.person_rounded,
                        size: 30,
                        color: theme.colorScheme.primary,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? user.email ?? l10n.profileUser,
                      style: theme.textTheme.titleLarge,
                    ),
                    if (user.username != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '@${user.username}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                    if (user.email != null && user.username == null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(user.email!, style: theme.textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.push('/edit-profile'),
                icon: const Icon(Icons.edit_outlined),
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton.danger(
          label: l10n.profileSignOut,
          icon: const Icon(Icons.logout_rounded, size: 18),
          onPressed: () async {
            await ref.read(authActionsProvider.notifier).signOut();
          },
        ),
      ],
    );
  }

  Widget _buildGuestHeader(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppSpacing.radiusLg,
            border: Border.all(color: theme.colorScheme.outline),
            boxShadow: AppShadows.elevated,
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: 30,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.profileGuestUser,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.profileGuestSubtitle,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton.primary(
          label: l10n.profileSignIn,
          icon: const Icon(Icons.phone_rounded, size: 18),
          onPressed: () => context.push('/login?redirectTo=/profile'),
        ),
      ],
    );
  }
}

class _LanguageChoiceBox extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageChoiceBox({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppSpacing.radiusMd,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest.withAlpha(130),
            borderRadius: AppSpacing.radiusMd,
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selected) ...[
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CityCountBadge extends StatelessWidget {
  final int count;

  const _CityCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: AppSpacing.radiusFull,
      ),
      child: Text(
        count.toString(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
