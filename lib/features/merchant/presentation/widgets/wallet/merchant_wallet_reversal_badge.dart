import 'package:flutter/material.dart';
import 'package:wain_app/core/theme/app_colors.dart';
import 'package:wain_app/l10n/app_localizations.dart';

import '../../../domain/entities/merchant_wallet_reversal_request.dart';

class MerchantWalletReversalBadge extends StatelessWidget {
  final MerchantWalletReversalRequest request;

  const MerchantWalletReversalBadge({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = _badgeStyle(request.status);
    final label = _statusLabel(l10n, request.status);
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: style.color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: style.color.withAlpha(75)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: style.color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    final tooltip = request.status == ReversalRequestStatus.rejected
        ? (request.rejectionReason ?? request.adminNote)
        : null;
    if (tooltip == null || tooltip.trim().isEmpty) return badge;
    return Tooltip(message: tooltip, child: badge);
  }

  _BadgeStyle _badgeStyle(ReversalRequestStatus status) {
    switch (status) {
      case ReversalRequestStatus.pendingReview:
        return const _BadgeStyle(AppColors.warning);
      case ReversalRequestStatus.pendingSecondApproval:
        return const _BadgeStyle(AppColors.info);
      case ReversalRequestStatus.approvedAndExecuted:
        return const _BadgeStyle(AppColors.success);
      case ReversalRequestStatus.rejected:
      case ReversalRequestStatus.expired:
      case ReversalRequestStatus.unknown:
        return const _BadgeStyle(AppColors.textSecondary);
    }
  }

  String _statusLabel(AppLocalizations l10n, ReversalRequestStatus status) {
    switch (status) {
      case ReversalRequestStatus.pendingReview:
        return l10n.merchantWalletReversalStatusPendingReview;
      case ReversalRequestStatus.pendingSecondApproval:
        return l10n.merchantWalletReversalStatusPendingSecondApproval;
      case ReversalRequestStatus.approvedAndExecuted:
        return l10n.merchantWalletReversalStatusApproved;
      case ReversalRequestStatus.rejected:
        return l10n.merchantWalletReversalStatusRejected;
      case ReversalRequestStatus.expired:
        return l10n.merchantWalletReversalStatusExpired;
      case ReversalRequestStatus.unknown:
        return l10n.merchantWalletReversalStatusUnknown;
    }
  }
}

class _BadgeStyle {
  final Color color;

  const _BadgeStyle(this.color);
}
