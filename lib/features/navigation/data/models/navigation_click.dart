// ignore_for_file: invalid_annotation_target
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'navigation_click.freezed.dart';
part 'navigation_click.g.dart';

/// Represents a navigation click event for analytics and commission tracking
@freezed
sealed class NavigationClick with _$NavigationClick {
  const factory NavigationClick({
    /// Auto-generated click ID (Firestore document ID)
    @JsonKey(includeToJson: false) String? clickId,

    /// Venue that was navigated to
    @JsonKey(name: 'venue_id') required String venueId,

    /// User ID (null for guests)
    @JsonKey(name: 'user_id') String? userId,

    /// Device unique identifier
    @JsonKey(name: 'device_id') required String deviceId,

    /// Timestamp of the click
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    required DateTime timestamp,

    /// Navigation app used: 'google_maps' | 'waze'
    @JsonKey(name: 'nav_app') required String navApp,

    /// Commission amount per click (default 2 ILS)
    @JsonKey(name: 'commission_amount') @Default(2) int commissionAmount,

    /// Commission status: 'pending' | 'paid'
    @JsonKey(name: 'commission_status')
    @Default('pending')
    String commissionStatus,
  }) = _NavigationClick;

  factory NavigationClick.fromJson(Map<String, dynamic> json) =>
      _$NavigationClickFromJson(json);

  factory NavigationClick.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return NavigationClick.fromJson({...data, 'clickId': doc.id});
  }
}

// Helper functions for Timestamp conversion
DateTime _timestampFromJson(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is String) {
    return DateTime.parse(value);
  }
  return DateTime.now();
}

dynamic _timestampToJson(DateTime date) {
  return Timestamp.fromDate(date);
}
