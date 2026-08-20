import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:wain_app/core/theme/app_colors.dart';
import 'package:wain_app/features/demo/application/demo_merchant_session.dart';
import 'package:wain_app/features/demo/presentation/demo_data_notice.dart';
import '../../domain/entities/merchant_wallet_entry.dart';
import '../../domain/entities/merchant_wallet_reversal_request.dart';
import '../../domain/entities/merchant_topup_request.dart';
import '../../domain/entities/merchant_wallet_report.dart';
import '../../domain/services/merchant_wallet_reversal_rules.dart';
import '../providers/merchant_wallet_providers.dart';
import '../widgets/wallet/merchant_topup_request_sheet.dart';
import '../widgets/wallet/merchant_wallet_reversal_badge.dart';
import '../widgets/wallet/merchant_wallet_reversal_request_sheet.dart';

class MerchantWalletScreen extends ConsumerWidget {
  const MerchantWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final walletAsync = ref.watch(merchantWalletStreamProvider);
    final requestsAsync = ref.watch(merchantTopUpRequestsStreamProvider);
    final entriesAsync = ref.watch(merchantWalletEntriesStreamProvider);
    final reportAsync = ref.watch(merchantWalletReportStreamProvider);
    final reversalRequestsAsync = ref.watch(
      merchantWalletReversalRequestsStreamProvider,
    );
    final merchantVenueId = ref.watch(merchantWalletVenueIdProvider).value;
    final isDemo = ref.watch(demoMerchantActiveProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.merchantWalletTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: walletAsync.when(
                data: (wallet) {
                  final balance = wallet?.availableBalance ?? 0.0;
                  final currency = wallet?.currency ?? 'ILS';
                  final isLowBalance = wallet?.isLowBalance ?? false;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isDemo) ...[
                        const DemoDataNotice(
                          key: Key('demo_wallet_local_notice'),
                          label:
                              'محاكاة محلية — لا يتم خصم أو تحويل أموال حقيقية',
                          alwaysShow: true,
                        ),
                        const SizedBox(height: 12),
                      ],
                      _WalletBalanceCard(
                        balance: balance,
                        currency: currency,
                        isLowBalance: isLowBalance,
                        onTopUp: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder: (context) =>
                                const MerchantTopUpRequestSheet(),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _WalletSummarySection(
                        reportAsync: reportAsync,
                        topUpRequestsAsync: requestsAsync,
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text(
                  l10n.merchantWalletLoadError,
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _WalletSectionHeader(
              title: l10n.merchantWalletTopUpRequests,
            ),
          ),
          requestsAsync.when(
            data: (requests) {
              if (requests.isEmpty) {
                return SliverToBoxAdapter(
                  child: _WalletEmptyCard(
                    message: l10n.merchantWalletNoTopUpRequests,
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final req = requests[index];
                  return _TopUpRequestTile(request: req);
                }, childCount: requests.length),
              );
            },
            loading: () =>
                const SliverToBoxAdapter(child: _WalletLoadingCard()),
            error: (e, st) => SliverToBoxAdapter(
              child: _WalletLoadErrorCard(
                message: l10n.merchantWalletLoadError,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _WalletSectionHeader(title: l10n.merchantWalletTransactions),
          ),
          entriesAsync.when(
            data: (entries) {
              final reversalRequests = reversalRequestsAsync.when(
                data: (requests) => requests,
                loading: () => null,
                error: (_, _) => null,
              );
              if (entries.isEmpty) {
                return SliverToBoxAdapter(
                  child: _WalletEmptyCard(
                    message: l10n.merchantWalletNoEntries,
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final entry = entries[index];
                  final reversalRequest = reversalRequests == null
                      ? null
                      : reversalRequestForEntry(
                          entry: entry,
                          existingRequests: reversalRequests,
                        );
                  return _WalletEntryTile(
                    entry: entry,
                    venueId: merchantVenueId,
                    reversalRequest: reversalRequest,
                    canRequestReview:
                        reversalRequests != null &&
                        canRequestWalletEntryReview(
                          entry: entry,
                          existingRequests: reversalRequests,
                        ),
                  );
                }, childCount: entries.length),
              );
            },
            loading: () =>
                const SliverToBoxAdapter(child: _WalletLoadingCard()),
            error: (e, st) => SliverToBoxAdapter(
              child: _WalletLoadErrorCard(
                message: l10n.merchantWalletLoadError,
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }
}

class _WalletBalanceCard extends StatelessWidget {
  final double balance;
  final String currency;
  final bool isLowBalance;
  final VoidCallback onTopUp;

  const _WalletBalanceCard({
    required this.balance,
    required this.currency,
    required this.isLowBalance,
    required this.onTopUp,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(82),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(34),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withAlpha(45)),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  l10n.merchantWalletBalance,
                  style: textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(35),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  currency,
                  style: textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          FittedBox(
            alignment: AlignmentDirectional.centerStart,
            fit: BoxFit.scaleDown,
            child: Text(
              balance.toStringAsFixed(2),
              style: textTheme.displayLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                height: 0.95,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _localizedCopy(
              context,
              ar: 'الرصيد المتاح لاستخدام مزايا وين المدفوعة.',
              en: 'Available balance for WAIN paid features.',
            ),
            style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          if (isLowBalance) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(28),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withAlpha(45)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.merchantWalletLowBalance,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: onTopUp,
            icon: const Icon(Icons.add_card_rounded),
            label: Text(l10n.merchantWalletTopUp),
          ),
        ],
      ),
    );
  }
}

class _WalletSectionHeader extends StatelessWidget {
  final String title;

  const _WalletSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Text(
        title,
        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _WalletEmptyCard extends StatelessWidget {
  final String message;

  const _WalletEmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.inbox_outlined, color: colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletLoadingCard extends StatelessWidget {
  const _WalletLoadingCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        child: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            const SizedBox(width: 12),
            Text(
              _localizedCopy(
                context,
                ar: 'جاري تحميل البيانات...',
                en: 'Loading data...',
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletLoadErrorCard extends StatelessWidget {
  final String message;

  const _WalletLoadErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.error.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopUpRequestTile extends StatelessWidget {
  final MerchantTopUpRequest request;

  const _TopUpRequestTile({required this.request});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final formatter = DateFormat('yyyy/MM/dd hh:mm a');

    Color statusColor;
    String statusText;

    switch (request.status) {
      case TopUpRequestStatus.pending:
        statusColor = AppColors.warning;
        statusText = l10n.merchantWalletStatusPending;
        break;
      case TopUpRequestStatus.credited:
        statusColor = AppColors.success;
        statusText = l10n.merchantWalletStatusCredited;
        break;
      case TopUpRequestStatus.rejected:
      case TopUpRequestStatus.cancelled:
        statusColor = AppColors.error;
        statusText = l10n.merchantWalletStatusRejected;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                '${request.amount.toStringAsFixed(2)} ${request.currency}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25), // ~0.1
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusText,
                style: textTheme.bodySmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatter.format(request.createdAt),
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (request.status == TopUpRequestStatus.credited &&
                  request.linkedEntryId != null &&
                  request.linkedEntryId!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.merchantWalletTopUpReflected,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
              if (request.status == TopUpRequestStatus.rejected &&
                  request.adminNote != null &&
                  request.adminNote!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.merchantWalletRejectedReason(request.adminNote!),
                  style: textTheme.bodySmall?.copyWith(color: AppColors.error),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (request.note != null && request.note!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  request.note!,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletSummarySection extends StatelessWidget {
  final AsyncValue<MerchantWalletReport?> reportAsync;
  final AsyncValue<List<MerchantTopUpRequest>> topUpRequestsAsync;

  const _WalletSummarySection({
    required this.reportAsync,
    required this.topUpRequestsAsync,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    return reportAsync.when(
      data: (report) {
        final totalCredited = report?.totalCredited ?? 0;
        final topupTotalCredited = report?.topupTotalCredited ?? 0;
        final pendingTopUpTotal = topUpRequestsAsync.maybeWhen(
          data: (requests) => requests
              .where((request) => request.status == TopUpRequestStatus.pending)
              .fold<double>(0, (total, request) => total + request.amount),
          orElse: () => 0,
        );
        final totalDebited = report?.totalDebited ?? 0;
        final last30Debited = report?.last30dDebited ?? 0;
        final mostUsed = _featureLabel(
          l10n,
          report?.mostUsedDebitFeature ?? 'other',
        );
        final requestCurrency = topUpRequestsAsync.maybeWhen(
          data: (requests) => requests.isEmpty ? null : requests.first.currency,
          orElse: () => null,
        );
        final currency = report?.currency ?? requestCurrency ?? 'ILS';

        return Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.merchantWalletSummaryTitle,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.merchantWalletSummaryTotalCredited(
                    totalCredited.toStringAsFixed(2),
                    currency,
                  ),
                ),
                Text(
                  l10n.merchantWalletSummaryApprovedTopUps(
                    topupTotalCredited.toStringAsFixed(2),
                    currency,
                  ),
                ),
                Text(
                  l10n.merchantWalletSummaryPendingTopUps(
                    pendingTopUpTotal.toStringAsFixed(2),
                    currency,
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = (constraints.maxWidth - 10) / 2;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _WalletSummaryMetric(
                          width: itemWidth,
                          icon: Icons.add_card_rounded,
                          label: _localizedCopy(
                            context,
                            ar: 'إجمالي الشحن',
                            en: 'Total top-ups',
                          ),
                          value:
                              '${topupTotalCredited.toStringAsFixed(2)} $currency',
                          color: AppColors.success,
                        ),
                        _WalletSummaryMetric(
                          width: itemWidth,
                          icon: Icons.payments_outlined,
                          label: _localizedCopy(
                            context,
                            ar: 'إجمالي الاستخدام',
                            en: 'Total spent',
                          ),
                          value: '${totalDebited.toStringAsFixed(2)} $currency',
                          color: AppColors.primary,
                        ),
                        _WalletSummaryMetric(
                          width: itemWidth,
                          icon: Icons.calendar_month_rounded,
                          label: _localizedCopy(
                            context,
                            ar: 'آخر 30 يوم',
                            en: 'Last 30 days',
                          ),
                          value:
                              '${last30Debited.toStringAsFixed(2)} $currency',
                          color: AppColors.warning,
                        ),
                        _WalletSummaryMetric(
                          width: itemWidth,
                          icon: Icons.auto_awesome_rounded,
                          label: _localizedCopy(
                            context,
                            ar: 'الأكثر استخداماً',
                            en: 'Most used',
                          ),
                          value: mostUsed,
                          color: AppColors.info,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }

  String _featureLabel(AppLocalizations l10n, String key) {
    if (key == 'story_promotion') return l10n.merchantWalletEntryStoryPromotion;
    if (key == 'offer_pin') return l10n.merchantWalletSummaryOfferPin;
    return l10n.merchantWalletEntryGeneric;
  }
}

class _WalletSummaryMetric extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _WalletSummaryMetric({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(46)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 10),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletEntryTile extends StatelessWidget {
  final MerchantWalletEntry entry;
  final String? venueId;
  final MerchantWalletReversalRequest? reversalRequest;
  final bool canRequestReview;

  const _WalletEntryTile({
    required this.entry,
    this.venueId,
    this.reversalRequest,
    this.canRequestReview = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final formatter = DateFormat('yyyy/MM/dd hh:mm a');
    final isCredit = entry.isCredit;
    final amountPrefix = isCredit ? '+' : '-';
    final amountColor = isCredit ? AppColors.success : AppColors.textPrimary;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          '$amountPrefix${_formatAmount(entry.amount)} ${_entryLabel(context, entry)}',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: amountColor,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatter.format(entry.createdAt),
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.merchantWalletBalanceAfter(
                  entry.balanceAfter.toStringAsFixed(2),
                  entry.currency,
                ),
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (reversalRequest != null) ...[
                const SizedBox(height: 8),
                MerchantWalletReversalBadge(request: reversalRequest!),
              ] else if (canRequestReview && venueId != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    key: ValueKey('wallet-review-${entry.id}'),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (context) =>
                            MerchantWalletReversalRequestSheet(
                              venueId: venueId!,
                              entry: entry,
                            ),
                      );
                    },
                    icon: const Icon(Icons.rate_review_outlined),
                    label: Text(l10n.merchantWalletReversalRequestCta),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _entryLabel(BuildContext context, MerchantWalletEntry entry) {
    final l10n = AppLocalizations.of(context)!;
    if (entry.referenceType == 'topup_request') {
      return l10n.merchantWalletEntryTopUp;
    }
    if (entry.featureKey == 'story_promotion') {
      final durationDays = entry.metadata['duration_days'];
      if (durationDays is num && durationDays > 0) {
        return l10n.merchantWalletEntryStoryPromotionDays(
          '${durationDays.toInt()}',
        );
      }
      return l10n.merchantWalletEntryStoryPromotion;
    }
    return entry.note?.trim().isNotEmpty == true
        ? entry.note!.trim()
        : l10n.merchantWalletEntryGeneric;
  }

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toStringAsFixed(0);
    }
    return amount.toStringAsFixed(2);
  }
}

String _localizedCopy(
  BuildContext context, {
  required String ar,
  required String en,
}) {
  return Localizations.localeOf(context).languageCode == 'ar' ? ar : en;
}
