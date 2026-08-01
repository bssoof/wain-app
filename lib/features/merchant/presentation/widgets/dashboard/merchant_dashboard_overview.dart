import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_venue.dart';
import 'package:wain_app/l10n/app_localizations.dart';

import 'merchant_dashboard_shared.dart';

class MerchantDashboardVenueHeaderCard extends StatelessWidget {
  final MerchantVenue venue;

  const MerchantDashboardVenueHeaderCard({super.key, required this.venue});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final photos = venue.photos;
    final moods = venue.moodLabels;
    final isOpen = venue.isOpenNow();

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [colorScheme.primary, colorScheme.primary.withAlpha(210)],
        ),
        borderRadius: AppSpacing.radiusLg,
        boxShadow: AppShadows.overlay,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: colorScheme.onPrimary.withAlpha(38),
                borderRadius: AppSpacing.radiusLg,
                image: photos.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(photos.first),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: photos.isEmpty
                  ? Icon(
                      Icons.storefront_rounded,
                      size: 30,
                      color: colorScheme.onPrimary,
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    venue.displayName.isNotEmpty
                        ? venue.displayName
                        : l10n.merchantDefaultVenueName,
                    style: textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    moods.isNotEmpty
                        ? moods.join(' • ')
                        : l10n.merchantDefaultType,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimary.withAlpha(220),
                    ),
                  ),
                  if (isOpen != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _MerchantDashboardStatusPill(
                      label: isOpen
                          ? l10n.merchantOpenNow
                          : l10n.merchantClosed,
                      color: isOpen
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                      onColor: colorScheme.onPrimary,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MerchantDashboardQuickActionsGrid extends StatelessWidget {
  const MerchantDashboardQuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final actions = <_MerchantDashboardQuickAction>[
      _MerchantDashboardQuickAction(
        icon: Icons.edit_rounded,
        label: l10n.merchantQuickActionEdit,
        route: '/merchant/edit-venue',
        color: colorScheme.primary,
      ),
      _MerchantDashboardQuickAction(
        icon: Icons.local_offer_rounded,
        label: l10n.merchantQuickActionOffers,
        route: '/merchant/offers',
        color: AppTheme.successColor,
      ),
      _MerchantDashboardQuickAction(
        icon: Icons.photo_camera_rounded,
        label: l10n.merchantQuickActionPhotos,
        route: '/merchant/photos',
        color: AppTheme.warningColor,
      ),
      _MerchantDashboardQuickAction(
        icon: Icons.rate_review_rounded,
        label: l10n.merchantQuickActionReviews,
        route: '/merchant/reviews',
        color: AppTheme.infoColor,
      ),
      _MerchantDashboardQuickAction(
        icon: Icons.restaurant_menu_rounded,
        label: l10n.merchantQuickActionMenu,
        route: '/merchant/venue/menu',
        color: colorScheme.secondary,
      ),
      _MerchantDashboardQuickAction(
        icon: Icons.access_time_rounded,
        label: l10n.merchantQuickActionHours,
        route: '/merchant/venue/hours',
        color: colorScheme.tertiary,
      ),
      _MerchantDashboardQuickAction(
        icon: Icons.auto_stories_rounded,
        label: l10n.merchantQuickActionStories,
        route: '/merchant/stories',
        color: AppTheme.primaryColor,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.02,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        final theme = Theme.of(context);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppSpacing.radiusLg,
            onTap: () => context.push(action.route),
            child: Ink(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: AppSpacing.radiusLg,
                border: Border.all(color: theme.colorScheme.outline),
                boxShadow: AppShadows.elevated,
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: action.color.withAlpha(22),
                      borderRadius: AppSpacing.radiusMd,
                    ),
                    alignment: Alignment.center,
                    child: Icon(action.icon, color: action.color, size: 24),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    action.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class MerchantDashboardVenueInfoSection extends StatelessWidget {
  final MerchantVenue venue;

  const MerchantDashboardVenueInfoSection({super.key, required this.venue});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = venue.categories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MerchantDashboardSectionTitle(title: l10n.merchantVenueInfo),
        const SizedBox(height: AppSpacing.md),
        MerchantDashboardCardShell(
          child: Column(
            children: [
              _MerchantDashboardInfoRow(
                icon: Icons.storefront_rounded,
                label: l10n.merchantInfoName,
                value: venue.displayName.isNotEmpty ? venue.displayName : '-',
              ),
              const Divider(height: AppSpacing.xl),
              _MerchantDashboardInfoRow(
                icon: Icons.location_on_outlined,
                label: l10n.merchantInfoCity,
                value: venue.city.isNotEmpty ? venue.city : '-',
              ),
              const Divider(height: AppSpacing.xl),
              _MerchantDashboardInfoRow(
                icon: Icons.phone_outlined,
                label: l10n.merchantInfoPhone,
                value: venue.phone.isNotEmpty ? venue.phone : '-',
              ),
              if (categories.isNotEmpty) ...[
                const Divider(height: AppSpacing.xl),
                _MerchantDashboardInfoRow(
                  icon: Icons.category_outlined,
                  label: l10n.merchantInfoCategory,
                  value: categories.join(', '),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MerchantDashboardInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MerchantDashboardInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: textTheme.titleSmall?.copyWith(color: colorScheme.onSurface),
          ),
        ),
      ],
    );
  }
}

class _MerchantDashboardStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color onColor;

  const _MerchantDashboardStatusPill({
    required this.label,
    required this.color,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: AppSpacing.radiusSm,
        border: Border.all(color: onColor.withAlpha(30)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: onColor),
        ),
      ),
    );
  }
}

class _MerchantDashboardQuickAction {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  const _MerchantDashboardQuickAction({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });
}
