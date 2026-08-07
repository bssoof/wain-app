import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:wain_app/features/profile/presentation/screens/user_stats_screen.dart';
import 'package:wain_app/features/reviews/domain/entities/review.dart';
import 'package:wain_app/features/reviews/presentation/providers/reviews_provider.dart';
import 'package:wain_app/features/reviews/presentation/widgets/review_form_sheet.dart';
import 'package:wain_app/features/reviews/presentation/widgets/star_rating_widget.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Reviews section widget for venue details screen
class ReviewsSection extends ConsumerWidget {
  final String venueId;
  final String venueName;
  static const double _avatarSize = 36;
  static const int _avatarCacheSize = 96;

  const ReviewsSection({
    super.key,
    required this.venueId,
    required this.venueName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(venueReviewsProvider(venueId));
    final currentUser = ref.watch(authStateProvider).asData?.value;
    final currentUserId = currentUser?.uid;
    final canAddReview = currentUser != null && !currentUser.isAnonymous;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.star_rounded, color: Colors.amber.shade700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.reviewsSectionTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildAddReviewButton(context, ref),
          ],
        ),
        const SizedBox(height: 16),
        reviewsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: WainLoadingIndicator(),
            ),
          ),
          error: (error, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade400),
                const SizedBox(width: 12),
                Text(l10n.reviewsSectionLoadFail),
              ],
            ),
          ),
          data: (reviews) {
            if (reviews.isEmpty) {
              return _buildEmptyState(context, canAddReview);
            }

            return Column(
              children: [
                _buildRatingSummary(context, reviews),
                const SizedBox(height: 16),
                ...reviews
                    .take(5)
                    .map(
                      (review) =>
                          _buildReviewCard(context, ref, review, currentUserId),
                    ),
                if (reviews.length > 5)
                  TextButton(
                    onPressed: () =>
                        _showAllReviews(context, reviews, currentUserId),
                    child: Text(
                      l10n.reviewsSectionViewAllCount(reviews.length),
                      style: const TextStyle(color: AppTheme.primaryColor),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildAddReviewButton(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.asData?.value;

    if (user == null || user.isAnonymous) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    return TextButton.icon(
      onPressed: () => _showReviewForm(context),
      icon: const Icon(Icons.edit_outlined, size: 18),
      label: Text(l10n.reviewsSectionAddBtn),
      style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
    );
  }

  void _showReviewForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReviewFormSheet(venueId: venueId, venueName: venueName),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool canAddReview) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 48,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.reviewsSectionEmptyTitle,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.reviewsSectionEmptySubtitle,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              if (canAddReview) {
                _showReviewForm(context);
                return;
              }
              context.push('/login?redirectTo=/venue/$venueId');
            },
            icon: const Icon(Icons.star_rounded, size: 20),
            label: Text(
              canAddReview ? l10n.reviewsSectionAddBtn : l10n.profileSignIn,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary(BuildContext context, List<Review> reviews) {
    final l10n = AppLocalizations.of(context)!;
    final avgRating = reviews.isEmpty
        ? 0.0
        : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

    final distribution = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final review in reviews) {
      final star = review.rating.round().clamp(1, 5);
      distribution[star] = (distribution[star] ?? 0) + 1;
    }

    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // A 6% amber wash reads as a warm tint on white but turns olive-yellow
        // over a dark surface, so the tint is layered on the theme surface
        // instead of standing alone.
        color: Color.alphaBlend(
          Colors.amber.withValues(alpha: 0.06),
          scheme.surface,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                avgRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              StarRatingDisplay(rating: avgRating, starSize: 14),
              const SizedBox(height: 4),
              Text(
                l10n.reviewsSectionCountLabel(reviews.length),
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = distribution[star] ?? 0;
                final percentage = reviews.isEmpty
                    ? 0.0
                    : count / reviews.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: scheme.surfaceContainerHighest,
                            color: Colors.amber,
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 20,
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
    BuildContext context,
    WidgetRef ref,
    Review review,
    String? currentUserId,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isOwner = currentUserId == review.userId;

    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // Theme colours, not Colors.white: the card was a bright white slab in
        // the middle of a dark page, with grey-on-white text that barely read.
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildReviewAvatar(review),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _formatDate(context, review.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              StarRatingDisplay(rating: review.rating, starSize: 14),
              if (isOwner)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.red.shade300,
                  ),
                  onPressed: () => _confirmDelete(context, ref, review),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
            ],
          ),
          if (review.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.text,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
          if (review.hasReply) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.store, size: 14, color: AppTheme.primaryColor),
                      const SizedBox(width: 4),
                      // Expanded rather than a fixed Text plus Spacer: on a
                      // narrow screen the label and the date together exceeded
                      // the row, overflowing by 40px.
                      Expanded(
                        child: Text(
                          l10n.reviewsSectionMerchantReply,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      if (review.merchantReplyAt != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(context, review.merchantReplyAt!),
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    review.merchantReply!,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewAvatar(Review review) {
    final initial = review.userName.isNotEmpty
        ? review.userName[0].toUpperCase()
        : '?';

    return ClipOval(
      child: SizedBox(
        width: _avatarSize,
        height: _avatarSize,
        child: review.userPhotoUrl == null
            ? Container(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              )
            : CachedNetworkImage(
                imageUrl: review.userPhotoUrl!,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
                memCacheWidth: _avatarCacheSize,
                memCacheHeight: _avatarCacheSize,
                maxWidthDiskCache: _avatarCacheSize,
                maxHeightDiskCache: _avatarCacheSize,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                placeholder: (context, url) => Container(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Review review) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.reviewsSectionDeleteTitle),
        content: Text(l10n.reviewsSectionDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.reviewsSectionCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final currentUserId = ref
                  .read(authStateProvider)
                  .asData
                  ?.value
                  ?.uid;
              await ref
                  .read(reviewsRepositoryProvider)
                  .deleteReview(venueId, review.id);
              ref.invalidate(venueReviewsProvider(venueId));
              ref.invalidate(venueRatingSummaryProvider(venueId));
              if (currentUserId != null) {
                ref.invalidate(userReviewCountProvider(currentUserId));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.reviewsSectionDeleteBtn),
          ),
        ],
      ),
    );
  }

  void _showAllReviews(
    BuildContext context,
    List<Review> reviews,
    String? currentUserId,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Consumer(
          builder: (context, ref, child) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  l10n.reviewsSectionAllTitle(reviews.length),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: reviews.length,
                  itemBuilder: (context, idx) => _buildReviewCard(
                    context,
                    ref,
                    reviews[idx],
                    currentUserId,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return l10n.reviewsTimeNow;
    if (diff.inMinutes < 60) return l10n.reviewsTimeMins(diff.inMinutes);
    if (diff.inHours < 24) return l10n.reviewsTimeHours(diff.inHours);
    if (diff.inDays < 7) return l10n.reviewsTimeDays(diff.inDays);
    if (diff.inDays < 30) return l10n.reviewsTimeWeeks(diff.inDays ~/ 7);

    return '${date.day}/${date.month}/${date.year}';
  }
}
