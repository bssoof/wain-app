import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/services/device_service.dart';
import 'package:wain_app/features/offers/domain/entities/offer.dart';

final userBenefitInsightsProvider =
    StreamProvider.family<UserBenefitInsights, String>((ref, userId) {
      final firestore = FirebaseFirestore.instance;

      return Stream.multi((controller) async {
        final deviceId = await ref.read(deviceServiceProvider).getDeviceId();

        QuerySnapshot<Map<String, dynamic>>? userSnapshot;
        QuerySnapshot<Map<String, dynamic>>? deviceSnapshot;

        Future<void> emitCombined() async {
          if (userSnapshot == null || deviceSnapshot == null) return;

          final docsById = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
          for (final doc in deviceSnapshot!.docs) {
            docsById[doc.id] = doc;
          }
          for (final doc in userSnapshot!.docs) {
            docsById[doc.id] = doc;
          }

          final combined = _CombinedClaimsSnapshot(docsById.values.toList());
          final insights = await _buildUserBenefitInsights(combined);
          if (!controller.isClosed) {
            controller.add(insights);
          }
        }

        final userSub = firestore
            .collection('offer_claims')
            .where('user_id', isEqualTo: userId)
            .snapshots(includeMetadataChanges: true)
            .listen((snapshot) async {
              userSnapshot = snapshot;
              await emitCombined();
            });

        final deviceSub = firestore
            .collection('offer_claims')
            .where('device_id', isEqualTo: deviceId)
            .snapshots(includeMetadataChanges: true)
            .listen((snapshot) async {
              deviceSnapshot = snapshot;
              await emitCombined();
            });

        ref.onDispose(() async {
          await userSub.cancel();
          await deviceSub.cancel();
          await controller.close();
        });
      });
    });

Future<UserBenefitInsights> _buildUserBenefitInsights(
  _ClaimsSnapshot claimsSnapshot,
) async {
  try {
    final claims = claimsSnapshot.docs.map(OfferClaim.fromFirestore).toList()
      ..sort((a, b) {
        final aTime = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

    final redeemedClaims = claims
        .where((claim) => claim.status == 'redeemed')
        .toList();
    final pendingClaims = claims
        .where((claim) => claim.status == 'pending')
        .length;
    final cancelledClaims = claims
        .where((claim) => claim.status == 'cancelled')
        .length;

    final offersById = <String, Offer>{};
    for (final offerId
        in redeemedClaims.map((claim) => claim.offerId).toSet()) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('offers')
            .doc(offerId)
            .get();
        if (doc.exists) {
          offersById[offerId] = Offer.fromFirestore(doc);
        }
      } catch (e) {
        debugPrint('Error fetching offer $offerId for benefit insights: $e');
      }
    }

    var confirmedSavings = 0.0;
    var amountOfferCount = 0;
    var extraDiscountCount = 0;
    var currency = 'ILS';

    final recentUsedOffers = <UsedOfferInsight>[];

    for (final claim in redeemedClaims) {
      final offer = offersById[claim.offerId];
      double? confirmedOfferSavings;

      if (claim.appliedSavings != null && claim.appliedSavings! > 0) {
        confirmedSavings += claim.appliedSavings!;
        confirmedOfferSavings = claim.appliedSavings!;
        amountOfferCount += 1;
        currency = claim.appliedCurrency ?? currency;
      } else if (claim.appliedDiscountType != null) {
        switch (claim.appliedDiscountType!) {
          case DiscountType.amount:
            final appliedValue = claim.appliedDiscountValue ?? 0;
            confirmedSavings += appliedValue;
            confirmedOfferSavings = appliedValue;
            amountOfferCount += 1;
            currency = claim.appliedCurrency ?? currency;
            break;
          case DiscountType.percent:
          case DiscountType.freeItem:
            extraDiscountCount += 1;
            break;
        }
      } else if (offer != null) {
        switch (offer.discountType) {
          case DiscountType.amount:
            confirmedSavings += offer.discountValue;
            confirmedOfferSavings = offer.discountValue;
            amountOfferCount += 1;
            currency = offer.currency ?? currency;
            break;
          case DiscountType.percent:
          case DiscountType.freeItem:
            extraDiscountCount += 1;
            break;
        }
      }

      if (recentUsedOffers.length < 5) {
        recentUsedOffers.add(
          UsedOfferInsight(
            claim: claim,
            offer: offer,
            confirmedSavings: confirmedOfferSavings,
          ),
        );
      }
    }

    return UserBenefitInsights(
      totalClaims: claims.length,
      redeemedClaims: redeemedClaims.length,
      pendingClaims: pendingClaims,
      cancelledClaims: cancelledClaims,
      confirmedSavings: confirmedSavings,
      currency: currency,
      fixedAmountOfferCount: amountOfferCount,
      extraDiscountCount: extraDiscountCount,
      recentUsedOffers: recentUsedOffers,
    );
  } catch (e) {
    debugPrint('Error fetching user benefit insights: $e');
    return const UserBenefitInsights.empty();
  }
}

abstract class _ClaimsSnapshot {
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs;
}

class _CombinedClaimsSnapshot implements _ClaimsSnapshot {
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  const _CombinedClaimsSnapshot(this.docs);
}

class UserBenefitInsights {
  final int totalClaims;
  final int redeemedClaims;
  final int pendingClaims;
  final int cancelledClaims;
  final double confirmedSavings;
  final String currency;
  final int fixedAmountOfferCount;
  final int extraDiscountCount;
  final List<UsedOfferInsight> recentUsedOffers;

  const UserBenefitInsights({
    required this.totalClaims,
    required this.redeemedClaims,
    required this.pendingClaims,
    required this.cancelledClaims,
    required this.confirmedSavings,
    required this.currency,
    required this.fixedAmountOfferCount,
    required this.extraDiscountCount,
    required this.recentUsedOffers,
  });

  const UserBenefitInsights.empty()
    : totalClaims = 0,
      redeemedClaims = 0,
      pendingClaims = 0,
      cancelledClaims = 0,
      confirmedSavings = 0,
      currency = 'ILS',
      fixedAmountOfferCount = 0,
      extraDiscountCount = 0,
      recentUsedOffers = const [];

  String formattedSavings() {
    return formatBenefitMoney(confirmedSavings, currency);
  }
}

class UsedOfferInsight {
  final OfferClaim claim;
  final Offer? offer;
  final double? confirmedSavings;

  const UsedOfferInsight({
    required this.claim,
    required this.offer,
    required this.confirmedSavings,
  });
}

String formatBenefitMoney(double value, String currency) {
  if (value <= 0) {
    return '0 $currency';
  }
  final isWhole = value == value.roundToDouble();
  return '${value.toStringAsFixed(isWhole ? 0 : 1)} $currency';
}
