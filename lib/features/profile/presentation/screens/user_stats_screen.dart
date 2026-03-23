import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/routing/navigation_extensions.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/widgets/app_button.dart';
import 'package:wain_app/core/widgets/app_empty_state.dart';
import 'package:wain_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wain_app/features/profile/presentation/providers/settings_providers.dart';
import 'package:wain_app/features/profile/presentation/providers/user_benefit_insights_provider.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
import 'package:wain_app/l10n/app_localizations.dart';

final userReviewCountProvider = FutureProvider.family<int, String>((
  ref,
  userId,
) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    final count = ((doc.data()?['reviews_count'] as num?)?.toInt() ?? 0).clamp(
      0,
      999999,
    );
    debugPrint('User reviews count: $count');
    return count;
  } catch (e) {
    debugPrint('Error fetching user reviews: $e');
    return 0;
  }
});

class UserStatsScreen extends ConsumerWidget {
  const UserStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.asData?.value;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.statsTitle),
        leading: IconButton(
          onPressed: () => context.popOrGo('/profile'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: user == null || user.isAnonymous
          ? _LoginPrompt(onSignIn: () => context.push('/login?redirectTo=/stats'))
          : _StatsContent(user: user),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  final VoidCallback onSignIn;

  const _LoginPrompt({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppEmptyState(
              icon: Icons.bar_chart_rounded,
              message: l10n.statsLoginPrompt,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              label: l10n.profileSignIn,
              onPressed: onSignIn,
              expanded: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsContent extends ConsumerWidget {
  final dynamic user;

  const _StatsContent({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context)!;

    final userId = user.uid as String;
    final reviewCountAsync = ref.watch(userReviewCountProvider(userId));
    final insightsAsync = ref.watch(userBenefitInsightsProvider(userId));
    final favoriteCountAsync = ref.watch(favoritesCountProvider);
    final city = ref.watch(cityProvider);
    final venuesState = ref.watch(cachedVenuesProvider(city: city));

    final reviewCount = reviewCountAsync.asData?.value ?? 0;
    final favoriteCount = favoriteCountAsync.asData?.value ?? 0;
    final insights =
        insightsAsync.asData?.value ?? const UserBenefitInsights.empty();
    final venueById = {
      for (final venue in venuesState.venues.cast<Venue>()) venue.id: venue,
    };

    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withAlpha(220),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: AppSpacing.radiusLg,
              boxShadow: AppShadows.overlay,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white.withAlpha(45),
                    backgroundImage: user.photoUrl != null
                        ? NetworkImage(user.photoUrl! as String)
                        : null,
                    child: user.photoUrl == null
                        ? Text(
                            user.displayName?.isNotEmpty == true
                                ? (user.displayName as String)[0].toUpperCase()
                                : '?',
                            style: textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.statsWelcome(
                      user.displayName ?? l10n.statsDefaultName,
                    ),
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.statsActivitySummary,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withAlpha(220),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.statsTitle, style: textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _StatCard(
                icon: Icons.local_offer_rounded,
                value: insightsAsync.when(
                  data: (value) => '${value.redeemedClaims}',
                  loading: () => '...',
                  error: (_, _) => '0',
                ),
                label: l10n.statsUsedOffers,
                accent: AppTheme.warningColor,
              ),
              _StatCard(
                icon: Icons.savings_outlined,
                value: insightsAsync.when(
                  data: (value) => value.formattedSavings(),
                  loading: () => '...',
                  error: (_, _) => '0',
                ),
                label: l10n.statsConfirmedSavings,
                accent: AppTheme.successColor,
              ),
              _StatCard(
                icon: Icons.pending_actions_rounded,
                value: insightsAsync.when(
                  data: (value) => '${value.pendingClaims}',
                  loading: () => '...',
                  error: (_, _) => '0',
                ),
                label: l10n.statsActiveClaims,
                accent: colorScheme.primary,
              ),
              _StatCard(
                icon: Icons.favorite_rounded,
                value: favoriteCountAsync.when(
                  data: (total) => '$total',
                  loading: () => '...',
                  error: (_, _) => '0',
                ),
                label: l10n.statsFavorites,
                accent: AppTheme.errorColor,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _BenefitSummaryCard(insights: insights),
          const SizedBox(height: AppSpacing.xxl),
          Text(l10n.statsUsedOffersDetails, style: textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.lg),
          insightsAsync.when(
            data: (value) {
              if (value.recentUsedOffers.isEmpty) {
                return AppEmptyState(
                  icon: Icons.local_offer_outlined,
                  message:
                      '${l10n.statsNoUsedOffersYet}\n\n${l10n.statsNoUsedOffersYetSub}',
                );
              }

              return Column(
                children: value.recentUsedOffers
                    .map(
                      (detail) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _UsedOfferRow(
                          detail: detail,
                          venueName: venueById[detail.claim.venueId]?.nameAr,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => AppEmptyState(
              icon: Icons.local_offer_outlined,
              message: l10n.statsNoUsedOffersYet,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(l10n.statsAchievements, style: textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              const _AchievementBadge(
                icon: Icons.explore_rounded,
                label: null,
                unlocked: true,
                labelKey: _AchievementLabel.newExplorer,
              ),
              _AchievementBadge(
                icon: Icons.rate_review_rounded,
                label: null,
                unlocked: reviewCount > 0,
                labelKey: _AchievementLabel.reviewer,
              ),
              _AchievementBadge(
                icon: Icons.local_offer_rounded,
                label: null,
                unlocked: insights.redeemedClaims > 0,
                labelKey: _AchievementLabel.offerHunter,
              ),
              _AchievementBadge(
                icon: Icons.favorite_rounded,
                label: null,
                unlocked: favoriteCount >= 3,
                labelKey: _AchievementLabel.placeLover,
              ),
              _AchievementBadge(
                icon: Icons.workspace_premium_rounded,
                label: null,
                unlocked: reviewCount >= 5,
                labelKey: _AchievementLabel.wainExpert,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}

class _BenefitSummaryCard extends StatelessWidget {
  final UserBenefitInsights insights;

  const _BenefitSummaryCard({required this.insights});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: colorScheme.outline),
        boxShadow: AppShadows.elevated,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withAlpha(20),
                    borderRadius: AppSpacing.radiusMd,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.insights_rounded,
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    l10n.statsSavingsHint,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              insights.formattedSavings(),
              style: theme.textTheme.displayMedium?.copyWith(
                color: colorScheme.onSurface,
                fontSize: 30,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              insights.fixedAmountOfferCount > 0
                  ? '${insights.fixedAmountOfferCount} ${l10n.statsUsedOffers}'
                  : l10n.statsNoUsedOffersYet,
              style: theme.textTheme.bodyMedium,
            ),
            if (insights.extraDiscountCount > 0) ...[
              const SizedBox(height: AppSpacing.md),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: AppSpacing.radiusMd,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.statsAdditionalDiscounts,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.statsAdditionalDiscountsSub(
                          insights.extraDiscountCount,
                        ),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UsedOfferRow extends StatelessWidget {
  final UsedOfferInsight detail;
  final String? venueName;

  const _UsedOfferRow({required this.detail, this.venueName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final offer = detail.offer;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: colorScheme.outline),
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
                color: colorScheme.primaryContainer,
                borderRadius: AppSpacing.radiusMd,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.local_offer_outlined,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (venueName?.isNotEmpty == true)
                    Text(
                      venueName!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  Text(
                    offer?.titleAr.isNotEmpty == true
                        ? offer!.titleAr
                        : detail.claim.appliedOfferTitleAr?.isNotEmpty == true
                        ? detail.claim.appliedOfferTitleAr!
                        : detail.claim.offerId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    offer?.getDiscountText(l10n) ?? l10n.statsOfferUsedStatus,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _MiniBadge(
                        label: l10n.statsOfferUsedStatus,
                        accent: AppTheme.successColor,
                      ),
                      if (detail.confirmedSavings != null)
                        _MiniBadge(
                          label: l10n.statsOfferSavingsValue(
                            formatBenefitMoney(
                              detail.confirmedSavings!,
                              offer?.currency ?? 'ILS',
                            ),
                          ),
                          accent: AppTheme.warningColor,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l10n.statsUsedOnDate(_formatDate(detail.claim.timestamp)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.end,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '--/--';
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color accent;

  const _MiniBadge({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withAlpha(20),
        borderRadius: AppSpacing.radiusSm,
        border: Border.all(color: accent.withAlpha(70)),
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
          ).textTheme.labelSmall?.copyWith(color: accent),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color accent;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: 160,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: AppSpacing.radiusLg,
          border: Border.all(color: colorScheme.outline),
          boxShadow: AppShadows.elevated,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withAlpha(24),
                  borderRadius: AppSpacing.radiusMd,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: accent),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                value,
                style: textTheme.displayMedium?.copyWith(
                  fontSize: 26,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(label, style: textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

enum _AchievementLabel {
  newExplorer,
  reviewer,
  offerHunter,
  placeLover,
  wainExpert,
}

class _AchievementBadge extends StatelessWidget {
  final IconData icon;
  final String? label;
  final bool unlocked;
  final _AchievementLabel labelKey;

  const _AchievementBadge({
    required this.icon,
    required this.label,
    required this.unlocked,
    required this.labelKey,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final accent = unlocked
        ? AppTheme.warningColor
        : colorScheme.onSurfaceVariant;
    final resolvedLabel = switch (labelKey) {
      _AchievementLabel.newExplorer => l10n.statsNewExplorer,
      _AchievementLabel.reviewer => l10n.statsReviewer,
      _AchievementLabel.offerHunter => l10n.statsOfferHunter,
      _AchievementLabel.placeLover => l10n.statsPlaceLover,
      _AchievementLabel.wainExpert => l10n.statsWainExpert,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: unlocked
            ? AppTheme.warningColor.withAlpha(22)
            : colorScheme.surfaceContainerLow,
        borderRadius: AppSpacing.radiusMd,
        border: Border.all(
          color: unlocked
              ? AppTheme.warningColor.withAlpha(80)
              : colorScheme.outline,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: accent),
            const SizedBox(width: AppSpacing.sm),
            Text(
              resolvedLabel,
              style: textTheme.labelMedium?.copyWith(color: accent),
            ),
            if (unlocked) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.check_circle_rounded, size: 16, color: accent),
            ],
          ],
        ),
      ),
    );
  }
}
