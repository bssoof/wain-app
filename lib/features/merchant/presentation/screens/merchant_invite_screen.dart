import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/widgets/app_button.dart';
import 'package:wain_app/l10n/app_localizations.dart';

import '../providers/merchant_dashboard_providers.dart';

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

    final result = await redeemInviteCode(code, AppLocalizations.of(context)!);

    if (!mounted) {
      return;
    }

    setState(() => _isLoading = false);

    if (result.success) {
      ref.invalidate(merchantVenueIdProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppTheme.successColor,
        ),
      );
      context.go('/merchant/dashboard');
      return;
    }

    setState(() => _errorMessage = result.message);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
        title: Text(l10n.inviteTitle),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                    AppButton.primary(
                      label: l10n.inviteVerifyBtn,
                      onPressed: _isLoading ? null : _submitCode,
                      isLoading: _isLoading,
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
