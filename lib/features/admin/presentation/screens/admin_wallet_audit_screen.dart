import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wain_app/features/admin/data/repositories/admin_wallet_audit_repository.dart';
import 'package:wain_app/features/admin/presentation/providers/admin_topup_review_providers.dart';
import 'package:wain_app/features/admin/presentation/providers/admin_wallet_audit_providers.dart';
import 'package:wain_app/features/admin/domain/entities/wallet_audit_event.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class AdminWalletAuditScreen extends ConsumerWidget {
  const AdminWalletAuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final accessAsync = ref.watch(adminAccessProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminWalletAuditTitle)),
      body: accessAsync.when(
        data: (hasAccess) {
          if (!hasAccess) {
            return Center(child: Text(l10n.adminTopUpReviewNoAccess));
          }
          return const _AuditBody();
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text(l10n.adminTopUpReviewLoadError)),
      ),
    );
  }
}

class _AuditBody extends ConsumerStatefulWidget {
  const _AuditBody();

  @override
  ConsumerState<_AuditBody> createState() => _AuditBodyState();
}

class _AuditBodyState extends ConsumerState<_AuditBody> {
  String? _selectedEventType;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.watch(adminWalletAuditRepositoryProvider);
    final reversalState = ref.watch(adminWalletReversalControllerProvider);
    final isReversing = reversalState.isLoading;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  key: ValueKey<String?>(_selectedEventType),
                  initialValue: _selectedEventType,
                  decoration: InputDecoration(
                    labelText: l10n.adminWalletAuditFilterType,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(l10n.adminWalletAuditFilterAll),
                    ),
                    const DropdownMenuItem(
                      value: 'story_promotion',
                      child: Text('story_promotion'),
                    ),
                    const DropdownMenuItem(
                      value: 'offer_pin',
                      child: Text('offer_pin'),
                    ),
                    const DropdownMenuItem(
                      value: 'topup_request_approved',
                      child: Text('topup_request_approved'),
                    ),
                    const DropdownMenuItem(
                      value: 'topup_request_rejected',
                      child: Text('topup_request_rejected'),
                    ),
                    const DropdownMenuItem(
                      value: 'topup_proof_deleted',
                      child: Text('topup_proof_deleted'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedEventType = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: repo.streamAuditEvents(eventType: _selectedEventType),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text(l10n.adminTopUpReviewLoadError));
              }
              final events = snapshot.data ?? const <WalletAuditEvent>[];
              if (events.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long, size: 36),
                      const SizedBox(height: 10),
                      Text(l10n.adminWalletAuditEmpty),
                      const SizedBox(height: 4),
                      Text(
                        l10n.adminWalletAuditEmptyHint,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final createdAt = DateFormat(
                    'yyyy/MM/dd HH:mm',
                  ).format(event.createdAt);
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      title: Row(
                        children: [
                          Expanded(child: Text(event.eventType)),
                          if ((event.reversalEntryId ?? '').isNotEmpty)
                            _StatusBadge(
                              label: l10n.adminWalletAuditReversedTag,
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${l10n.adminTopUpReviewVenue}: ${event.venueId ?? '-'}',
                          ),
                          Text(
                            '${l10n.adminWalletAuditRequestId}: ${event.requestId ?? '-'}',
                          ),
                          Text(
                            '${l10n.adminWalletAuditLinkedEntry}: ${event.linkedEntryId ?? '-'}',
                          ),
                          if ((event.reversalEntryId ?? '').isNotEmpty)
                            Text(
                              '${l10n.adminWalletAuditReversedLabel}: ${event.reversalEntryId}',
                            ),
                          Text(createdAt),
                        ],
                      ),
                      trailing: _buildReversalAction(
                        context: context,
                        eventType: event.eventType,
                        entryId: event.entryId,
                        venueId: event.venueId,
                        entryType: event.type,
                        featureKey: event.featureKey,
                        reversalEntryId: event.reversalEntryId,
                        isReversing: isReversing,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget? _buildReversalAction({
    required BuildContext context,
    required String eventType,
    required String? entryId,
    required String? venueId,
    required String? entryType,
    required String? featureKey,
    required String? reversalEntryId,
    required bool isReversing,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final hasReversal = (reversalEntryId ?? '').isNotEmpty;
    final eligibleFeature =
        featureKey == 'story_promotion' || featureKey == 'offer_pin';
    final eligibleDebitEvent =
        eventType == 'wallet_entry' && entryType == 'debit' && eligibleFeature;
    if (!eligibleDebitEvent) return null;
    if (hasReversal) {
      return Text(
        l10n.adminWalletAuditReversedTag,
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
    }
    if (entryId == null ||
        entryId.isEmpty ||
        venueId == null ||
        venueId.isEmpty) {
      return null;
    }
    return TextButton(
      onPressed: isReversing
          ? null
          : () => _showReversalDialog(
              context: context,
              entryId: entryId,
              venueId: venueId,
            ),
      child: Text(l10n.adminWalletAuditReverseCta),
    );
  }

  Future<void> _showReversalDialog({
    required BuildContext context,
    required String entryId,
    required String venueId,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    final adminNoteController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool submitting = false;
        String? reasonError;
        String? submitError;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: Text(l10n.adminWalletAuditReverseDialogTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: l10n.adminWalletAuditReverseReasonLabel,
                    errorText: reasonError,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: adminNoteController,
                  decoration: InputDecoration(
                    labelText: l10n.adminWalletAuditReverseAdminNoteLabel,
                  ),
                  maxLines: 2,
                ),
                if (submitError != null) ...[
                  const SizedBox(height: 8),
                  Text(submitError!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: submitting
                    ? null
                    : () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: submitting
                    ? null
                    : () async {
                        final reason = reasonController.text.trim();
                        if (reason.isEmpty) {
                          setDialogState(() {
                            reasonError =
                                l10n.adminWalletAuditReverseReasonRequired;
                            submitError = null;
                          });
                          return;
                        }
                        setDialogState(() {
                          submitting = true;
                          reasonError = null;
                          submitError = null;
                        });
                        await ref
                            .read(
                              adminWalletReversalControllerProvider.notifier,
                            )
                            .reverseEntry(
                              entryId: entryId,
                              venueId: venueId,
                              reason: reason,
                              adminNote: adminNoteController.text.trim(),
                            );
                        final state = ref.read(
                          adminWalletReversalControllerProvider,
                        );
                        if (state.hasError) {
                          setDialogState(() {
                            submitting = false;
                            submitError =
                                '${l10n.adminTopUpReviewActionError}: ${state.error}';
                          });
                          return;
                        }
                        if (!dialogContext.mounted) return;
                        setState(() {});
                        Navigator.of(dialogContext).pop(true);
                      },
                child: submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.adminWalletAuditReverseConfirm),
              ),
            ],
          ),
        );
      },
    );

    if (result == true) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.adminWalletAuditReverseSuccess)),
      );
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;

  const _StatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(24),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.green.shade800,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
