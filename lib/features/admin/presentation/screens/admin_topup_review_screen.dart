import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wain_app/features/admin/presentation/providers/admin_topup_review_providers.dart';
import 'package:wain_app/core/routing/app_router.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_topup_request.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class AdminTopUpReviewScreen extends ConsumerWidget {
  const AdminTopUpReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final adminAccessAsync = ref.watch(adminAccessProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminTopUpReviewTitle),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.adminWalletAudit),
            icon: const Icon(Icons.query_stats),
            tooltip: l10n.adminWalletAuditTitle,
          ),
        ],
      ),
      body: adminAccessAsync.when(
        data: (hasAccess) {
          if (!hasAccess) {
            return Center(child: Text(l10n.adminTopUpReviewNoAccess));
          }
          final requestsAsync = ref.watch(adminPendingTopUpsProvider);
          return requestsAsync.when(
            data: (requests) {
              if (requests.isEmpty) {
                return Center(child: Text(l10n.adminTopUpReviewEmpty));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  return _AdminTopUpCard(request: requests[index]);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text(l10n.adminTopUpReviewLoadError)),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text(l10n.adminTopUpReviewLoadError)),
      ),
    );
  }
}

class _AdminTopUpCard extends ConsumerWidget {
  final MerchantTopUpRequest request;
  const _AdminTopUpCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final reviewState = ref.watch(adminTopUpReviewControllerProvider);
    final isLoading = reviewState.isLoading;
    final date = DateFormat('yyyy/MM/dd HH:mm').format(request.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${request.amount.toStringAsFixed(2)} ${request.currency}',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text('${l10n.adminTopUpReviewVenue}: ${request.venueId}'),
            Text(
              '${l10n.adminTopUpReviewRequester}: ${request.requestedByUid}',
            ),
            Text('${l10n.adminTopUpReviewCreatedAt}: $date'),
            if ((request.transferReference ?? '').isNotEmpty)
              Text(
                '${l10n.adminTopUpReviewReference}: ${request.transferReference}',
              ),
            if ((request.note ?? '').isNotEmpty)
              Text('${l10n.adminTopUpReviewNote}: ${request.note}'),
            if ((request.proofImageUrl ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              FutureBuilder<String?>(
                future: _resolveProofUrl(request.proofImageUrl!),
                builder: (context, snapshot) {
                  final url = snapshot.data;
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (url == null || url.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return InkWell(
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (_) => Dialog(
                        child: InteractiveViewer(
                          child: Image.network(url, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        url,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: isLoading
                        ? null
                        : () => _approve(context, ref, request.id),
                    child: Text(l10n.adminTopUpReviewApprove),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading
                        ? null
                        : () => _reject(context, ref, request.id),
                    child: Text(l10n.adminTopUpReviewReject),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _resolveProofUrl(String proofImageRefOrUrl) async {
    if (proofImageRefOrUrl.startsWith('http://') ||
        proofImageRefOrUrl.startsWith('https://')) {
      return proofImageRefOrUrl;
    }
    try {
      return await FirebaseStorage.instance
          .ref(proofImageRefOrUrl)
          .getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    String requestId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await ref
        .read(adminTopUpReviewControllerProvider.notifier)
        .review(requestId: requestId, decision: 'credit');
    final state = ref.read(adminTopUpReviewControllerProvider);
    if (!context.mounted) return;
    state.whenOrNull(
      data: (_) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.adminTopUpReviewApproved))),
      error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.adminTopUpReviewActionError}: $e')),
      ),
    );
  }

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    String requestId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.adminTopUpReviewReject),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: l10n.adminTopUpReviewRejectNoteRequired,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final value = noteController.text.trim();
              if (value.isEmpty) return;
              Navigator.of(dialogContext).pop(value);
            },
            child: Text(l10n.adminTopUpReviewReject),
          ),
        ],
      ),
    );
    if (note == null || note.isEmpty) return;
    await ref
        .read(adminTopUpReviewControllerProvider.notifier)
        .review(requestId: requestId, decision: 'reject', adminNote: note);
    final state = ref.read(adminTopUpReviewControllerProvider);
    if (!context.mounted) return;
    state.whenOrNull(
      data: (_) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.adminTopUpReviewRejected))),
      error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.adminTopUpReviewActionError}: $e')),
      ),
    );
  }
}
