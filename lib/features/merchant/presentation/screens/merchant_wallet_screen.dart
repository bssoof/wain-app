import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:wain_app/core/theme/app_colors.dart';
import '../../domain/entities/merchant_wallet_entry.dart';
import '../../domain/entities/merchant_topup_request.dart';
import '../../domain/entities/merchant_wallet_report.dart';
import '../providers/merchant_wallet_providers.dart';
import '../widgets/wallet/merchant_topup_request_sheet.dart';

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
                      if (isLowBalance)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.error.withAlpha(55),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.merchantWalletLowBalance,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(76),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.merchantWalletBalance,
                              style: textTheme.titleMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  balance.toStringAsFixed(2),
                                  style: textTheme.displayMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: Text(
                                    currency,
                                    style: textTheme.titleMedium?.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primary,
                                minimumSize: const Size(double.infinity, 52),
                              ),
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
                                      const MerchantTopUpRequestSheet(),
                                );
                              },
                              child: Text(l10n.merchantWalletTopUp),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _WalletSummarySection(reportAsync: reportAsync),
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
          requestsAsync.when(
            data: (requests) {
              if (requests.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        l10n.merchantWalletNoTopUpRequests,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
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
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) =>
                SliverToBoxAdapter(child: Text(l10n.merchantWalletLoadError)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                l10n.merchantWalletTopUpRequests,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                l10n.merchantWalletTransactions,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          entriesAsync.when(
            data: (entries) {
              if (entries.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        l10n.merchantWalletNoEntries,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final entry = entries[index];
                  return _WalletEntryTile(entry: entry);
                }, childCount: entries.length),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) =>
                SliverToBoxAdapter(child: Text(l10n.merchantWalletLoadError)),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
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
            Text(
              '${request.amount.toStringAsFixed(2)} ${request.currency}',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
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

  const _WalletSummarySection({required this.reportAsync});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    return reportAsync.when(
      data: (report) {
        final topupTotalCredited = report?.topupTotalCredited ?? 0;
        final totalDebited = report?.totalDebited ?? 0;
        final last30Debited = report?.last30dDebited ?? 0;
        final mostUsed = _featureLabel(
          l10n,
          report?.mostUsedDebitFeature ?? 'other',
        );
        final currency = report?.currency ?? 'ILS';

        return Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.merchantWalletSummaryTitle,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.merchantWalletSummaryTotalCredited(
                    topupTotalCredited.toStringAsFixed(2),
                    currency,
                  ),
                ),
                Text(
                  l10n.merchantWalletSummaryTotalDebited(
                    totalDebited.toStringAsFixed(2),
                    currency,
                  ),
                ),
                Text(
                  l10n.merchantWalletSummaryLast30Debited(
                    last30Debited.toStringAsFixed(2),
                    currency,
                  ),
                ),
                Text(l10n.merchantWalletSummaryMostUsedFeature(mostUsed)),
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

class _WalletEntryTile extends StatelessWidget {
  final MerchantWalletEntry entry;

  const _WalletEntryTile({required this.entry});

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
