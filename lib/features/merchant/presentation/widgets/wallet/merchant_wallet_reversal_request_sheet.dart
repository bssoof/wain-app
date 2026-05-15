import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/theme/app_colors.dart';
import 'package:wain_app/l10n/app_localizations.dart';

import '../../../data/repositories/merchant_wallet_repository.dart';
import '../../../domain/entities/merchant_wallet_entry.dart';
import '../../providers/merchant_wallet_providers.dart';

typedef MerchantWalletReversalSubmit =
    Future<void> Function({required String reason, String? note});

const _minimumReviewReasonLength = 10;

class MerchantWalletReversalRequestSheet extends ConsumerStatefulWidget {
  final String venueId;
  final MerchantWalletEntry entry;
  final MerchantWalletReversalSubmit? onSubmit;

  const MerchantWalletReversalRequestSheet({
    super.key,
    required this.venueId,
    required this.entry,
    this.onSubmit,
  });

  @override
  ConsumerState<MerchantWalletReversalRequestSheet> createState() =>
      _MerchantWalletReversalRequestSheetState();
}

class _MerchantWalletReversalRequestSheetState
    extends ConsumerState<MerchantWalletReversalRequestSheet> {
  final _reasonController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _reasonController.addListener(_onReasonChanged);
  }

  @override
  void dispose() {
    _reasonController
      ..removeListener(_onReasonChanged)
      ..dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onReasonChanged() => setState(() {});

  int get _reasonLength => _reasonController.text.trim().length;

  bool get _canSubmit => _reasonLength >= _minimumReviewReasonLength;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.merchantWalletReversalSheetTitle,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.merchantWalletReversalSheetSubtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('wallet-reversal-reason-field'),
              controller: _reasonController,
              minLines: 3,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                labelText: l10n.merchantWalletReversalReasonLabel,
                hintText: l10n.merchantWalletReversalReasonHint,
                helperText: l10n.merchantWalletReversalReasonMinLengthHint(
                  '$_minimumReviewReasonLength',
                ),
                counterText:
                    '${_reasonLength.clamp(0, _minimumReviewReasonLength)}/$_minimumReviewReasonLength',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('wallet-reversal-note-field'),
              controller: _noteController,
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                labelText: l10n.merchantWalletReversalNoteLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('wallet-reversal-submit-button'),
              onPressed: !_canSubmit || _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.rate_review_outlined),
              label: Text(l10n.merchantWalletReversalSubmit),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final reason = _reasonController.text.trim();
      final note = _noteController.text.trim();
      final onSubmit = widget.onSubmit;
      if (onSubmit != null) {
        await onSubmit(reason: reason, note: note.isEmpty ? null : note);
      } else {
        await ref
            .read(walletReversalRequestControllerProvider.notifier)
            .submitRequest(
              venueId: widget.venueId,
              entryId: widget.entry.id,
              reason: reason,
              note: note.isEmpty ? null : note,
            );
        final state = ref.read(walletReversalRequestControllerProvider);
        if (state.hasError) {
          final error = state.error;
          throw error is MerchantReversalException
              ? error
              : MerchantReversalException(l10n.merchantWalletReversalError);
        }
      }
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.merchantWalletReversalSuccess)),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is MerchantReversalException
          ? error.message
          : l10n.merchantWalletReversalError;
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
