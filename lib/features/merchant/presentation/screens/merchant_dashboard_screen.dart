import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/providers/offline_providers.dart';
import 'package:wain_app/core/routing/navigation_extensions.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/widgets/app_button.dart';
import 'package:wain_app/core/widgets/app_empty_state.dart';
import 'package:wain_app/core/widgets/offline_widgets.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_dashboard_refresh.dart';
import 'package:wain_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

import '../providers/merchant_dashboard_providers.dart';
import '../providers/merchant_invalidation.dart';
import '../providers/merchant_providers.dart';
import '../widgets/dashboard/merchant_dashboard_analytics.dart';
import '../widgets/dashboard/merchant_dashboard_content.dart';
import '../widgets/dashboard/merchant_dashboard_offers.dart';
import '../widgets/dashboard/merchant_dashboard_overview.dart';
import '../widgets/dashboard/merchant_dashboard_reviews.dart';
import '../widgets/dashboard/merchant_dashboard_shared.dart';
import '../widgets/dashboard/merchant_dashboard_wallet_card.dart';
import '../widgets/merchant_action_feed.dart';

class MerchantDashboardScreen extends ConsumerWidget {
  const MerchantDashboardScreen({super.key});

  Future<void> _refreshDashboardData(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    if (!ref.read(isOnlineProvider)) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.offlineActionRequiresConnection,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    try {
      final result = await ref
          .read(merchantDashboardRepositoryProvider)
          .refreshDashboard(debugMode: kDebugMode);

      final busyTimesStatus = _busyTimesRefreshStatusMessage(
        l10n,
        result.busyTimesStatus,
      );

      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.dashboardRefreshSuccess('${result.views}', '${result.calls}', '${result.navs}')}\n$busyTimesStatus',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on DashboardRefreshException catch (error) {
      debugPrint(
        'Backfill analytics failed: ${error.type} ${error.debugMessage}',
      );
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(_backfillErrorMessage(l10n, error)),
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
      ref.invalidateMerchantDashboardData();
    }
  }

  String _backfillErrorMessage(
    AppLocalizations l10n,
    DashboardRefreshException error,
  ) {
    switch (error.type) {
      case DashboardRefreshFailureType.permissionDenied:
        return l10n.dashboardErrorPermission;
      case DashboardRefreshFailureType.missingIndex:
        return l10n.dashboardErrorIndex;
      case DashboardRefreshFailureType.noVenue:
        return l10n.dashboardErrorNoVenue;
      case DashboardRefreshFailureType.unauthenticated:
        return l10n.dashboardErrorUnauthenticated;
      case DashboardRefreshFailureType.unknown:
        return l10n.dashboardRefreshFailed(
          error.debugMessage ?? error.type.name,
        );
    }
  }

  String _busyTimesRefreshStatusMessage(
    AppLocalizations l10n,
    BusyTimesRefreshStatus status,
  ) {
    switch (status) {
      case BusyTimesRefreshStatus.ready:
        return l10n.dashboardBusyTimesReady;
      case BusyTimesRefreshStatus.readyDemo:
        return l10n.dashboardBusyTimesReadyDemo;
      case BusyTimesRefreshStatus.pendingHours:
        return l10n.dashboardBusyTimesPendingHours;
      case BusyTimesRefreshStatus.pendingTimezone:
        return l10n.dashboardBusyTimesPendingTimezone;
      case BusyTimesRefreshStatus.pendingSignals:
        return l10n.dashboardBusyTimesPendingSignals;
      case BusyTimesRefreshStatus.pendingActiveDays:
        return l10n.dashboardBusyTimesPendingActiveDays;
      case BusyTimesRefreshStatus.pendingGeneric:
        return l10n.dashboardBusyTimesPendingGeneric;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final venueAsync = ref.watch(merchantVenueProvider);
    final venueSnapshotAsync = ref.watch(merchantVenueSnapshotProvider);
    final drilldownSnapshotAsync = ref.watch(
      merchantDashboardAnalyticsDrilldownSnapshotProvider,
    );
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.popOrGo('/profile'),
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
          final venueSnapshot = venueSnapshotAsync.asData?.value;
          final shouldShowOfflineEmpty =
              venue == null &&
              venueSnapshot != null &&
              !venueSnapshot.hasData &&
              venueSnapshot.isFromCache &&
              venueSnapshot.fetchedAt == null &&
              !ref.read(isOnlineProvider);

          if (shouldShowOfflineEmpty) {
            return const OfflineEmptyState(
              title: 'لا توجد نسخة محفوظة للوحة التاجر',
              subtitle:
                  'افتح لوحة التاجر مرة واحدة أثناء الاتصال لحفظ نسخة محلية.',
            );
          }

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
                drilldownSnapshotAsync.maybeWhen(
                  data: (snapshot) => OfflineBanner(
                    isVisible: snapshot.isFromCache,
                    fetchedAt: snapshot.fetchedAt,
                  ),
                  orElse: () => OfflineBanner(
                    isVisible: venueSnapshot?.isFromCache ?? false,
                    fetchedAt: venueSnapshot?.fetchedAt,
                  ),
                ),
                MerchantDashboardVenueHeaderCard(venue: venue),
                const SizedBox(height: AppSpacing.md),
                const MerchantDashboardWalletCard(),
                const SizedBox(height: AppSpacing.xl),
                MerchantActionFeed(
                  onRefreshRequested: () => _refreshDashboardData(context, ref),
                ),
                const SizedBox(height: AppSpacing.xl),
                MerchantDashboardSectionTitle(title: l10n.merchantManageVenue),
                const SizedBox(height: AppSpacing.md),
                const MerchantDashboardQuickActionsGrid(),
                const SizedBox(height: AppSpacing.xxl),
                const MerchantDashboardContentHealthSection(),
                const SizedBox(height: AppSpacing.xxl),
                const MerchantDashboardStatsSection(),
                const SizedBox(height: AppSpacing.xxl),
                const MerchantDashboardAnalyticsHighlightsSection(),
                const SizedBox(height: AppSpacing.xxl),
                const MerchantDashboardReviewsSection(),
                const MerchantDashboardReviewQualityCard(),
                const SizedBox(height: AppSpacing.xxl),
                const MerchantDashboardOffersSection(),
                const SizedBox(height: AppSpacing.xxl),
                MerchantDashboardVenueInfoSection(venue: venue),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          );
        },
      ),
    );
  }
}
