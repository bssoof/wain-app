// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'navigation_click.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NavigationClick {

/// Auto-generated click ID (Firestore document ID)
@JsonKey(includeToJson: false) String? get clickId;/// Venue that was navigated to
@JsonKey(name: 'venue_id') String get venueId;/// User ID (null for guests)
@JsonKey(name: 'user_id') String? get userId;/// Device unique identifier
@JsonKey(name: 'device_id') String get deviceId;/// Timestamp of the click
@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime get timestamp;/// Navigation app used: 'google_maps' | 'waze'
@JsonKey(name: 'nav_app') String get navApp;/// Commission amount per click (default 2 ILS)
@JsonKey(name: 'commission_amount') int get commissionAmount;/// Commission status: 'pending' | 'paid'
@JsonKey(name: 'commission_status') String get commissionStatus;
/// Create a copy of NavigationClick
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NavigationClickCopyWith<NavigationClick> get copyWith => _$NavigationClickCopyWithImpl<NavigationClick>(this as NavigationClick, _$identity);

  /// Serializes this NavigationClick to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NavigationClick&&(identical(other.clickId, clickId) || other.clickId == clickId)&&(identical(other.venueId, venueId) || other.venueId == venueId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.navApp, navApp) || other.navApp == navApp)&&(identical(other.commissionAmount, commissionAmount) || other.commissionAmount == commissionAmount)&&(identical(other.commissionStatus, commissionStatus) || other.commissionStatus == commissionStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,clickId,venueId,userId,deviceId,timestamp,navApp,commissionAmount,commissionStatus);

@override
String toString() {
  return 'NavigationClick(clickId: $clickId, venueId: $venueId, userId: $userId, deviceId: $deviceId, timestamp: $timestamp, navApp: $navApp, commissionAmount: $commissionAmount, commissionStatus: $commissionStatus)';
}


}

/// @nodoc
abstract mixin class $NavigationClickCopyWith<$Res>  {
  factory $NavigationClickCopyWith(NavigationClick value, $Res Function(NavigationClick) _then) = _$NavigationClickCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeToJson: false) String? clickId,@JsonKey(name: 'venue_id') String venueId,@JsonKey(name: 'user_id') String? userId,@JsonKey(name: 'device_id') String deviceId,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime timestamp,@JsonKey(name: 'nav_app') String navApp,@JsonKey(name: 'commission_amount') int commissionAmount,@JsonKey(name: 'commission_status') String commissionStatus
});




}
/// @nodoc
class _$NavigationClickCopyWithImpl<$Res>
    implements $NavigationClickCopyWith<$Res> {
  _$NavigationClickCopyWithImpl(this._self, this._then);

  final NavigationClick _self;
  final $Res Function(NavigationClick) _then;

/// Create a copy of NavigationClick
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clickId = freezed,Object? venueId = null,Object? userId = freezed,Object? deviceId = null,Object? timestamp = null,Object? navApp = null,Object? commissionAmount = null,Object? commissionStatus = null,}) {
  return _then(_self.copyWith(
clickId: freezed == clickId ? _self.clickId : clickId // ignore: cast_nullable_to_non_nullable
as String?,venueId: null == venueId ? _self.venueId : venueId // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,navApp: null == navApp ? _self.navApp : navApp // ignore: cast_nullable_to_non_nullable
as String,commissionAmount: null == commissionAmount ? _self.commissionAmount : commissionAmount // ignore: cast_nullable_to_non_nullable
as int,commissionStatus: null == commissionStatus ? _self.commissionStatus : commissionStatus // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [NavigationClick].
extension NavigationClickPatterns on NavigationClick {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NavigationClick value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NavigationClick() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NavigationClick value)  $default,){
final _that = this;
switch (_that) {
case _NavigationClick():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NavigationClick value)?  $default,){
final _that = this;
switch (_that) {
case _NavigationClick() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String? clickId, @JsonKey(name: 'venue_id')  String venueId, @JsonKey(name: 'user_id')  String? userId, @JsonKey(name: 'device_id')  String deviceId, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime timestamp, @JsonKey(name: 'nav_app')  String navApp, @JsonKey(name: 'commission_amount')  int commissionAmount, @JsonKey(name: 'commission_status')  String commissionStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NavigationClick() when $default != null:
return $default(_that.clickId,_that.venueId,_that.userId,_that.deviceId,_that.timestamp,_that.navApp,_that.commissionAmount,_that.commissionStatus);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeToJson: false)  String? clickId, @JsonKey(name: 'venue_id')  String venueId, @JsonKey(name: 'user_id')  String? userId, @JsonKey(name: 'device_id')  String deviceId, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime timestamp, @JsonKey(name: 'nav_app')  String navApp, @JsonKey(name: 'commission_amount')  int commissionAmount, @JsonKey(name: 'commission_status')  String commissionStatus)  $default,) {final _that = this;
switch (_that) {
case _NavigationClick():
return $default(_that.clickId,_that.venueId,_that.userId,_that.deviceId,_that.timestamp,_that.navApp,_that.commissionAmount,_that.commissionStatus);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeToJson: false)  String? clickId, @JsonKey(name: 'venue_id')  String venueId, @JsonKey(name: 'user_id')  String? userId, @JsonKey(name: 'device_id')  String deviceId, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime timestamp, @JsonKey(name: 'nav_app')  String navApp, @JsonKey(name: 'commission_amount')  int commissionAmount, @JsonKey(name: 'commission_status')  String commissionStatus)?  $default,) {final _that = this;
switch (_that) {
case _NavigationClick() when $default != null:
return $default(_that.clickId,_that.venueId,_that.userId,_that.deviceId,_that.timestamp,_that.navApp,_that.commissionAmount,_that.commissionStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NavigationClick implements NavigationClick {
  const _NavigationClick({@JsonKey(includeToJson: false) this.clickId, @JsonKey(name: 'venue_id') required this.venueId, @JsonKey(name: 'user_id') this.userId, @JsonKey(name: 'device_id') required this.deviceId, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) required this.timestamp, @JsonKey(name: 'nav_app') required this.navApp, @JsonKey(name: 'commission_amount') this.commissionAmount = 2, @JsonKey(name: 'commission_status') this.commissionStatus = 'pending'});
  factory _NavigationClick.fromJson(Map<String, dynamic> json) => _$NavigationClickFromJson(json);

/// Auto-generated click ID (Firestore document ID)
@override@JsonKey(includeToJson: false) final  String? clickId;
/// Venue that was navigated to
@override@JsonKey(name: 'venue_id') final  String venueId;
/// User ID (null for guests)
@override@JsonKey(name: 'user_id') final  String? userId;
/// Device unique identifier
@override@JsonKey(name: 'device_id') final  String deviceId;
/// Timestamp of the click
@override@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) final  DateTime timestamp;
/// Navigation app used: 'google_maps' | 'waze'
@override@JsonKey(name: 'nav_app') final  String navApp;
/// Commission amount per click (default 2 ILS)
@override@JsonKey(name: 'commission_amount') final  int commissionAmount;
/// Commission status: 'pending' | 'paid'
@override@JsonKey(name: 'commission_status') final  String commissionStatus;

/// Create a copy of NavigationClick
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NavigationClickCopyWith<_NavigationClick> get copyWith => __$NavigationClickCopyWithImpl<_NavigationClick>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NavigationClickToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NavigationClick&&(identical(other.clickId, clickId) || other.clickId == clickId)&&(identical(other.venueId, venueId) || other.venueId == venueId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.navApp, navApp) || other.navApp == navApp)&&(identical(other.commissionAmount, commissionAmount) || other.commissionAmount == commissionAmount)&&(identical(other.commissionStatus, commissionStatus) || other.commissionStatus == commissionStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,clickId,venueId,userId,deviceId,timestamp,navApp,commissionAmount,commissionStatus);

@override
String toString() {
  return 'NavigationClick(clickId: $clickId, venueId: $venueId, userId: $userId, deviceId: $deviceId, timestamp: $timestamp, navApp: $navApp, commissionAmount: $commissionAmount, commissionStatus: $commissionStatus)';
}


}

/// @nodoc
abstract mixin class _$NavigationClickCopyWith<$Res> implements $NavigationClickCopyWith<$Res> {
  factory _$NavigationClickCopyWith(_NavigationClick value, $Res Function(_NavigationClick) _then) = __$NavigationClickCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeToJson: false) String? clickId,@JsonKey(name: 'venue_id') String venueId,@JsonKey(name: 'user_id') String? userId,@JsonKey(name: 'device_id') String deviceId,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime timestamp,@JsonKey(name: 'nav_app') String navApp,@JsonKey(name: 'commission_amount') int commissionAmount,@JsonKey(name: 'commission_status') String commissionStatus
});




}
/// @nodoc
class __$NavigationClickCopyWithImpl<$Res>
    implements _$NavigationClickCopyWith<$Res> {
  __$NavigationClickCopyWithImpl(this._self, this._then);

  final _NavigationClick _self;
  final $Res Function(_NavigationClick) _then;

/// Create a copy of NavigationClick
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clickId = freezed,Object? venueId = null,Object? userId = freezed,Object? deviceId = null,Object? timestamp = null,Object? navApp = null,Object? commissionAmount = null,Object? commissionStatus = null,}) {
  return _then(_NavigationClick(
clickId: freezed == clickId ? _self.clickId : clickId // ignore: cast_nullable_to_non_nullable
as String?,venueId: null == venueId ? _self.venueId : venueId // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,navApp: null == navApp ? _self.navApp : navApp // ignore: cast_nullable_to_non_nullable
as String,commissionAmount: null == commissionAmount ? _self.commissionAmount : commissionAmount // ignore: cast_nullable_to_non_nullable
as int,commissionStatus: null == commissionStatus ? _self.commissionStatus : commissionStatus // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
