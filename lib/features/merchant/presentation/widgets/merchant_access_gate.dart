import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/widgets/app_button.dart';
import 'package:wain_app/core/widgets/app_empty_state.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_dashboard_providers.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

class MerchantAccessGate extends ConsumerWidget {
  final String currentLocation;
  final Widget child;

  const MerchantAccessGate({
    super.key,
    required this.currentLocation,
    required this.child,
  });

  bool get _isInviteRoute => currentLocation == '/merchant/invite';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessAsync = ref.watch(merchantRouteAccessProvider);
    final l10n = AppLocalizations.of(context)!;

    return accessAsync.when(
      loading: () => const _MerchantAccessScaffold(
        body: Center(child: WainLoadingIndicator()),
      ),
      error: (error, _) => _MerchantAccessScaffold(
        body: _MerchantAccessMessage(
          icon: Icons.error_outline_rounded,
          message: l10n.merchantErrorGeneric(error.toString()),
          primaryAction: AppButton.primary(
            label: l10n.retryButton,
            onPressed: () => ref.invalidate(merchantRouteAccessProvider),
            expanded: false,
          ),
          secondaryAction: AppButton.secondary(
            label: l10n.profileTitle,
            onPressed: () => context.go('/profile'),
            expanded: false,
          ),
        ),
      ),
      data: (access) {
        if (access.isReady && _isInviteRoute) {
          return const _MerchantRouteRedirect(
            targetRoute: '/merchant/dashboard',
          );
        }

        if (access.needsInviteFlow && !_isInviteRoute) {
          return const _MerchantRouteRedirect(targetRoute: '/merchant/invite');
        }

        if (access.hasBrokenVenueLink) {
          return _MerchantAccessScaffold(
            body: _MerchantAccessMessage(
              icon: Icons.store_mall_directory_outlined,
              message: l10n.dashboardErrorPermission,
              primaryAction: AppButton.primary(
                label: l10n.retryButton,
                onPressed: () => ref.invalidate(merchantRouteAccessProvider),
                expanded: false,
              ),
              secondaryAction: AppButton.secondary(
                label: l10n.profileTitle,
                onPressed: () => context.go('/profile'),
                expanded: false,
              ),
            ),
          );
        }

        if (access.isUnauthenticated) {
          return const _MerchantAccessScaffold(
            body: Center(child: WainLoadingIndicator()),
          );
        }

        return child;
      },
    );
  }
}

class _MerchantRouteRedirect extends StatefulWidget {
  final String targetRoute;

  const _MerchantRouteRedirect({required this.targetRoute});

  @override
  State<_MerchantRouteRedirect> createState() => _MerchantRouteRedirectState();
}

class _MerchantRouteRedirectState extends State<_MerchantRouteRedirect> {
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(widget.targetRoute);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const _MerchantAccessScaffold(
      body: Center(child: WainLoadingIndicator()),
    );
  }
}

class _MerchantAccessScaffold extends StatelessWidget {
  final Widget body;

  const _MerchantAccessScaffold({required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: body));
  }
}

class _MerchantAccessMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget primaryAction;
  final Widget secondaryAction;

  const _MerchantAccessMessage({
    required this.icon,
    required this.message,
    required this.primaryAction,
    required this.secondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppEmptyState(icon: icon, message: message),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              alignment: WrapAlignment.center,
              children: [primaryAction, secondaryAction],
            ),
          ],
        ),
      ),
    );
  }
}
