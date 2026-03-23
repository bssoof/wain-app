import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/widgets/app_button.dart';
import 'package:wain_app/core/widgets/app_empty_state.dart';
import 'package:wain_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

import '../providers/merchant_dashboard_providers.dart';

class MerchantDashboardScreen extends ConsumerWidget {
  const MerchantDashboardScreen({super.key});

  Future<void> _refreshDashboardData(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final analyticsResult = await FirebaseFunctions.instance
          .httpsCallable('backfillMerchantAnalytics')
          .call({'days': 30});
      final busyTimesResult = await FirebaseFunctions.instance
          .httpsCallable('backfillVenueBusyTimes')
          .call({'demoMode': kDebugMode});

      final data = analyticsResult.data as Map<dynamic, dynamic>?;
      final summary = data?['summary'] as Map<dynamic, dynamic>?;
      final views = (summary?['views_total'] as num?)?.toInt() ?? 0;
      final calls = (summary?['calls_total'] as num?)?.toInt() ?? 0;
      final navs = (summary?['navs_total'] as num?)?.toInt() ?? 0;
      final busyTimesStatus = _busyTimesRefreshStatusMessage(
        l10n,
        busyTimesResult.data as Map<dynamic, dynamic>?,
      );

      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.dashboardRefreshSuccess('$views', '$calls', '$navs')}\n$busyTimesStatus',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on FirebaseFunctionsException catch (error) {
      debugPrint('Backfill analytics failed: ${error.code} ${error.message}');
      if (!context.mounted) {
        return;
      }
      final message = _backfillErrorMessage(context, error);
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (error) {
      debugPrint('Backfill analytics failed: $error');
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.dashboardRefreshFailed(error.toString())),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      ref.invalidate(merchantVenueProvider);
      ref.invalidate(merchantStatsProvider);
      ref.invalidate(merchantOffersProvider);
      ref.invalidate(merchantAnalyticsProvider);
      ref.invalidate(merchantAnalyticsDailyProvider(30));
      ref.invalidate(merchantAnalyticsDailyProvider(7));
      ref.invalidate(userNotificationsProvider);
      ref.invalidate(unreadNotificationsCountProvider);
    }
  }

  String _backfillErrorMessage(
    BuildContext context,
    FirebaseFunctionsException error,
  ) {
    final l10n = AppLocalizations.of(context)!;
    switch (error.code) {
      case 'permission-denied':
        return l10n.dashboardErrorPermission;
      case 'failed-precondition':
        if ((error.message ?? '').toLowerCase().contains('index')) {
          return l10n.dashboardErrorIndex;
        }
        return l10n.dashboardErrorNoVenue;
      case 'unauthenticated':
        return l10n.dashboardErrorUnauthenticated;
      default:
        return l10n.dashboardRefreshFailed(error.message ?? error.code);
    }
  }

  String _busyTimesRefreshStatusMessage(
    AppLocalizations l10n,
    Map<dynamic, dynamic>? resultData,
  ) {
    final busyTimes = resultData?['busyTimes'] as Map<dynamic, dynamic>?;
    final confidence = busyTimes?['confidence'] as String?;
    if (busyTimes == null) {
      return l10n.dashboardBusyTimesPendingGeneric;
    }
    if (busyTimes['demo_override_active'] == true) {
      return l10n.dashboardBusyTimesReadyDemo;
    }
    if (confidence != 'insufficient') {
      return l10n.dashboardBusyTimesReady;
    }

    switch (busyTimes['insufficient_reason'] as String?) {
      case 'missing_opening_hours':
        return l10n.dashboardBusyTimesPendingHours;
      case 'missing_timezone':
        return l10n.dashboardBusyTimesPendingTimezone;
      case 'not_enough_signals':
        return l10n.dashboardBusyTimesPendingSignals;
      case 'not_enough_active_days':
        return l10n.dashboardBusyTimesPendingActiveDays;
      default:
        return l10n.dashboardBusyTimesPendingGeneric;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final venueAsync = ref.watch(merchantVenueProvider);
    final statsAsync = ref.watch(merchantStatsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.merchantDashboardTitle),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final countAsync = ref.watch(unreadNotificationsCountProvider);
              final count = countAsync.asData?.value ?? 0;
              return IconButton(
                onPressed: () => context.push('/merchant/notifications'),
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.notifications_outlined),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _refreshDashboardData(context, ref),
          ),
        ],
      ),
      body: venueAsync.when(
        loading: () => const Center(child: WainLoadingIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              l10n.merchantErrorGeneric(error.toString()),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (venue) {
          if (venue == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppEmptyState(
                      icon: Icons.storefront_outlined,
                      message:
                          '${l10n.merchantNoVenueLinked}\n\n${l10n.merchantEnterInvitePrompt}',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton.primary(
                      label: l10n.merchantEnterInviteBtn,
                      onPressed: () => context.push('/merchant/invite'),
                      icon: const Icon(Icons.vpn_key_rounded, size: 18),
                      expanded: false,
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: colorScheme.primary,
            onRefresh: () => _refreshDashboardData(context, ref),
            child: ListView(
              padding: AppSpacing.screenPadding,
              children: [
                _VenueHeaderCard(venue: venue),
                const SizedBox(height: AppSpacing.xl),
                _SectionTitle(title: l10n.merchantManageVenue),
                const SizedBox(height: AppSpacing.md),
                _QuickActionsGrid(),
                const SizedBox(height: AppSpacing.xxl),
                statsAsync.when(
                  loading: () => const Center(child: WainLoadingIndicator()),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (stats) => _StatsSection(stats: stats),
                ),
                const SizedBox(height: AppSpacing.xxl),
                _TrendsSection(),
                const SizedBox(height: AppSpacing.xxl),
                statsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (stats) => _ReviewsSection(stats: stats),
                ),
                const SizedBox(height: AppSpacing.xxl),
                _OffersSection(),
                const SizedBox(height: AppSpacing.xxl),
                _VenueInfoSection(venue: venue),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VenueHeaderCard extends StatelessWidget {
  final Map<String, dynamic> venue;

  const _VenueHeaderCard({required this.venue});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final photos = (venue['photos'] as List?)?.cast<dynamic>() ?? const [];
    final moods =
        ((venue['tags'] as Map?)?['mood'] as List?)?.cast<dynamic>() ??
        const [];

    bool? isOpen;
    try {
      isOpen = Venue.fromJson(venue).isOpenNow();
    } catch (_) {
      isOpen = null;
    }

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
                        image: NetworkImage('${photos.first}'),
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
                    venue['name_ar'] ?? l10n.merchantDefaultVenueName,
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
                    _StatusPill(
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

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final actions = <_QuickAction>[
      _QuickAction(
        icon: Icons.qr_code_scanner_rounded,
        label: l10n.merchantQuickActionScan,
        route: '/merchant/scan',
        color: AppTheme.errorColor,
      ),
      _QuickAction(
        icon: Icons.edit_rounded,
        label: l10n.merchantQuickActionEdit,
        route: '/merchant/edit-venue',
        color: Theme.of(context).colorScheme.primary,
      ),
      _QuickAction(
        icon: Icons.local_offer_rounded,
        label: l10n.merchantQuickActionOffers,
        route: '/merchant/offers',
        color: AppTheme.successColor,
      ),
      _QuickAction(
        icon: Icons.photo_camera_rounded,
        label: l10n.merchantQuickActionPhotos,
        route: '/merchant/photos',
        color: AppTheme.warningColor,
      ),
      _QuickAction(
        icon: Icons.rate_review_rounded,
        label: l10n.merchantQuickActionReviews,
        route: '/merchant/reviews',
        color: AppTheme.infoColor,
      ),
      _QuickAction(
        icon: Icons.restaurant_menu_rounded,
        label: l10n.merchantQuickActionMenu,
        route: '/merchant/venue/menu',
        color: colorScheme.secondary,
      ),
      _QuickAction(
        icon: Icons.access_time_rounded,
        label: l10n.merchantQuickActionHours,
        route: '/merchant/venue/hours',
        color: colorScheme.tertiary,
      ),
      _QuickAction(
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

class _StatsSection extends ConsumerWidget {
  final MerchantStats stats;

  const _StatsSection({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final analyticsAsync = ref.watch(merchantAnalyticsProvider);
    final dailyAsync = ref.watch(merchantAnalyticsDailyProvider(14));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: l10n.merchantStats),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.star_rounded,
                value: stats.rating.toStringAsFixed(1),
                label: l10n.merchantRating,
                accent: AppTheme.warningColor,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _StatCard(
                icon: Icons.rate_review_rounded,
                value: stats.reviewCount.toString(),
                label: l10n.merchantReviewCount,
                accent: AppTheme.infoColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        analyticsAsync.when(
          loading: () => const Center(child: WainLoadingIndicator()),
          error: (_, _) => const SizedBox.shrink(),
          data: (analytics) {
            final points =
                dailyAsync.asData?.value ?? const <MerchantDailyPoint>[];
            final viewsWoW = calculateDailyWoW(points, (point) => point.views);
            final callsWoW = calculateDailyWoW(points, (point) => point.calls);
            final navsWoW = calculateDailyWoW(points, (point) => point.navs);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.merchantVisitorEngagement,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      l10n.merchantThisWeek,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _AnalyticsCard(
                        icon: Icons.visibility_rounded,
                        value: '${analytics.viewsThisWeek}',
                        total: analytics.viewsTotal,
                        label: l10n.merchantViews,
                        wow: viewsWoW,
                        accent: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _AnalyticsCard(
                        icon: Icons.phone_rounded,
                        value: '${analytics.callsThisWeek}',
                        total: analytics.callsTotal,
                        label: l10n.merchantCalls,
                        wow: callsWoW,
                        accent: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _AnalyticsCard(
                        icon: Icons.navigation_rounded,
                        value: '${analytics.navsThisWeek}',
                        total: analytics.navsTotal,
                        label: l10n.merchantNavs,
                        wow: navsWoW,
                        accent: AppTheme.warningColor,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _AnalyticsCard(
                        icon: Icons.auto_stories_rounded,
                        value: '${analytics.storyViewsThisWeek}',
                        total: analytics.storyViewsTotal,
                        label: l10n.merchantStoryViews,
                        wow: null,
                        accent: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TrendsSection extends ConsumerWidget {
  const _TrendsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final rangeDays = ref.watch(trendRangeDaysProvider);
    final dailyAsync = ref.watch(merchantAnalyticsDailyProvider(rangeDays));
    final colorScheme = Theme.of(context).colorScheme;
    final rangeLabel = rangeDays == 7
        ? l10n.merchantDays7
        : l10n.merchantDays30;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _SectionTitle(title: l10n.merchantTrends)),
            ToggleButtons(
              isSelected: [rangeDays == 7, rangeDays == 30],
              onPressed: (index) {
                ref
                    .read(trendRangeDaysProvider.notifier)
                    .setRange(index == 0 ? 7 : 30);
              },
              borderRadius: AppSpacing.radiusSm,
              constraints: const BoxConstraints(minWidth: 54, minHeight: 36),
              textStyle: Theme.of(context).textTheme.labelMedium,
              selectedColor: colorScheme.primary,
              fillColor: colorScheme.primaryContainer,
              color: colorScheme.onSurfaceVariant,
              borderColor: colorScheme.outline,
              selectedBorderColor: colorScheme.primary,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Text(l10n.dashboard7Days),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Text(l10n.dashboard30Days),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        dailyAsync.when(
          loading: () => const _CardShell(
            child: SizedBox(
              height: 72,
              child: Center(child: WainLoadingIndicator()),
            ),
          ),
          error: (_, _) =>
              _TrendFallback(message: l10n.merchantTrendLoadFailed),
          data: (points) {
            if (points.isEmpty ||
                points.every(
                  (point) =>
                      point.views == 0 && point.calls == 0 && point.navs == 0,
                )) {
              return _TrendFallback(message: l10n.merchantNoTrendData);
            }

            final viewsWoW = calculateDailyWoW(points, (point) => point.views);
            final callsWoW = calculateDailyWoW(points, (point) => point.calls);
            final navsWoW = calculateDailyWoW(points, (point) => point.navs);
            final topDay = points.reduce(
              (left, right) => left.views >= right.views ? left : right,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _TrendPill(
                      label: l10n.merchantViewsWow,
                      wow: viewsWoW,
                      accent: Theme.of(context).colorScheme.primary,
                    ),
                    _TrendPill(
                      label: l10n.merchantCallsWow,
                      wow: callsWoW,
                      accent: AppTheme.successColor,
                    ),
                    _TrendPill(
                      label: l10n.merchantNavsWow,
                      wow: navsWoW,
                      accent: AppTheme.warningColor,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _TrendCard(
                  title: l10n.merchantViewsLast(rangeLabel),
                  values: points.map((point) => point.views).toList(),
                  accent: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                _TrendCard(
                  title: l10n.merchantCallsLast(rangeLabel),
                  values: points.map((point) => point.calls).toList(),
                  accent: AppTheme.successColor,
                ),
                const SizedBox(height: AppSpacing.md),
                _TrendCard(
                  title: l10n.merchantNavsLast(rangeLabel),
                  values: points.map((point) => point.navs).toList(),
                  accent: AppTheme.warningColor,
                ),
                const SizedBox(height: AppSpacing.md),
                _CardShell(
                  backgroundColor: AppTheme.warningColor.withAlpha(18),
                  borderColor: AppTheme.warningColor.withAlpha(60),
                  child: Row(
                    children: [
                      Icon(
                        Icons.emoji_events_rounded,
                        color: AppTheme.warningColor,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.merchantBestDay(topDay.dateKey, topDay.views),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  final MerchantStats stats;

  const _ReviewsSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (stats.recentReviews.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: l10n.merchantRecentReviews),
          const SizedBox(height: AppSpacing.md),
          _TrendFallback(message: l10n.merchantNoReviewsYet),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: l10n.merchantRecentReviews),
        const SizedBox(height: AppSpacing.md),
        ...stats.recentReviews.map(_ReviewCard.new),
      ],
    );
  }
}

class _OffersSection extends ConsumerWidget {
  const _OffersSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final offersAsync = ref.watch(merchantOffersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: l10n.merchantOffers),
        const SizedBox(height: AppSpacing.md),
        offersAsync.when(
          loading: () => const Center(child: WainLoadingIndicator()),
          error: (_, _) => const SizedBox.shrink(),
          data: (offers) {
            if (offers.isEmpty) {
              return _TrendFallback(message: l10n.merchantNoOffersNow);
            }

            return Column(
              children: offers
                  .map((offer) => _OfferRow(offer: offer))
                  .toList(growable: false),
            );
          },
        ),
      ],
    );
  }
}

class _VenueInfoSection extends StatelessWidget {
  final Map<String, dynamic> venue;

  const _VenueInfoSection({required this.venue});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories =
        (venue['categories'] as List?)?.map((item) => '$item').toList() ??
        const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: l10n.merchantVenueInfo),
        const SizedBox(height: AppSpacing.md),
        _CardShell(
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.storefront_rounded,
                label: l10n.merchantInfoName,
                value: venue['name_ar'] ?? '-',
              ),
              const Divider(height: AppSpacing.xl),
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: l10n.merchantInfoCity,
                value: venue['city'] ?? '-',
              ),
              const Divider(height: AppSpacing.xl),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: l10n.merchantInfoPhone,
                value: venue['phone'] ?? '-',
              ),
              if (categories.isNotEmpty) ...[
                const Divider(height: AppSpacing.xl),
                _InfoRow(
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.headlineSmall);
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;

  const _CardShell({
    required this.child,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: borderColor ?? colorScheme.outline),
        boxShadow: AppShadows.elevated,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return _CardShell(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withAlpha(22),
              borderRadius: AppSpacing.radiusMd,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: accent, size: 24),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(value, style: textTheme.displayMedium?.copyWith(fontSize: 26)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final int total;
  final String label;
  final double? wow;
  final Color accent;

  const _AnalyticsCard({
    required this.icon,
    required this.value,
    required this.total,
    required this.label,
    required this.wow,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final wowAccent = wow == null
        ? colorScheme.onSurfaceVariant
        : wow! >= 0
        ? AppTheme.successColor
        : AppTheme.errorColor;
    final wowBackground = wow == null
        ? colorScheme.surfaceContainerLow
        : wow! >= 0
        ? AppTheme.successColor.withAlpha(18)
        : AppTheme.errorColor.withAlpha(18);

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 22),
              const Spacer(),
              if (wow != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: wowBackground,
                    borderRadius: AppSpacing.radiusSm,
                  ),
                  child: Text(
                    '${wow! >= 0 ? '+' : ''}${wow!.toStringAsFixed(0)}%',
                    style: textTheme.labelSmall?.copyWith(color: wowAccent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: textTheme.displayMedium?.copyWith(
              fontSize: 24,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.merchantTotalLabel(total), style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _TrendFallback extends StatelessWidget {
  final String message;

  const _TrendFallback({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _CardShell(
      backgroundColor: colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          Icon(Icons.show_chart_outlined, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _TrendPill extends StatelessWidget {
  final String label;
  final double? wow;
  final Color accent;

  const _TrendPill({
    required this.label,
    required this.wow,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasWow = wow != null;
    final isPositive = (wow ?? 0) >= 0;
    final stateColor = !hasWow
        ? colorScheme.onSurfaceVariant
        : isPositive
        ? AppTheme.successColor
        : AppTheme.errorColor;
    final stateBackground = !hasWow
        ? colorScheme.surfaceContainerLow
        : isPositive
        ? AppTheme.successColor.withAlpha(18)
        : AppTheme.errorColor.withAlpha(18);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: stateBackground,
        borderRadius: AppSpacing.radiusMd,
        border: Border.all(color: stateColor.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              !hasWow
                  ? Icons.remove_rounded
                  : isPositive
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              size: 16,
              color: stateColor,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '$label: ',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: accent),
            ),
            Text(
              hasWow
                  ? '${isPositive ? '+' : ''}${wow!.toStringAsFixed(0)}%'
                  : '-',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: stateColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final String title;
  final List<int> values;
  final Color accent;

  const _TrendCard({
    required this.title,
    required this.values,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final allZero = values.every((value) => value == 0);

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 88,
            child: allZero
                ? Center(
                    child: Text(
                      l10n.merchantNoChartActivity,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : CustomPaint(
                    painter: _SimpleLineChartPainter(
                      values: values,
                      lineColor: accent,
                      guideColor: Theme.of(context).colorScheme.outline,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const _ReviewCard(this.review);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final rating = (review['rating'] as num?)?.toDouble() ?? 0;
    final comment = review['comment'] as String? ?? '';
    final userName = review['user_name'] as String? ?? l10n.merchantDefaultUser;
    final createdAt = review['created_at'] as Timestamp?;
    final dateStr = createdAt != null
        ? '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: _CardShell(
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

class _OfferRow extends StatelessWidget {
  final Map<String, dynamic> offer;

  const _OfferRow({required this.offer});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: _CardShell(
        backgroundColor: AppTheme.successColor.withAlpha(18),
        borderColor: AppTheme.successColor.withAlpha(60),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.successColor.withAlpha(24),
                borderRadius: AppSpacing.radiusMd,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.local_offer_rounded,
                color: AppTheme.successColor,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer['title_ar'] ??
                        offer['title'] ??
                        l10n.merchantDefaultOfferTitle,
                    style: textTheme.titleMedium,
                  ),
                  if (offer['description_ar'] != null ||
                      offer['description'] != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      offer['description_ar'] ?? offer['description'] ?? '',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
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

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color onColor;

  const _StatusPill({
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

class _SimpleLineChartPainter extends CustomPainter {
  final List<int> values;
  final Color lineColor;
  final Color guideColor;

  _SimpleLineChartPainter({
    required this.values,
    required this.lineColor,
    required this.guideColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    final guidePaint = Paint()
      ..color = guideColor.withAlpha(90)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      guidePaint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      guidePaint,
    );

    final maxValue = values.reduce(math.max).toDouble();
    final minValue = values.reduce(math.min).toDouble();
    final valueRange = (maxValue - minValue).abs() < 0.001
        ? 1.0
        : (maxValue - minValue);
    final usableHeight = math.max(1.0, size.height - 8);
    final stepX = values.length <= 1 ? 0.0 : size.width / (values.length - 1);

    final points = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final normalized = (values[index] - minValue) / valueRange;
      final x = stepX * index;
      final y = size.height - 4 - (normalized * usableHeight);
      points.add(Offset(x, y));
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index++) {
      linePath.lineTo(points[index].dx, points[index].dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withAlpha(56), lineColor.withAlpha(8)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = lineColor;
    canvas.drawCircle(points.first, 2.8, dotPaint);
    if (points.length > 1) {
      canvas.drawCircle(points.last, 2.8, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SimpleLineChartPainter oldDelegate) {
    if (oldDelegate.lineColor != lineColor ||
        oldDelegate.guideColor != guideColor ||
        oldDelegate.values.length != values.length) {
      return true;
    }
    for (var index = 0; index < values.length; index++) {
      if (oldDelegate.values[index] != values[index]) {
        return true;
      }
    }
    return false;
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });
}
