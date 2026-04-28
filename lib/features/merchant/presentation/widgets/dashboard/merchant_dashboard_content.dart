import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_content_health.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_dashboard_providers.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

import 'merchant_dashboard_shared.dart';

class MerchantDashboardContentHealthSection extends ConsumerWidget {
  const MerchantDashboardContentHealthSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final healthAsync = ref.watch(merchantContentHealthProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MerchantDashboardSectionTitle(title: l10n.merchantContentHealthTitle),
        const SizedBox(height: AppSpacing.md),
        healthAsync.when(
          loading: () => const MerchantDashboardCardShell(
            child: Row(children: [WainLoadingIndicator(size: 20)]),
          ),
          error: (_, _) => MerchantDashboardFallbackCard(
            message: l10n.merchantContentHealthLoadFailed,
            icon: Icons.inventory_2_outlined,
          ),
          data: (health) => health.allHealthy
              ? MerchantDashboardCardShell(
                  backgroundColor: AppTheme.successColor.withAlpha(10),
                  borderColor: AppTheme.successColor.withAlpha(40),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.successColor,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.merchantContentHealthHealthyTitle,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              l10n.merchantContentHealthHealthyMessage,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : MerchantDashboardCardShell(
                  child: Column(
                    children: [
                      for (var i = 0; i < health.issues.length; i++) ...[
                        _MerchantDashboardContentHealthTile(
                          item: health.issues[i],
                        ),
                        if (i < health.issues.length - 1)
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            child: Divider(height: 1),
                          ),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _MerchantDashboardContentHealthTile extends StatelessWidget {
  final MerchantContentHealthItem item;

  const _MerchantDashboardContentHealthTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final tone = switch (item.status) {
      MerchantContentHealthStatus.healthy => AppTheme.successColor,
      MerchantContentHealthStatus.warning => AppTheme.warningColor,
      MerchantContentHealthStatus.critical => AppTheme.errorColor,
    };

    final title = switch (item.kind) {
      MerchantContentHealthKind.menu => l10n.merchantContentHealthMenuTitle,
      MerchantContentHealthKind.photos => l10n.merchantContentHealthPhotosTitle,
      MerchantContentHealthKind.stories =>
        l10n.merchantContentHealthStoriesTitle,
      MerchantContentHealthKind.hours => l10n.merchantContentHealthHoursTitle,
      MerchantContentHealthKind.profile =>
        l10n.merchantContentHealthProfileTitle,
    };

    final ctaLabel = switch (item.kind) {
      MerchantContentHealthKind.menu => l10n.merchantQuickActionMenu,
      MerchantContentHealthKind.photos => l10n.merchantQuickActionPhotos,
      MerchantContentHealthKind.stories => l10n.merchantQuickActionStories,
      MerchantContentHealthKind.hours => l10n.merchantQuickActionHours,
      MerchantContentHealthKind.profile => l10n.merchantQuickActionEdit,
    };

    final route = switch (item.kind) {
      MerchantContentHealthKind.menu => '/merchant/venue/menu',
      MerchantContentHealthKind.photos => '/merchant/photos',
      MerchantContentHealthKind.stories => '/merchant/stories',
      MerchantContentHealthKind.hours => '/merchant/venue/hours',
      MerchantContentHealthKind.profile => '/merchant/edit-venue',
    };

    final message = switch (item.kind) {
      MerchantContentHealthKind.menu =>
        item.status == MerchantContentHealthStatus.critical
            ? l10n.merchantContentHealthMenuMissing
            : l10n.merchantContentHealthMenuStale('${item.ageDays ?? 0}'),
      MerchantContentHealthKind.photos =>
        item.status == MerchantContentHealthStatus.critical
            ? l10n.merchantContentHealthPhotosCritical('${item.count ?? 0}')
            : l10n.merchantContentHealthPhotosWarning('${item.count ?? 0}'),
      MerchantContentHealthKind.stories =>
        item.status == MerchantContentHealthStatus.critical
            ? l10n.merchantContentHealthStoriesCritical('${item.ageDays ?? 0}')
            : l10n.merchantContentHealthStoriesWarning('${item.ageDays ?? 0}'),
      MerchantContentHealthKind.hours =>
        item.status == MerchantContentHealthStatus.critical
            ? l10n.merchantContentHealthHoursCritical
            : l10n.merchantContentHealthHoursWarning('${item.count ?? 0}'),
      MerchantContentHealthKind.profile =>
        item.status == MerchantContentHealthStatus.critical
            ? l10n.merchantContentHealthProfileCritical(
                '${item.missingCount ?? 0}',
              )
            : l10n.merchantContentHealthProfileWarning(
                '${item.missingCount ?? 0}',
              ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: tone.withAlpha(16),
            borderRadius: AppSpacing.radiusMd,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Icon(_iconForKind(item.kind), color: tone),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(message, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        TextButton(
          onPressed: () => context.push(route),
          style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
          child: Text(ctaLabel),
        ),
      ],
    );
  }

  IconData _iconForKind(MerchantContentHealthKind kind) {
    return switch (kind) {
      MerchantContentHealthKind.menu => Icons.restaurant_menu_rounded,
      MerchantContentHealthKind.photos => Icons.photo_library_outlined,
      MerchantContentHealthKind.stories => Icons.auto_stories_rounded,
      MerchantContentHealthKind.hours => Icons.access_time_rounded,
      MerchantContentHealthKind.profile => Icons.storefront_outlined,
    };
  }
}
