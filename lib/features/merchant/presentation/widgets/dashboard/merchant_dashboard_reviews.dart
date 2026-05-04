import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_review.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_review_quality_summary.dart';
import 'package:wain_app/l10n/app_localizations.dart';

import '../../providers/merchant_dashboard_providers.dart';
import 'merchant_dashboard_shared.dart';

class MerchantDashboardReviewsSection extends ConsumerWidget {
  const MerchantDashboardReviewsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(merchantStatsProvider);
    final l10n = AppLocalizations.of(context)!;

    return statsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (stats) {
        if (stats.recentReviews.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MerchantDashboardSectionTitle(title: l10n.merchantRecentReviews),
              const SizedBox(height: AppSpacing.md),
              MerchantDashboardFallbackCard(message: l10n.merchantNoReviewsYet),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MerchantDashboardSectionTitle(title: l10n.merchantRecentReviews),
            const SizedBox(height: AppSpacing.md),
            ...stats.recentReviews.map(MerchantDashboardReviewCard.new),
          ],
        );
      },
    );
  }
}

class MerchantDashboardReviewQualityCard extends ConsumerWidget {
  const MerchantDashboardReviewQualityCard({super.key});

  Color _replyRateTone(double rate) {
    if (rate > 80) {
      return AppTheme.successColor;
    }
    if (rate >= 50) {
      return AppTheme.warningColor;
    }
    return AppTheme.errorColor;
  }

  String _formatAverageReplyTime(
    AppLocalizations l10n,
    MerchantReviewQualitySummary summary,
  ) {
    final duration = summary.averageReplyTime;
    if (duration == null) {
      return l10n.merchantReviewNoReplyDataYet;
    }
    if (duration < const Duration(hours: 1)) {
      return l10n.merchantReviewAverageReplyUnderOneHour;
    }
    if (duration < const Duration(days: 1)) {
      return l10n.merchantReviewAverageReplyHours('${duration.inHours}');
    }
    return l10n.merchantReviewAverageReplyDays('${duration.inDays}');
  }

  String? _formatOldestUnanswered(
    AppLocalizations l10n,
    MerchantReviewQualitySummary summary,
    DateTime now,
  ) {
    final oldest = summary.oldestUnanswered;
    final createdAt = oldest?.createdAt;
    if (createdAt == null) {
      return null;
    }
    final age = now.difference(createdAt);
    if (age < const Duration(hours: 1)) {
      return l10n.merchantReviewOldestUnansweredUnderOneHour;
    }
    if (age < const Duration(days: 1)) {
      return l10n.merchantReviewOldestUnansweredHours('${age.inHours}');
    }
    return l10n.merchantReviewOldestUnansweredDays('${age.inDays}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(merchantReviewsProvider);
    final l10n = AppLocalizations.of(context)!;

    return reviewsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (reviews) {
        if (reviews.isEmpty) {
          return const SizedBox.shrink();
        }

        final summary = buildMerchantReviewQualitySummary(reviews);
        if (!summary.hasReviews) {
          return const SizedBox.shrink();
        }

        final now = DateTime.now();
        final colorScheme = Theme.of(context).colorScheme;
        final oldestUnansweredLabel = _formatOldestUnanswered(
          l10n,
          summary,
          now,
        );

        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: MerchantDashboardCardShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.merchantReviewQualityTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    MerchantDashboardMetricChip(
                      icon: Icons.reply_rounded,
                      label: l10n.merchantReviewReplyRate(
                        summary.replyRatePercent.toStringAsFixed(0),
                      ),
                      tone: _replyRateTone(summary.replyRatePercent),
                    ),
                    MerchantDashboardMetricChip(
                      icon: Icons.schedule_rounded,
                      label: _formatAverageReplyTime(l10n, summary),
                      tone: summary.averageReplyTime == null
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.primary,
                    ),
                  ],
                ),
                if (oldestUnansweredLabel != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Icon(
                        Icons.mark_email_unread_rounded,
                        size: 18,
                        color: AppTheme.warningColor,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          oldestUnansweredLabel,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class MerchantDashboardReviewCard extends StatelessWidget {
  final MerchantReview review;

  const MerchantDashboardReviewCard(this.review, {super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final rating = review.rating;
    final comment = review.trimmedText;
    final userName = review.trimmedUserName.isNotEmpty
        ? review.trimmedUserName
        : l10n.merchantDefaultUser;
    final createdAt = review.createdAt;
    final dateStr = createdAt != null
        ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: MerchantDashboardCardShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ...List.generate(
                  5,
                  (index) => Icon(
                    index < rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 16,
                    color: AppTheme.warningColor,
                  ),
                ),
                const Spacer(),
                Text(dateStr, style: textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(userName, style: textTheme.titleMedium),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                comment,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
