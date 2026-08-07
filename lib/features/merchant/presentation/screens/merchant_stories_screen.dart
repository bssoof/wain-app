import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wain_app/core/routing/app_router.dart';
import 'package:wain_app/core/providers/offline_providers.dart';
import 'package:wain_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/widgets/app_empty_state.dart';
import 'package:wain_app/core/widgets/offline_widgets.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_menu_item_image.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_stories_repository.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_story.dart';
import '../providers/merchant_dashboard_providers.dart';
import '../providers/merchant_invalidation.dart';
import '../providers/merchant_providers.dart';
import '../providers/merchant_wallet_providers.dart';

/// Merchant Stories Screen — إدارة الستوريات
class MerchantStoriesScreen extends ConsumerWidget {
  final String? highlightStoryId;

  const MerchantStoriesScreen({super.key, this.highlightStoryId});

  String _formatStoryStatusDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venueIdAsync = ref.watch(merchantVenueIdProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final walletAsync = ref.watch(merchantWalletStreamProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.merchantStoriesTitle),
      ),
      floatingActionButton: isOnline
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateStory(context, ref),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              icon: const Icon(Icons.add),
              label: Text(l10n.merchantStoriesNewStory),
            )
          : null,
      body: !isOnline
          ? Column(
              children: [
                OfflineBanner(
                  isVisible: true,
                  message: l10n.offlineScreenRequiresConnection,
                ),
                Expanded(
                  child: OfflineEmptyState(
                    title: l10n.merchantStoriesOfflineTitle,
                    subtitle: l10n.offlineScreenUnavailableSubtitle,
                  ),
                ),
              ],
            )
          : venueIdAsync.when(
              loading: () => const Center(child: WainLoadingIndicator()),
              error: (e, s) => Center(
                child: Padding(
                  padding: AppSpacing.screenPadding,
                  child: Text(
                    l10n.merchantStoriesError,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
              data: (venueId) {
                if (venueId == null) {
                  return Center(
                    child: Padding(
                      padding: AppSpacing.screenPadding,
                      child: Text(
                        l10n.merchantStoriesNoVenue,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  );
                }
                return StreamBuilder<List<MerchantStory>>(
                  stream: ref
                      .read(merchantStoriesRepositoryProvider)
                      .watchStories(venueId: venueId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: WainLoadingIndicator());
                    }

                    final stories = snapshot.data ?? const <MerchantStory>[];
                    final highlighted = highlightStoryId;
                    final orderedStories = highlighted == null
                        ? stories
                        : <MerchantStory>[
                            ...stories.where(
                              (story) => story.id == highlighted,
                            ),
                            ...stories.where(
                              (story) => story.id != highlighted,
                            ),
                          ];

                    final wallet = walletAsync.asData?.value;
                    final walletMissing = wallet == null;
                    final lowBalance = wallet?.isLowBalance ?? false;
                    final zeroBalance =
                        wallet != null && wallet.availableBalance <= 0;

                    if (stories.isEmpty) {
                      return Padding(
                        padding: AppSpacing.screenPadding,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (walletMissing || lowBalance) ...[
                              _LowBalanceStoriesCallout(
                                walletMissing: walletMissing,
                                lowBalance: lowBalance,
                                zeroBalance: zeroBalance,
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            AppEmptyState(
                              icon: Icons.auto_stories_outlined,
                              message: l10n.merchantStoriesEmpty,
                            ),
                            Text(
                              l10n.merchantStoriesEmptyPrompt,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.xl,
                        AppSpacing.xl,
                        96,
                      ),
                      itemCount:
                          orderedStories.length +
                          ((walletMissing || lowBalance) ? 1 : 0),
                      itemBuilder: (context, index) {
                        if ((walletMissing || lowBalance) && index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: _LowBalanceStoriesCallout(
                              walletMissing: walletMissing,
                              lowBalance: lowBalance,
                              zeroBalance: zeroBalance,
                            ),
                          );
                        }
                        final storyIndex = (walletMissing || lowBalance)
                            ? index - 1
                            : index;
                        final story = orderedStories[storyIndex];
                        final storyId = story.id;
                        final createdAt = story.createdAt;
                        final imageUrl = story.imageUrl;
                        final videoUrl = story.videoUrl;
                        final text = story.text;
                        final now = DateTime.now();
                        final isExpired = story.isExpiredAt(now);
                        final isPromoted = story.isPromotedAt(now);
                        final promotedUntil = story.promotedUntil;
                        final dateStr = createdAt != null
                            ? '${createdAt.day}/${createdAt.month} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}'
                            : '';

                        final shouldHighlight = highlightStoryId == storyId;
                        final remainingPromotion = promotedUntil?.difference(
                          now,
                        );
                        final promotionIsExpired =
                            promotedUntil != null &&
                            !promotedUntil.isAfter(now);
                        final promotionExpiringSoon =
                            remainingPromotion != null &&
                            remainingPromotion.inMilliseconds > 0 &&
                            remainingPromotion <= const Duration(hours: 24);
                        final showRenewCta =
                            isPromoted ||
                            promotionExpiringSoon ||
                            promotionIsExpired;
                        final promotionStateLabel = promotionIsExpired
                            ? l10n.merchantStoriesPromotionExpiredState
                            : promotionExpiringSoon
                            ? l10n.merchantStoriesPromotionExpiringState
                            : isPromoted
                            ? l10n.merchantStoriesPromotionActiveState
                            : null;

                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: shouldHighlight
                                ? colorScheme.primaryContainer.withAlpha(34)
                                : colorScheme.surface,
                            borderRadius: AppSpacing.radiusLg,
                            border: Border.all(
                              color: shouldHighlight
                                  ? colorScheme.primary
                                  : isPromoted
                                  ? AppTheme.warningColor
                                  : (isExpired
                                        ? colorScheme.error.withAlpha(90)
                                        : colorScheme.outline),
                              width: shouldHighlight || isPromoted ? 2 : 1,
                            ),
                            boxShadow: AppShadows.elevated,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (imageUrl != null)
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  child: Image(
                                    image: venueImageProvider(imageUrl),
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      height: 200,
                                      color:
                                          colorScheme.surfaceContainerHighest,
                                      child: const Icon(
                                        Icons.broken_image,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                )
                              else if (videoUrl != null)
                                Container(
                                  height: 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.videocam,
                                          size: 48,
                                          color: colorScheme.primary,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          l10n.merchantStoriesVideo,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (text.isNotEmpty)
                                      Text(
                                        text,
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                    const SizedBox(height: AppSpacing.sm),
                                    // Status row
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Flexible(
                                          child: Text(
                                            dateStr,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                theme.textTheme.labelSmall,
                                          ),
                                        ),
                                        // A SizedBox, not a Spacer: a Spacer is
                                        // an Expanded and so competed with the
                                        // date for the row's flex, leaving both
                                        // it and the badge short.
                                        const SizedBox(width: AppSpacing.sm),
                                        // Promote Status Badge — Flexible for
                                        // the same reason as the date beside
                                        // it: both are intrinsic, and on a
                                        // narrow card they do not both fit.
                                        if (isPromoted)
                                          Flexible(
                                            child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.sm,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.warningColor
                                                  .withAlpha(18),
                                              borderRadius: AppSpacing.radiusSm,
                                              border: Border.all(
                                                color: AppTheme.warningColor
                                                    .withAlpha(72),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.star,
                                                  size: 12,
                                                  color: AppTheme.warningColor,
                                                ),
                                                const SizedBox(
                                                  width: AppSpacing.xs,
                                                ),
                                                Flexible(
                                                  child: Text(
                                                    l10n
                                                        .merchantStoriesPromoted,
                                                    maxLines: 1,
                                                    overflow: TextOverflow
                                                        .ellipsis,
                                                    style: theme
                                                        .textTheme
                                                        .labelSmall
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: AppTheme
                                                              .warningColor,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Expiry Status Badge — intrinsic like
                                        // the one above, so it gives too.
                                        Flexible(
                                          child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.sm,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isExpired
                                                ? colorScheme.errorContainer
                                                : AppTheme.successColor
                                                      .withAlpha(18),
                                            borderRadius: AppSpacing.radiusSm,
                                          ),
                                            child: Text(
                                              isExpired
                                                  ? l10n.merchantStoriesExpired
                                                  : l10n.merchantStoriesActive,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color: isExpired
                                                        ? colorScheme
                                                              .onErrorContainer
                                                        : AppTheme
                                                              .successColor,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (isPromoted) ...[
                                      const SizedBox(height: AppSpacing.sm),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: AppSpacing.xs,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.warningColor
                                              .withAlpha(12),
                                          borderRadius: AppSpacing.radiusSm,
                                          border: Border.all(
                                            color: AppTheme.warningColor
                                                .withAlpha(56),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.rocket_launch_rounded,
                                              size: 14,
                                              color: AppTheme.warningColor,
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.xs,
                                            ),
                                            Expanded(
                                              child: Text(
                                                promotedUntil != null
                                                    ? l10n.merchantStoriesPromotedUntil(
                                                        _formatStoryStatusDateTime(
                                                          promotedUntil,
                                                        ),
                                                      )
                                                    : l10n.merchantStoriesPromoted,
                                                style: theme
                                                    .textTheme
                                                    .labelMedium
                                                    ?.copyWith(
                                                      color:
                                                          AppTheme.warningColor,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (promotionStateLabel != null) ...[
                                      const SizedBox(height: AppSpacing.sm),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: AppSpacing.xs,
                                        ),
                                        decoration: BoxDecoration(
                                          color: promotionIsExpired
                                              ? colorScheme.errorContainer
                                              : promotionExpiringSoon
                                              ? AppTheme.warningColor.withAlpha(
                                                  16,
                                                )
                                              : AppTheme.successColor.withAlpha(
                                                  14,
                                                ),
                                          borderRadius: AppSpacing.radiusSm,
                                          border: Border.all(
                                            color: promotionIsExpired
                                                ? colorScheme.error.withAlpha(
                                                    80,
                                                  )
                                                : promotionExpiringSoon
                                                ? AppTheme.warningColor
                                                      .withAlpha(80)
                                                : AppTheme.successColor
                                                      .withAlpha(80),
                                          ),
                                        ),
                                        child: Text(
                                          promotedUntil == null
                                              ? promotionStateLabel
                                              : l10n.merchantStoriesPromotionStateWithTime(
                                                  promotionStateLabel,
                                                  _formatStoryStatusDateTime(
                                                    promotedUntil,
                                                  ),
                                                ),
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: AppSpacing.md),
                                    // Action buttons row - prominent promote button
                                    Row(
                                      children: [
                                        // Promote Button -- large and prominent
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _promoteStory(
                                              context,
                                              ref,
                                              storyId,
                                            ),
                                            icon: const Icon(
                                              Icons.rocket_launch,
                                              size: 18,
                                            ),
                                            label: Text(
                                              showRenewCta
                                                  ? l10n.merchantStoriesRenewPromotion
                                                  : l10n.merchantStoriesPromote,
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isPromoted
                                                  ? AppTheme.warningColor
                                                  : colorScheme.primary,
                                              foregroundColor:
                                                  colorScheme.onPrimary,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 10,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    AppSpacing.radiusMd,
                                              ),
                                              elevation: 0,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        // Delete Button
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: AppTheme.errorColor,
                                            size: 22,
                                          ),
                                          onPressed: () => _deleteStory(
                                            context,
                                            ref,
                                            storyId,
                                            imageUrl,
                                            videoUrl,
                                          ),
                                          tooltip:
                                              l10n.merchantStoriesDeleteTooltip,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _promoteStory(
    BuildContext context,
    WidgetRef ref,
    String storyId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final wallet = ref.read(merchantWalletStreamProvider).asData?.value;
    final walletMissing = wallet == null;
    final lowBalance = wallet?.isLowBalance ?? false;
    final zeroBalance = wallet != null && wallet.availableBalance <= 0;

    if (walletMissing) {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        useRootNavigator: false,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.merchantWalletTitle),
          content: Text(l10n.merchantStoriesWalletMissing),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (context.mounted) {
                  context.push(AppRoutes.merchantWallet);
                }
              },
              child: Text(l10n.merchantStoriesOpenWallet),
            ),
          ],
        ),
      );
      return;
    }

    if (zeroBalance) {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        useRootNavigator: false,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.merchantWalletTitle),
          content: Text(l10n.merchantStoriesInsufficientBalance),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (context.mounted) {
                  context.push(AppRoutes.merchantWallet);
                }
              },
              child: Text(l10n.merchantStoriesOpenWallet),
            ),
          ],
        ),
      );
      return;
    }

    if (lowBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.merchantWalletLowBalance),
          action: SnackBarAction(
            label: l10n.merchantStoriesOpenWallet,
            onPressed: () => context.push(AppRoutes.merchantWallet),
          ),
        ),
      );
    }

    final repository = ref.read(merchantStoriesRepositoryProvider);
    StoryPromotionPricing pricing;
    try {
      pricing = await repository.getStoryPromotionPricing();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_storyPromotionErrorMessage(context, error)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!context.mounted) return;

    final duration = await showDialog<int>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.merchantStoriesPromoteTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.merchantStoriesPromoteDesc),
            const SizedBox(height: 16),
            Text(l10n.merchantStoriesChooseDuration),
            const SizedBox(height: 8),
            _PromoteOption(
              label: _promotionOptionLabel(
                l10n,
                baseLabel: l10n.merchantStoriesPromote1Day,
                price: pricing.oneDayPrice,
                currency: pricing.currency,
              ),
              days: 1,
            ),
            _PromoteOption(
              label: _promotionOptionLabel(
                l10n,
                baseLabel: l10n.merchantStoriesPromote3Days,
                price: pricing.threeDayPrice,
                currency: pricing.currency,
              ),
              days: 3,
            ),
            _PromoteOption(
              label: _promotionOptionLabel(
                l10n,
                baseLabel: l10n.merchantStoriesPromote7Days,
                price: pricing.sevenDayPrice,
                currency: pricing.currency,
              ),
              days: 7,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.merchantStoriesCancel),
          ),
        ],
      ),
    );

    if (duration == null) return;
    if (!context.mounted) return;
    final requestId = _createPromotionRequestId();

    var loadingShown = false;
    try {
      showDialog(
        context: context,
        useRootNavigator: false,
        barrierDismissible: false,
        builder: (_) => const Center(child: WainLoadingIndicator()),
      );
      loadingShown = true;

      await repository.promoteStory(
        storyId: storyId,
        durationDays: duration,
        requestId: requestId,
      );

      if (!context.mounted) return;
      if (loadingShown && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        loadingShown = false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.merchantStoriesPromoteSuccess),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      if (loadingShown && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        loadingShown = false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_storyPromotionErrorMessage(context, e)),
          backgroundColor: Colors.red,
          action: _shouldOfferWalletAction(e)
              ? SnackBarAction(
                  label: l10n.merchantStoriesOpenWallet,
                  onPressed: () {
                    if (context.mounted) {
                      context.push(AppRoutes.merchantWallet);
                    }
                  },
                )
              : null,
        ),
      );
    }
  }

  void _deleteStory(
    BuildContext context,
    WidgetRef ref,
    String storyId,
    String? imageUrl,
    String? videoUrl,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.merchantStoriesDeleteTitle),
        content: Text(l10n.merchantStoriesDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.merchantStoriesNo),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.merchantStoriesYes,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref
          .read(merchantStoriesRepositoryProvider)
          .deleteStory(
            storyId: storyId,
            imageUrl: imageUrl,
            videoUrl: videoUrl,
          );
      ref.invalidateMerchantContentData();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.merchantStoriesDeleted),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.merchantStoriesDeleteFailed(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _storyPromotionErrorMessage(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context)!;
    if (error is StoryPromotionFailure) {
      switch (error.message) {
        case 'insufficient_wallet_balance':
          return l10n.merchantStoriesInsufficientBalance;
        case 'wallet_not_found':
          return l10n.merchantStoriesWalletMissing;
        case 'wallet_inactive':
          return l10n.merchantStoriesWalletInactive;
        case 'pricing_unavailable':
          return l10n.merchantStoriesPricingUnavailable;
        case 'venue_inactive':
          return l10n.merchantStoriesVenueInactive;
        case 'story_expired':
          return l10n.merchantStoriesExpired;
        case 'promotion_request_conflict':
          return l10n.merchantStoriesPromotionConflict;
      }
      if (error.message.isNotEmpty) {
        return l10n.merchantStoriesPromoteError(error.message);
      }
    }
    return l10n.merchantStoriesPromoteError(error.toString());
  }

  bool _shouldOfferWalletAction(Object error) {
    return error is StoryPromotionFailure &&
        (error.message == 'insufficient_wallet_balance' ||
            error.message == 'wallet_not_found' ||
            error.message == 'wallet_inactive');
  }

  String _promotionOptionLabel(
    AppLocalizations l10n, {
    required String baseLabel,
    required double price,
    required String currency,
  }) {
    final priceLabel = _formatPromotionPrice(price);
    return l10n.merchantStoriesPromotionOption(baseLabel, priceLabel, currency);
  }

  String _formatPromotionPrice(double price) {
    if (price == price.roundToDouble()) {
      return price.toStringAsFixed(0);
    }
    return price
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String _createPromotionRequestId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final randomPart = Random.secure().nextInt(1 << 32).toRadixString(36);
    return 'storypromo_${timestamp}_$randomPart';
  }

  void _showCreateStory(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CreateStorySheet(ref: ref),
    );
  }
}

class _LowBalanceStoriesCallout extends StatelessWidget {
  final bool walletMissing;
  final bool lowBalance;
  final bool zeroBalance;

  const _LowBalanceStoriesCallout({
    required this.walletMissing,
    required this.lowBalance,
    required this.zeroBalance,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    if (!walletMissing && !lowBalance) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withAlpha(18),
        borderRadius: AppSpacing.radiusMd,
        border: Border.all(color: AppTheme.warningColor.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.warningColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  walletMissing
                      ? l10n.merchantStoriesWalletMissing
                      : l10n.merchantWalletLowBalance,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (walletMissing || zeroBalance) ...[
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.tonalIcon(
                onPressed: () => context.push(AppRoutes.merchantWallet),
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: Text(l10n.merchantStoriesOpenWallet),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PromoteOption extends StatelessWidget {
  final String label;
  final int days;

  const _PromoteOption({required this.label, required this.days});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context, days),
        child: Text(label),
      ),
    );
  }
}

/// Create Story Bottom Sheet
class _CreateStorySheet extends StatefulWidget {
  final WidgetRef ref;
  const _CreateStorySheet({required this.ref});

  @override
  State<_CreateStorySheet> createState() => _CreateStorySheetState();
}

class _CreateStorySheetState extends State<_CreateStorySheet> {
  final _textController = TextEditingController();
  XFile? _pickedImage;
  XFile? _pickedVideo;
  bool _isSubmitting = false;
  int _expiryHours = 24;
  String _mediaType = 'none'; // 'none', 'image', 'video'

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _pickedImage = picked;
        _pickedVideo = null;
        _mediaType = 'image';
      });
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 30),
    );
    if (picked != null) {
      setState(() {
        _pickedVideo = picked;
        _pickedImage = null;
        _mediaType = 'video';
      });
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final text = _textController.text.trim();
    if (text.isEmpty && _pickedImage == null && _pickedVideo == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.merchantStoriesAddContent)));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final venueId = await widget.ref.read(merchantVenueIdProvider.future);
      if (venueId == null) throw Exception('No venue');
      final user = await widget.ref.read(authStateProvider.future);
      await widget.ref
          .read(merchantStoriesRepositoryProvider)
          .createStory(
            venueId: venueId,
            text: text,
            expiryHours: _expiryHours,
            createdBy: user?.uid,
            image: _pickedImage,
            video: _pickedVideo,
          );
      widget.ref.invalidateMerchantContentData();

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.merchantStoriesPublished),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.merchantStoriesPublishError(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
            Text(
              l10n.merchantStoriesNewStoryTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Media Picker -- Image or Video
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: _mediaType == 'image'
                            ? AppTheme.primaryColor.withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _mediaType == 'image'
                              ? AppTheme.primaryColor
                              : Colors.grey.shade300,
                          width: _mediaType == 'image' ? 2 : 1,
                        ),
                      ),
                      child: _pickedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_pickedImage!.path),
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 36,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.merchantStoriesPhoto,
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickVideo,
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: _mediaType == 'video'
                            ? Colors.deepPurple.withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _mediaType == 'video'
                              ? Colors.deepPurple
                              : Colors.grey.shade300,
                          width: _mediaType == 'video' ? 2 : 1,
                        ),
                      ),
                      child: _pickedVideo != null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.videocam,
                                  size: 40,
                                  color: Colors.deepPurple,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.merchantStoriesVideoSelected,
                                  style: TextStyle(
                                    color: Colors.deepPurple.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.videocam_outlined,
                                  size: 36,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.merchantStoriesVideo,
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  l10n.merchantStoriesVideoLimit,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Text
            TextField(
              controller: _textController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.merchantStoriesTextHint,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Expiry
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 20),
                const SizedBox(width: 8),
                Text(l10n.merchantStoriesDuration),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: Text(l10n.merchantStories24h),
                  selected: _expiryHours == 24,
                  onSelected: (_) => setState(() => _expiryHours = 24),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(l10n.merchantStories48h),
                  selected: _expiryHours == 48,
                  onSelected: (_) => setState(() => _expiryHours = 48),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(l10n.merchantStoriesPromote7),
                  selected: _expiryHours == 168,
                  onSelected: (_) => setState(() => _expiryHours = 168),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: WainLoadingIndicator(),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  l10n.merchantStoriesPublishBtn,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
