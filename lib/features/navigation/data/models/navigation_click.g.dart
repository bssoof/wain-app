// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation_click.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NavigationClick _$NavigationClickFromJson(Map<String, dynamic> json) =>
    _NavigationClick(
      clickId: json['clickId'] as String?,
      venueId: json['venue_id'] as String,
      userId: json['user_id'] as String?,
      deviceId: json['device_id'] as String,
      timestamp: _timestampFromJson(json['timestamp']),
      navApp: json['nav_app'] as String,
      commissionAmount: (json['commission_amount'] as num?)?.toInt() ?? 2,
      commissionStatus: json['commission_status'] as String? ?? 'pending',
    );

Map<String, dynamic> _$NavigationClickToJson(_NavigationClick instance) =>
    <String, dynamic>{
      'venue_id': instance.venueId,
      'user_id': instance.userId,
      'device_id': instance.deviceId,
      'timestamp': _timestampToJson(instance.timestamp),
      'nav_app': instance.navApp,
      'commission_amount': instance.commissionAmount,
      'commission_status': instance.commissionStatus,
    };
