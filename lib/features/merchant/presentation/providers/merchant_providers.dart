import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
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

final merchantOffersRepositoryProvider = Provider<MerchantOffersRepository>((
  ref,
) {
  return FirestoreMerchantOffersRepository();
});

final merchantDashboardRepositoryProvider =
    Provider<MerchantDashboardRepository>((ref) {
      return MerchantDashboardRepository();
    });

final merchantInviteRepositoryProvider = Provider<MerchantInviteRepository>((
  ref,
) {
  return FirebaseMerchantInviteRepository();
});

final merchantReviewsRepositoryProvider = Provider<MerchantReviewsRepository>((
  ref,
) {
  return FirestoreMerchantReviewsRepository();
});

final merchantPhotosRepositoryProvider = Provider<MerchantPhotosRepository>((
  ref,
) {
  return FirebaseMerchantPhotosRepository();
});

final merchantHoursRepositoryProvider = Provider<MerchantHoursRepository>((
  ref,
) {
  return FirebaseMerchantHoursRepository();
});

final merchantVenueProfileRepositoryProvider =
    Provider<MerchantVenueProfileRepository>((ref) {
      return FirebaseMerchantVenueProfileRepository();
    });

final merchantStoriesRepositoryProvider = Provider<MerchantStoriesRepository>((
  ref,
) {
  return FirebaseMerchantStoriesRepository();
});

@riverpod
MerchantRepository merchantRepository(Ref ref) {
  return MerchantRepository();
}
