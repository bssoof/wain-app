import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wain_app/features/demo/application/demo_merchant_session.dart';
import 'package:wain_app/features/demo/data/demo_merchant_repositories.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_dashboard_repository.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_hours_repository.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_invite_repository.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_offers_repository.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_photos_repository.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_reviews_repository.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_repository.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_stories_repository.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_venue_profile_repository.dart';

part 'merchant_providers.g.dart';

/// Every merchant repository is chosen here, and the demo walkthrough is
/// chosen at exactly the same point.
///
/// This is the whole seam. A demo merchant surface reaches Firebase only if one
/// of these falls through to the production adapter while the session flag is
/// on, which is what `demo_merchant_isolation_test` asserts one provider at a
/// time. Nothing downstream of here needs to know the demo exists.

final merchantOffersRepositoryProvider = Provider<MerchantOffersRepository>((
  ref,
) {
  if (isDemoMerchantSession(ref)) return DemoMerchantOffersRepository();
  return FirestoreMerchantOffersRepository();
});

final merchantDashboardRepositoryProvider =
    Provider<MerchantDashboardRepository>((ref) {
      if (isDemoMerchantSession(ref)) return DemoMerchantDashboardRepository();
      return MerchantDashboardRepository();
    });

final merchantInviteRepositoryProvider = Provider<MerchantInviteRepository>((
  ref,
) {
  if (isDemoMerchantSession(ref)) return DemoMerchantInviteRepository();
  return FirebaseMerchantInviteRepository();
});

final merchantReviewsRepositoryProvider = Provider<MerchantReviewsRepository>((
  ref,
) {
  if (isDemoMerchantSession(ref)) return DemoMerchantReviewsRepository();
  return FirestoreMerchantReviewsRepository();
});

final merchantPhotosRepositoryProvider = Provider<MerchantPhotosRepository>((
  ref,
) {
  if (isDemoMerchantSession(ref)) return DemoMerchantPhotosRepository();
  return FirebaseMerchantPhotosRepository();
});

final merchantHoursRepositoryProvider = Provider<MerchantHoursRepository>((
  ref,
) {
  if (isDemoMerchantSession(ref)) return DemoMerchantHoursRepository();
  return FirebaseMerchantHoursRepository();
});

final merchantVenueProfileRepositoryProvider =
    Provider<MerchantVenueProfileRepository>((ref) {
      if (isDemoMerchantSession(ref)) {
        return DemoMerchantVenueProfileRepository();
      }
      return FirebaseMerchantVenueProfileRepository();
    });

final merchantStoriesRepositoryProvider = Provider<MerchantStoriesRepository>((
  ref,
) {
  if (isDemoMerchantSession(ref)) return DemoMerchantStoriesRepository();
  return FirebaseMerchantStoriesRepository();
});

@riverpod
MerchantRepository merchantRepository(Ref ref) {
  if (isDemoMerchantSession(ref)) return DemoMerchantRepository();
  return MerchantRepository();
}
