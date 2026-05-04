import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/providers/offline_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/routing/navigation_extensions.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/widgets/app_button.dart';
import 'package:wain_app/core/widgets/offline_widgets.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_invite_result.dart';
import 'package:wain_app/l10n/app_localizations.dart';

import '../providers/merchant_invalidation.dart';
import '../providers/merchant_providers.dart';

class MerchantInviteScreen extends ConsumerStatefulWidget {
  const MerchantInviteScreen({super.key});

  @override
  ConsumerState<MerchantInviteScreen> createState() =>
      _MerchantInviteScreenState();
}

class _MerchantInviteScreenState extends ConsumerState<MerchantInviteScreen> {
  final _codeController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitCode() async {
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
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(
        () => _errorMessage = AppLocalizations.of(context)!.inviteCodeEmpty,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final l10n = AppLocalizations.of(context)!;
    final result = await ref
        .read(merchantInviteRepositoryProvider)
        .redeemInviteCode(code);

    if (!mounted) {
      return;
    }

    setState(() => _isLoading = false);

    final message = _inviteResultMessage(l10n, result.type);

    if (result.isSuccess) {
      ref.invalidateMerchantAllData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.successColor,
        ),
      );
      context.go('/merchant/dashboard');
      return;
    }

    setState(() => _errorMessage = message);
  }

  String _inviteResultMessage(
    AppLocalizations l10n,
    MerchantInviteResultType type,
  ) {
    switch (type) {
      case MerchantInviteResultType.success:
        return l10n.inviteSuccess;
      case MerchantInviteResultType.invalidCode:
        return l10n.inviteInvalidCode;
      case MerchantInviteResultType.appCheckFailed:
        return l10n.inviteAppCheckFailed;
      case MerchantInviteResultType.codeExpired:
        return l10n.inviteCodeExpired;
      case MerchantInviteResultType.codeUsed:
        return l10n.inviteCodeUsed;
      case MerchantInviteResultType.codeUnavailable:
        return l10n.inviteCodeUnavailable;
      case MerchantInviteResultType.rateLimited:
        return l10n.inviteRateLimited;
      case MerchantInviteResultType.aborted:
        return l10n.inviteAborted;
      case MerchantInviteResultType.unauthenticated:
        return l10n.inviteUnauthenticated;
      case MerchantInviteResultType.activationFailed:
        return l10n.inviteActivationFailed;
      case MerchantInviteResultType.connectionError:
        return l10n.inviteConnectionError;
      case MerchantInviteResultType.retryError:
        return l10n.inviteRetryError;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isOnline = ref.watch(isOnlineProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.popOrGo('/profile'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.inviteTitle),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OfflineBanner(
              isVisible: !isOnline,
              message: 'إدخال كود الدعوة يحتاج اتصالاً بالإنترنت',
            ),
            if (!isOnline) const SizedBox(height: AppSpacing.lg),
            const SizedBox(height: AppSpacing.lg),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: AppSpacing.radiusLg,
                border: Border.all(color: colorScheme.outline),
                boxShadow: AppShadows.elevated,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: AppSpacing.radiusLg,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.storefront_rounded,
                        size: 40,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      l10n.inviteEnterCode,
                      textAlign: TextAlign.center,
                      style: textTheme.displayMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.inviteSubtitle,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: AppSpacing.radiusLg,
                border: Border.all(color: colorScheme.outline),
                boxShadow: AppShadows.elevated,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.inviteTitle, style: textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: _codeController,
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.done,
                      style: textTheme.displayMedium?.copyWith(
                        letterSpacing: 4,
                        fontSize: 24,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.inviteCodeHint,
                        hintStyle: textTheme.titleSmall?.copyWith(
                          letterSpacing: 2,
                        ),
                      ),
                      onSubmitted: (_) => _isLoading ? null : _submitCode(),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    OnlineOnlyGuard(
                      child: AppButton.primary(
                        label: l10n.inviteVerifyBtn,
                        onPressed: _isLoading ? null : _submitCode,
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withAlpha(16),
                borderRadius: AppSpacing.radiusLg,
                border: Border.all(color: AppTheme.infoColor.withAlpha(40)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppTheme.infoColor,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        l10n.inviteHelpText,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
