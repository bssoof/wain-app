import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_dashboard_providers.dart';
import 'package:wain_app/features/onboarding/presentation/providers/onboarding_providers.dart';

const _homeRoute = '/home';
const _resultsRoute = '/results';
const _merchantDashboardRoute = '/merchant/dashboard';

Future<String> resolvePostAuthLandingRoute(
  WidgetRef ref, {
  String? redirectTo,
}) async {
  final explicitRedirect = redirectTo?.trim();
  if (explicitRedirect != null && explicitRedirect.isNotEmpty) {
    return explicitRedirect;
  }

  _refreshPostAuthProviders(ref);

  try {
    final access = await ref.read(merchantRouteAccessProvider.future);
    if (access.isReady) {
      return _merchantDashboardRoute;
    }
  } catch (_) {
    // Auth success should not fail just because merchant access probing failed.
  }

  return ref.read(discoveryCompletedProvider) ? _resultsRoute : _homeRoute;
}

void _refreshPostAuthProviders(WidgetRef ref) {
  ref
    ..invalidate(authStateProvider)
    ..invalidate(currentUserProvider)
    ..invalidate(merchantVenueIdSnapshotProvider)
    ..invalidate(merchantVenueIdProvider)
    ..invalidate(merchantRouteAccessSnapshotProvider)
    ..invalidate(merchantRouteAccessProvider);
}
