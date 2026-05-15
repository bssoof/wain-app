import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/services/device_service.dart';
import 'package:wain_app/features/offers/domain/entities/offer.dart';

double _roundBenefitMoney(double value) =>
    double.parse(value.toStringAsFixed(2));

double? _resolvedConfirmedSavings(OfferClaim claim) {
  if (claim.appliedSavings != null && claim.appliedSavings! > 0) {
    return claim.appliedSavings!;
  }

  switch (claim.appliedDiscountType) {
    case DiscountType.amount:
      final appliedValue = claim.appliedDiscountValue ?? 0;
      return appliedValue > 0 ? appliedValue : null;
    case DiscountType.percent:
      final billAmount = claim.appliedBillAmount;
      final discountValue = claim.appliedDiscountValue;
      if (billAmount != null &&
          billAmount > 0 &&
          discountValue != null &&
          discountValue > 0) {
        final savings = billAmount * discountValue / 100;
        return _roundBenefitMoney(savings.clamp(0, billAmount).toDouble());
      }
      return null;
    case DiscountType.freeItem:
    case null:
      return null;
  }
}

final userBenefitInsightsProvider =
    StreamProvider.family<UserBenefitInsights, String>((ref, userId) {
      final firestore = FirebaseFirestore.instance;
      final deviceService = ref.watch(deviceServiceProvider);

      return Stream.multi((controller) async {
        var userDocs = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
        var deviceDocs =
            <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};

        Future<void> emitInsights() async {
          final combined =
              <String, QueryDocumentSnapshot<Map<String, dynamic>>>{
                ...deviceDocs,
                ...userDocs,
              };
          final insights = await _buildUserBenefitInsights(
            _CombinedClaimsSnapshot(combined.values.toList()),
          );
          if (!controller.isClosed) {
            controller.add(insights);
          }
        }

        final userSub = firestore
            .collection('offer_claims')
            .where('user_id', isEqualTo: userId)
            .snapshots(includeMetadataChanges: true)
            .listen((snapshot) async {
              userDocs = _docsById(snapshot.docs);
              await emitInsights();
            });

        StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? deviceSub;
        try {
          final deviceId = await deviceService.getDeviceId();
          if (deviceId.trim().isNotEmpty) {
            deviceSub = firestore
                .collection('offer_claims')
                .where('device_id', isEqualTo: deviceId)
                .snapshots(includeMetadataChanges: true)
                .listen((snapshot) async {
                  deviceDocs = _docsById(snapshot.docs);
                  await emitInsights();
                });
          }
        } catch (e) {
          debugPrint('Error reading device claims for benefit insights: $e');
        }

        ref.onDispose(() async {
          await userSub.cancel();
          await deviceSub?.cancel();
          await controller.close();
        });
      });
    });

Map<String, QueryDocumentSnapshot<Map<String, dynamic>>> _docsById(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) {
  return {for (final doc in docs) doc.id: doc};
}

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

    final redeemedClaims = claims.where(_isRedeemedClaim).toList();
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
      var confirmedOfferSavings = _resolvedConfirmedSavings(claim);

      if (confirmedOfferSavings != null && confirmedOfferSavings > 0) {
        confirmedSavings += confirmedOfferSavings;
        amountOfferCount += 1;
        currency = claim.appliedCurrency ?? currency;
      } else if (claim.appliedDiscountType != null) {
        switch (claim.appliedDiscountType!) {
          case DiscountType.amount:
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

bool _isRedeemedClaim(OfferClaim claim) {
  final status = claim.status.trim().toLowerCase();
  return status == 'redeemed' || status == 'used' || status == 'completed';
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
