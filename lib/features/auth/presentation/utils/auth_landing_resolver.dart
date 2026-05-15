import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_dashboard_providers.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_providers.dart';
import 'package:wain_app/features/onboarding/presentation/providers/onboarding_providers.dart';

const _homeRoute = '/home';
const _resultsRoute = '/results';
const _profileRoute = '/profile';
const _statsRoute = '/stats';
const _merchantDashboardRoute = '/merchant/dashboard';
const _merchantProbeTimeout = Duration(seconds: 3);

Future<String> resolvePostAuthLandingRoute(
  WidgetRef ref, {
  String? redirectTo,
  String? signedInUid,
}) async {
  final explicitRedirect = redirectTo?.trim();
  if (explicitRedirect != null &&
      explicitRedirect.isNotEmpty &&
      !_isGenericPostAuthRedirect(explicitRedirect)) {
    return explicitRedirect;
  }

  _refreshPostAuthProviders(ref);

  final merchantRoute = await _resolveMerchantLandingRoute(
    ref,
    signedInUid: signedInUid,
  );
  if (merchantRoute != null) {
    return merchantRoute;
  }

  if (explicitRedirect != null && explicitRedirect.isNotEmpty) {
    return explicitRedirect;
  }

  return ref.read(discoveryCompletedProvider) ? _resultsRoute : _homeRoute;
}

bool _isGenericPostAuthRedirect(String route) {
  final path = Uri.tryParse(route)?.path ?? route;
  return path == _homeRoute ||
      path == _resultsRoute ||
      path == _profileRoute ||
      path == _statsRoute;
}

Future<String?> _resolveMerchantLandingRoute(
  WidgetRef ref, {
  String? signedInUid,
}) async {
  try {
    var uid = signedInUid?.trim();
    if (uid == null || uid.isEmpty) {
      final user = await ref
          .read(currentUserProvider.future)
          .timeout(_merchantProbeTimeout);
      uid = user?.uid.trim();
    }
    if (uid == null || uid.isEmpty) return null;

    final repository = ref.read(merchantDashboardRepositoryProvider);
    final venueId =
        (await repository.getLinkedVenueId(uid).timeout(_merchantProbeTimeout))
            ?.trim();
    if (venueId == null || venueId.isEmpty) return null;

    final venueExists = await repository
        .venueExists(venueId)
        .timeout(_merchantProbeTimeout);
    return venueExists ? _merchantDashboardRoute : null;
  } catch (_) {
    // Auth success should not fail just because merchant access probing failed.
    return null;
  }
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
