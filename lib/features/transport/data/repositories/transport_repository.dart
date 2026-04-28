import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:wain_app/core/providers/location_provider.dart';
import 'package:wain_app/core/services/device_service.dart';

class TransportQuote {
  const TransportQuote({
    required this.quoteId,
    required this.partnerId,
    required this.partnerName,
    required this.serviceType,
    required this.estimatedPrice,
    required this.priceMin,
    required this.priceMax,
    required this.currency,
    required this.etaMinutes,
    required this.tripMinutes,
    required this.generatedAt,
    required this.expiresAt,
    required this.priceConfidence,
    required this.quoteSource,
    required this.pricingVersion,
    required this.handoffType,
  });

  final String quoteId;
  final String partnerId;
  final String partnerName;
  final String serviceType;
  final double estimatedPrice;
  final double priceMin;
  final double priceMax;
  final String currency;
  final int etaMinutes;
  final int tripMinutes;
  final DateTime generatedAt;
  final DateTime expiresAt;
  final String priceConfidence;
  final String quoteSource;
  final String pricingVersion;
  final String handoffType;

  bool get isEstimate => priceConfidence == 'estimate';
  bool get isExpired => expiresAt.isBefore(DateTime.now());

  factory TransportQuote.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    int toInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    DateTime toDate(dynamic value) {
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return TransportQuote(
      quoteId: (json['quoteId'] ?? '').toString(),
      partnerId: (json['partnerId'] ?? '').toString(),
      partnerName: (json['partnerName'] ?? '').toString(),
      serviceType: (json['serviceType'] ?? '').toString(),
      estimatedPrice: toDouble(json['estimatedPrice']),
      priceMin: toDouble(json['priceMin']),
      priceMax: toDouble(json['priceMax']),
      currency: (json['currency'] ?? 'ILS').toString(),
      etaMinutes: toInt(json['etaMinutes']),
      tripMinutes: toInt(json['tripMinutes']),
      generatedAt: toDate(json['generatedAt']),
      expiresAt: toDate(json['expiresAt']),
      priceConfidence: (json['priceConfidence'] ?? 'estimate').toString(),
      quoteSource: (json['quoteSource'] ?? 'managed').toString(),
      pricingVersion: (json['pricingVersion'] ?? 'v1').toString(),
      handoffType: (json['handoffType'] ?? '').toString(),
    );
  }
}

class TransportQuotesResult {
  const TransportQuotesResult({
    required this.originMode,
    required this.generatedAt,
    required this.expiresAt,
    required this.quotes,
  });

  final String originMode;
  final DateTime generatedAt;
  final DateTime expiresAt;
  final List<TransportQuote> quotes;

  factory TransportQuotesResult.fromJson(Map<String, dynamic> json) {
    DateTime toDate(dynamic value) {
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    final rawQuotes = (json['quotes'] as List<dynamic>? ?? const [])
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => TransportQuote.fromJson(e.cast<String, dynamic>()))
        .toList();

    return TransportQuotesResult(
      originMode: (json['originMode'] ?? 'real_location').toString(),
      generatedAt: toDate(json['generatedAt']),
      expiresAt: toDate(json['expiresAt']),
      quotes: rawQuotes,
    );
  }
}

class TransportHandoffResult {
  const TransportHandoffResult({
    required this.handoffId,
    required this.handoffType,
    required this.handoffUrl,
  });

  final String handoffId;
  final String handoffType;
  final String handoffUrl;

  factory TransportHandoffResult.fromJson(Map<String, dynamic> json) {
    return TransportHandoffResult(
      handoffId: (json['handoffId'] ?? '').toString(),
      handoffType: (json['handoffType'] ?? '').toString(),
      handoffUrl: (json['handoffUrl'] ?? '').toString(),
    );
  }
}

abstract class TransportRepository {
  Future<TransportQuotesResult> getQuotes({
    required String venueId,
    required String city,
    required UserLocation userLocation,
    required String source,
  });

  Future<TransportHandoffResult> createHandoff({
    required String venueId,
    required String quoteId,
    required String source,
  });
}

class TransportRepositoryImpl implements TransportRepository {
  TransportRepositoryImpl({
    required FirebaseFunctions functions,
    required FirebaseAuth auth,
    required DeviceService deviceService,
  }) : _functions = functions,
       _auth = auth,
       _deviceService = deviceService;

  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;
  final DeviceService _deviceService;

  @override
  Future<TransportQuotesResult> getQuotes({
    required String venueId,
    required String city,
    required UserLocation userLocation,
    required String source,
  }) async {
    final deviceId = await _deviceService.getDeviceId();
    final callable = _functions.httpsCallable('getTransportQuotes');

    try {
      final result = await callable.call({
        'venueId': venueId,
        'city': city,
        'originLat': userLocation.latitude,
        'originLng': userLocation.longitude,
        'isRealLocation': userLocation.isRealLocation,
        'source': source,
        'deviceId': deviceId,
      });

      final data = (result.data as Map<Object?, Object?>)
          .cast<String, dynamic>();
      return TransportQuotesResult.fromJson(data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'Transport getQuotes failed: ${e.code} - ${e.message} - ${e.details}',
      );
      rethrow;
    }
  }

  @override
  Future<TransportHandoffResult> createHandoff({
    required String venueId,
    required String quoteId,
    required String source,
  }) async {
    final deviceId = await _deviceService.getDeviceId();
    final callable = _functions.httpsCallable('createTransportHandoff');

    try {
      final result = await callable.call({
        'venueId': venueId,
        'quoteId': quoteId,
        'source': source,
        'deviceId': deviceId,
        'uid': _auth.currentUser?.uid,
      });

      final data = (result.data as Map<Object?, Object?>)
          .cast<String, dynamic>();
      return TransportHandoffResult.fromJson(data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'Transport createHandoff failed: ${e.code} - ${e.message} - ${e.details}',
      );
      rethrow;
    }
  }
}
