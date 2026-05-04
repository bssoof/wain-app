import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/providers/offline_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/routing/navigation_extensions.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/widgets/app_button.dart';
import 'package:wain_app/core/widgets/app_empty_state.dart';
import 'package:wain_app/core/widgets/offline_widgets.dart';
import 'package:wain_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_review.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

import '../providers/merchant_dashboard_providers.dart';
import '../providers/merchant_providers.dart';

class MerchantReviewsScreen extends ConsumerStatefulWidget {
  final int? initialFilter;

  const MerchantReviewsScreen({super.key, this.initialFilter});

  @override
  ConsumerState<MerchantReviewsScreen> createState() =>
      _MerchantReviewsScreenState();
}

class _MerchantReviewsScreenState extends ConsumerState<MerchantReviewsScreen> {
  int? _activeFilter;

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter;
  }

  @override
  void didUpdateWidget(covariant MerchantReviewsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) {
      _activeFilter = widget.initialFilter;
    }
  }

  Future<void> _refresh() async {
    if (!ref.read(isOnlineProvider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.offlineActionRequiresConnection,
          ),
        ),
      );
      return;
    }
    ref.invalidate(merchantReviewsProvider);
    ref.invalidate(merchantStatsProvider);
    await ref.read(merchantReviewsProvider.future);
  }

  Future<bool> _submitReply(String reviewId, String replyText) async {
    if (!ref.read(isOnlineProvider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.offlineActionRequiresConnection,
          ),
        ),
      );
      return false;
    }
    try {
      final venueId = await ref.read(merchantVenueIdProvider.future);
      if (venueId == null) {
        return false;
      }

      final user = await ref.read(authStateProvider.future);
      final authorIdentifier =
          user?.displayName ?? user?.email ?? user?.uid ?? 'merchant';

      await ref
          .read(merchantReviewsRepositoryProvider)
          .submitReply(
            venueId: venueId,
            reviewId: reviewId,
            replyText: replyText,
            authorIdentifier: authorIdentifier,
          );

      ref.invalidate(merchantReviewsProvider);
      ref.invalidate(merchantStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.merchantReviewsReplySent,
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }

      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.merchantReviewsErrorGeneric(error.toString()),
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return false;
    }
  }

  Future<bool> _deleteReply(String reviewId) async {
    if (!ref.read(isOnlineProvider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.offlineActionRequiresConnection,
          ),
        ),
      );
      return false;
    }
    try {
      final venueId = await ref.read(merchantVenueIdProvider.future);
      if (venueId == null) {
        return false;
      }

      await ref
          .read(merchantReviewsRepositoryProvider)
          .deleteReply(venueId: venueId, reviewId: reviewId);

      ref.invalidate(merchantReviewsProvider);
      ref.invalidate(merchantStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.merchantReviewsReplyDeleted,
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }

      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.merchantReviewsErrorGeneric(error.toString()),
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return false;
    }
  }

  List<_MerchantReviewRecord> _applyFilter(
    List<_MerchantReviewRecord> reviews,
  ) {
    return reviews.where((review) {
      final filter = _activeFilter;
      if (filter == null) {
        return true;
      }
      if (filter == 0) {
        return !review.hasReply;
      }
      return review.starBucket == filter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final venueIdAsync = ref.watch(merchantVenueIdProvider);
    final reviewsSnapshotAsync = ref.watch(merchantReviewsSnapshotProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.popOrGo('/merchant/dashboard'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.merchantReviewsTitle),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: venueIdAsync.when(
        loading: () => const Center(child: WainLoadingIndicator()),
        error: (error, _) => _MerchantReviewsErrorState(
          message: l10n.merchantReviewsErrorGeneric(error.toString()),
          onRetry: _refresh,
        ),
        data: (venueId) {
          if (venueId == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: AppEmptyState(
                  icon: Icons.storefront_outlined,
                  message: l10n.merchantNoVenueLinked,
                  actionLabel: l10n.merchantEnterInviteBtn,
                  onAction: () => context.push('/merchant/invite'),
                ),
              ),
            );
          }

          final reviewsAsync = ref.watch(merchantReviewsProvider);
          return reviewsAsync.when(
            loading: () => const Center(child: WainLoadingIndicator()),
            error: (error, _) => _MerchantReviewsErrorState(
              message: l10n.merchantReviewsErrorGeneric(error.toString()),
              onRetry: _refresh,
            ),
            data: (rawReviews) {
              final snapshot = reviewsSnapshotAsync.asData?.value;
              final reviews = rawReviews
                  .map(_MerchantReviewRecord.fromReview)
                  .toList();
              final filteredReviews = _applyFilter(reviews);
              final pendingCount = reviews
                  .where((review) => !review.hasReply)
                  .length;
              final averageRating = reviews.isEmpty
                  ? 0.0
                  : reviews
                            .map((review) => review.rating)
                            .reduce((left, right) => left + right) /
                        reviews.length;

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: AppSpacing.screenPadding,
                  children: [
                    OfflineBanner(
                      isVisible: snapshot?.isFromCache ?? false,
                      fetchedAt: snapshot?.fetchedAt,
                    ),
                    if (snapshot?.isFromCache ?? false)
                      const SizedBox(height: AppSpacing.md),
                    _ReviewsSummaryCard(
                      title: l10n.merchantReviewsTitle,
                      totalReviewsLabel: l10n.merchantReviewsCount(
                        reviews.length,
                      ),
                      averageRating: averageRating,
                      pendingReplies: pendingCount,
                      pendingLabel: l10n.merchantReviewsFilterNoReply,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _ReviewFilterBar(
                      activeFilter: _activeFilter,
                      onSelected: (value) {
                        setState(() => _activeFilter = value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (reviews.isEmpty)
                      AppEmptyState(
                        icon: Icons.rate_review_outlined,
                        message: l10n.merchantReviewsEmpty,
                      )
                    else if (filteredReviews.isEmpty)
                      AppEmptyState(
                        icon: Icons.filter_alt_off_rounded,
                        message: l10n.merchantReviewsNoResults,
                        actionLabel: l10n.merchantReviewsFilterAll,
                        onAction: () => setState(() => _activeFilter = null),
                      )
                    else
                      ...filteredReviews.map(
                        (review) => Padding(
                          key: ValueKey(review.id),
                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                          child: _MerchantReviewCard(
                            review: review,
                            onSubmitReply: (reply) =>
                                _submitReply(review.id, reply),
                            onDeleteReply: () => _deleteReply(review.id),
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ReviewsSummaryCard extends StatelessWidget {
  final String title;
  final String totalReviewsLabel;
  final double averageRating;
  final int pendingReplies;
  final String pendingLabel;

  const _ReviewsSummaryCard({
    required this.title,
    required this.totalReviewsLabel,
    required this.averageRating,
    required this.pendingReplies,
    required this.pendingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: colorScheme.outline),
        boxShadow: AppShadows.elevated,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: AppSpacing.radiusMd,
                  ),
                  child: Icon(
                    Icons.rate_review_outlined,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.headlineSmall),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        totalReviewsLabel,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _SummaryPill(
                  icon: Icons.star_rounded,
                  label: averageRating.toStringAsFixed(1),
                  backgroundColor: AppTheme.warningColor.withAlpha(18),
                  foregroundColor: AppTheme.warningColor,
                ),
                _SummaryPill(
                  icon: Icons.reply_outlined,
                  label: '$pendingReplies $pendingLabel',
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _SummaryPill({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppSpacing.radiusFull,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foregroundColor),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: foregroundColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewFilterBar extends StatelessWidget {
  final int? activeFilter;
  final ValueChanged<int?> onSelected;

  const _ReviewFilterBar({
    required this.activeFilter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChipItem(
            label: l10n.merchantReviewsFilterAll,
            selected: activeFilter == null,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChipItem(
            label: l10n.merchantReviewsFilterNoReply,
            selected: activeFilter == 0,
            icon: Icons.reply_outlined,
            onTap: () => onSelected(0),
          ),
          for (var stars = 5; stars >= 1; stars--) ...[
            const SizedBox(width: AppSpacing.sm),
            _FilterChipItem(
              label: '$stars',
              selected: activeFilter == stars,
              icon: Icons.star_rounded,
              onTap: () => onSelected(stars),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _FilterChipItem({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      selected: selected,
      onSelected: (_) => onTap(),
      label: Text(label),
      avatar: icon == null
          ? null
          : Icon(
              icon,
              size: 16,
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.primary,
      side: BorderSide(color: colorScheme.outline),
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusFull),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}

class _MerchantReviewCard extends StatefulWidget {
  final _MerchantReviewRecord review;
  final Future<bool> Function(String reply) onSubmitReply;
  final Future<bool> Function() onDeleteReply;

  const _MerchantReviewCard({
    required this.review,
    required this.onSubmitReply,
    required this.onDeleteReply,
  });

  @override
  State<_MerchantReviewCard> createState() => _MerchantReviewCardState();
}

class _MerchantReviewCardState extends State<_MerchantReviewCard> {
  late final TextEditingController _replyController;

  bool _showComposer = false;
  bool _isEditing = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _replyController = TextEditingController(text: widget.review.merchantReply);
    _replyController.addListener(_handleComposerChanged);
  }

  @override
  void dispose() {
    _replyController.removeListener(_handleComposerChanged);
    _replyController.dispose();
    super.dispose();
  }

  void _handleComposerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleSubmit() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await widget.onSubmitReply(text);
    if (!mounted) {
      return;
    }
    setState(() {
      _isSubmitting = false;
      if (success) {
        _showComposer = false;
        _isEditing = false;
      }
    });
  }

  Future<void> _handleDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.merchantReviewsDeleteReplyTitle),
        content: Text(l10n.merchantReviewsDeleteReplyConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.merchantReviewsCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.merchantReviewsDelete,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await widget.onDeleteReply();
    if (!mounted) {
      return;
    }
    setState(() {
      _isSubmitting = false;
      if (success) {
        _replyController.clear();
        _showComposer = false;
        _isEditing = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final review = widget.review;
    final showComposer = _showComposer || _isEditing;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReviewAvatar(review: review),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.displayName(l10n),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (index) => Icon(
                              index < review.starBucket
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 18,
                              color: AppTheme.warningColor,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _formatRelativeTime(context, review.createdAt),
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (review.text.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                review.text,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (review.hasReply && !showComposer) ...[
              _ReplyCard(
                reply: review.merchantReply!,
                repliedAt: review.merchantReplyAt,
                onEdit: () {
                  setState(() {
                    _showComposer = true;
                    _isEditing = true;
                    _replyController.text = review.merchantReply ?? '';
                  });
                },
                onDelete: _isSubmitting ? null : _handleDelete,
              ),
            ] else if (!showComposer) ...[
              AppButton.secondary(
                label: l10n.merchantReviewsAddReply,
                onPressed: () {
                  setState(() {
                    _showComposer = true;
                    _isEditing = false;
                  });
                },
                icon: const Icon(Icons.reply_outlined, size: 18),
                expanded: false,
                height: AppSpacing.touchTargetMin,
              ),
            ],
            if (showComposer) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: AppSpacing.radiusMd,
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _replyController,
                        minLines: 2,
                        maxLines: 5,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: l10n.merchantReviewsReplyHint,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton.tertiary(
                              label: l10n.merchantReviewsCancel,
                              onPressed: _isSubmitting
                                  ? null
                                  : () {
                                      setState(() {
                                        _showComposer = false;
                                        _isEditing = false;
                                        _replyController.text =
                                            review.merchantReply ?? '';
                                      });
                                    },
                              expanded: true,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: AppButton.primary(
                              label: review.hasReply
                                  ? l10n.merchantReviewsEdit
                                  : l10n.merchantReviewsAddReply,
                              onPressed:
                                  _replyController.text.trim().isEmpty ||
                                      _isSubmitting
                                  ? null
                                  : _handleSubmit,
                              isLoading: _isSubmitting,
                              height: AppSpacing.touchTargetMin,
                            ),
                          ),
                        ],
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

class _ReplyCard extends StatelessWidget {
  final String reply;
  final DateTime? repliedAt;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _ReplyCard({
    required this.reply,
    required this.repliedAt,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(110),
        borderRadius: AppSpacing.radiusMd,
        border: Border.all(color: colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.storefront_outlined,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    l10n.merchantReviewsOwnerReply,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: l10n.merchantReviewsEdit,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  tooltip: l10n.merchantReviewsDeleteTooltip,
                ),
              ],
            ),
            if (repliedAt != null) ...[
              Text(
                _formatRelativeTime(context, repliedAt!),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              reply,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewAvatar extends StatelessWidget {
  final _MerchantReviewRecord review;

  const _ReviewAvatar({required this.review});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (review.userPhotoUrl != null && review.userPhotoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: colorScheme.primaryContainer,
        backgroundImage: NetworkImage(review.userPhotoUrl!),
      );
    }

    return CircleAvatar(
      radius: 22,
      backgroundColor: colorScheme.primaryContainer,
      child: Text(
        review.initial(l10n),
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: colorScheme.primary),
      ),
    );
  }
}

class _MerchantReviewsErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _MerchantReviewsErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              label: AppLocalizations.of(context)!.retryButton,
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              expanded: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _MerchantReviewRecord {
  final String id;
  final String userName;
  final String? userPhotoUrl;
  final double rating;
  final String text;
  final DateTime createdAt;
  final String? merchantReply;
  final DateTime? merchantReplyAt;

  const _MerchantReviewRecord({
    required this.id,
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    required this.text,
    required this.createdAt,
    this.merchantReply,
    this.merchantReplyAt,
  });

  factory _MerchantReviewRecord.fromReview(MerchantReview review) {
    return _MerchantReviewRecord(
      id: review.id,
      userName: review.trimmedUserName,
      userPhotoUrl: review.userPhotoUrl,
      rating: review.rating,
      text: review.trimmedText,
      createdAt: review.createdAt ?? DateTime.now(),
      merchantReply: review.merchantReply?.trim(),
      merchantReplyAt: review.merchantReplyAt,
    );
  }

  bool get hasReply => merchantReply != null && merchantReply!.isNotEmpty;

  int get starBucket {
    final rounded = rating.round();
    if (rounded < 1) {
      return 1;
    }
    if (rounded > 5) {
      return 5;
    }
    return rounded;
  }

  String displayName(AppLocalizations l10n) {
    return userName.isEmpty ? l10n.merchantReviewsDefaultUser : userName;
  }

  String initial(AppLocalizations l10n) {
    if (userName.isEmpty) {
      return l10n.merchantReviewsDefaultInitial;
    }
    return userName.substring(0, 1).toUpperCase();
  }
}

String _formatRelativeTime(BuildContext context, DateTime time) {
  final l10n = AppLocalizations.of(context)!;
  final difference = DateTime.now().difference(time);

  if (difference.inMinutes < 1) {
    return l10n.reviewsTimeNow;
  }
  if (difference.inHours < 1) {
    return l10n.reviewsTimeMins(difference.inMinutes);
  }
  if (difference.inDays < 1) {
    return l10n.reviewsTimeHours(difference.inHours);
  }
  if (difference.inDays < 7) {
    return l10n.reviewsTimeDays(difference.inDays);
  }
  return l10n.reviewsTimeWeeks((difference.inDays / 7).floor());
}
