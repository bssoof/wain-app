import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/widgets/app_button.dart';
import 'package:wain_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_dashboard_providers.dart';
import 'package:wain_app/features/profile/presentation/providers/settings_providers.dart';
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
    final merchantVenueIdAsync = ref.watch(merchantVenueIdProvider);
    final theme = Theme.of(context);

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

    final merchantTile = merchantVenueIdAsync.when<Widget?>(
      data: (venueId) {
        if (venueId != null) {
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
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
          _buildSectionCard(context, [
            _buildSettingItem(
              context,
              icon: Icons.location_on_outlined,
              title: l10n.profileCity,
              subtitle: settings.city,
              onTap: () => _showCityPicker(context, ref),
            ),
            _buildSettingItem(
              context,
              icon: Icons.language_rounded,
              title: l10n.profileLanguage,
              subtitle: settings.language == 'ar'
                  ? l10n.profileLanguageAr
                  : 'English',
              trailing: Switch.adaptive(
                value: settings.language == 'ar',
                onChanged: (_) =>
                    ref.read(settingsProvider.notifier).toggleLanguage(),
                activeTrackColor: theme.colorScheme.primary,
              ),
              onTap: () => ref.read(settingsProvider.notifier).toggleLanguage(),
            ),
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
                onChanged: (_) =>
                    ref.read(settingsProvider.notifier).toggleTheme(),
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
              onTap: () =>
                  ref.read(settingsProvider.notifier).toggleNotifications(),
            ),
          ]),
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
          const SizedBox(height: AppSpacing.xxl),
          AppButton.secondary(
            label: l10n.profileMerchantScan,
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
            onPressed: () => context.push('/merchant/scan'),
          ),
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

  void _showCityPicker(BuildContext context, WidgetRef ref) {
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
                  (city) => ListTile(
                    onTap: () {
                      ref.read(settingsProvider.notifier).setCity(city);
                      Navigator.of(sheetContext).pop();
                    },
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      city == currentCity
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: city == currentCity
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(city, style: theme.textTheme.titleMedium),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
          onPressed: () => context.push('/login'),
        ),
      ],
    );
  }
}
