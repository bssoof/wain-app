import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/widgets/app_button.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_action_item.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_action_feed_provider.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class MerchantActionFeed extends ConsumerWidget {
  final Future<void> Function() onRefreshRequested;

  const MerchantActionFeed({super.key, required this.onRefreshRequested});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(merchantActionFeedProvider);
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.merchantActionFeedTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.md),
        ...actions.map(
          (action) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _ActionCard(
              action: action,
              onRefreshRequested: onRefreshRequested,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final MerchantActionItem action;
  final Future<void> Function() onRefreshRequested;

  const _ActionCard({required this.action, required this.onRefreshRequested});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final presentation = _presentationFor(context, l10n, action);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: presentation.backgroundColor,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: presentation.borderColor),
        boxShadow: AppShadows.elevated,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: presentation.iconColor.withAlpha(22),
                borderRadius: AppSpacing.radiusMd,
              ),
              alignment: Alignment.center,
              child: Icon(
                presentation.icon,
                color: presentation.iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    presentation.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    presentation.subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton.tertiary(
                    label: presentation.ctaLabel,
                    onPressed: presentation.onPressed,
                    icon: Icon(presentation.ctaIcon, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _ActionPresentation _presentationFor(
    BuildContext context,
    AppLocalizations l10n,
    MerchantActionItem action,
  ) {
    return switch (action) {
      RefreshAnalyticsAction item => _ActionPresentation(
        icon: Icons.insights_rounded,
        iconColor: Theme.of(context).colorScheme.primary,
        borderColor: Theme.of(context).colorScheme.primary.withAlpha(90),
        backgroundColor: Theme.of(
          context,
        ).colorScheme.primaryContainer.withAlpha(40),
        title: l10n.merchantActionRefreshAnalyticsTitle,
        subtitle: l10n.merchantActionRefreshAnalyticsBody(
          _staleHours(item.lastUpdated).toString(),
        ),
        ctaLabel: l10n.merchantActionRefreshAnalyticsCta,
        ctaIcon: Icons.refresh_rounded,
        onPressed: () => onRefreshRequested(),
      ),
      ExpiringOfferAction item => _ActionPresentation(
        icon: Icons.timer_outlined,
        iconColor: AppTheme.warningColor,
        borderColor: AppTheme.warningColor.withAlpha(90),
        backgroundColor: AppTheme.warningColor.withAlpha(12),
        title: l10n.merchantActionExpiringOfferTitle,
        subtitle: l10n.merchantActionExpiringOfferBody(
          item.offerTitle,
          _remainingHours(item.expiresAt).toString(),
        ),
        ctaLabel: l10n.merchantQuickActionOffers,
        ctaIcon: Icons.arrow_outward_rounded,
        onPressed: () => context.push(
          '/merchant/offers',
          extra: {'highlight': item.offerId},
        ),
      ),
      ExpiredOfferAction item => _ActionPresentation(
        icon: Icons.event_busy_rounded,
        iconColor: AppTheme.errorColor,
        borderColor: AppTheme.errorColor.withAlpha(90),
        backgroundColor: AppTheme.errorColor.withAlpha(10),
        title: l10n.merchantActionExpiredOfferTitle,
        subtitle: l10n.merchantActionExpiredOfferBody(item.offerTitle),
        ctaLabel: l10n.merchantQuickActionOffers,
        ctaIcon: Icons.arrow_outward_rounded,
        onPressed: () => context.push(
          '/merchant/offers',
          extra: {'highlight': item.offerId},
        ),
      ),
      UnansweredReviewsAction item => _ActionPresentation(
        icon: Icons.rate_review_rounded,
        iconColor: AppTheme.infoColor,
        borderColor: AppTheme.infoColor.withAlpha(90),
        backgroundColor: AppTheme.infoColor.withAlpha(10),
        title: l10n.merchantActionUnansweredReviewsTitle,
        subtitle: l10n.merchantActionUnansweredReviewsBody(item.count),
        ctaLabel: l10n.merchantActionReviewsReplyCta,
        ctaIcon: Icons.arrow_outward_rounded,
        onPressed: () =>
            context.push('/merchant/reviews', extra: {'filter': 0}),
      ),
      NoActiveOffersAction item => _ActionPresentation(
        icon: Icons.lightbulb_outline_rounded,
        iconColor: AppTheme.successColor,
        borderColor: AppTheme.successColor.withAlpha(90),
        backgroundColor: AppTheme.successColor.withAlpha(10),
        title: l10n.merchantActionNoActiveOffersTitle,
        subtitle: l10n.merchantActionNoActiveOffersBody(item.viewsThisWeek),
        ctaLabel: l10n.merchantOffersNewOffer,
        ctaIcon: Icons.add_rounded,
        onPressed: () => context.push('/merchant/offers'),
      ),
    };
  }

  int _staleHours(DateTime? lastUpdated) {
    if (lastUpdated == null) {
      return 24;
    }
    final difference = DateTime.now().difference(lastUpdated);
    return difference.inHours <= 0 ? 1 : difference.inHours;
  }

  int _remainingHours(DateTime expiresAt) {
    final difference = expiresAt.difference(DateTime.now());
    return difference.inHours <= 0 ? 1 : difference.inHours;
  }
}

class _ActionPresentation {
  final IconData icon;
  final Color iconColor;
  final Color borderColor;
  final Color backgroundColor;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final IconData ctaIcon;
  final VoidCallback onPressed;

  const _ActionPresentation({
    required this.icon,
    required this.iconColor,
    required this.borderColor,
    required this.backgroundColor,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.ctaIcon,
    required this.onPressed,
  });
}
