// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppUser {

/// Firebase Auth UID
 String get uid;/// Phone number (+970 or +972 format)
@JsonKey(name: 'phone_number') String get phoneNumber;/// When the user first signed up
@JsonKey(name: 'created_at', fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime get createdAt;/// Whether this is an anonymous/guest user
@JsonKey(name: 'is_anonymous') bool get isAnonymous;/// Unique username (@username)
 String? get username;/// Display name (from Google Sign-In)
@JsonKey(name: 'display_name') String? get displayName;/// Email address (from Google Sign-In)
 String? get email;/// Profile photo URL (from Google Sign-In)
@JsonKey(name: 'photo_url') String? get photoUrl;/// User's favorite venues (synced with Firestore)
 List<String> get favorites;
/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppUserCopyWith<AppUser> get copyWith => _$AppUserCopyWithImpl<AppUser>(this as AppUser, _$identity);

  /// Serializes this AppUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppUser&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isAnonymous, isAnonymous) || other.isAnonymous == isAnonymous)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&const DeepCollectionEquality().equals(other.favorites, favorites));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uid,phoneNumber,createdAt,isAnonymous,username,displayName,email,photoUrl,const DeepCollectionEquality().hash(favorites));

@override
String toString() {
  return 'AppUser(uid: $uid, phoneNumber: $phoneNumber, createdAt: $createdAt, isAnonymous: $isAnonymous, username: $username, displayName: $displayName, email: $email, photoUrl: $photoUrl, favorites: $favorites)';
}


}

/// @nodoc
abstract mixin class $AppUserCopyWith<$Res>  {
  factory $AppUserCopyWith(AppUser value, $Res Function(AppUser) _then) = _$AppUserCopyWithImpl;
@useResult
$Res call({
 String uid,@JsonKey(name: 'phone_number') String phoneNumber,@JsonKey(name: 'created_at', fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime createdAt,@JsonKey(name: 'is_anonymous') bool isAnonymous, String? username,@JsonKey(name: 'display_name') String? displayName, String? email,@JsonKey(name: 'photo_url') String? photoUrl, List<String> favorites
});




}
/// @nodoc
class _$AppUserCopyWithImpl<$Res>
    implements $AppUserCopyWith<$Res> {
  _$AppUserCopyWithImpl(this._self, this._then);

  final AppUser _self;
  final $Res Function(AppUser) _then;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? phoneNumber = null,Object? createdAt = null,Object? isAnonymous = null,Object? username = freezed,Object? displayName = freezed,Object? email = freezed,Object? photoUrl = freezed,Object? favorites = null,}) {
  return _then(_self.copyWith(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,isAnonymous: null == isAnonymous ? _self.isAnonymous : isAnonymous // ignore: cast_nullable_to_non_nullable
as bool,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,favorites: null == favorites ? _self.favorites : favorites // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [AppUser].
extension AppUserPatterns on AppUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppUser value)  $default,){
final _that = this;
switch (_that) {
case _AppUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppUser value)?  $default,){
final _that = this;
switch (_that) {
case _AppUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid, @JsonKey(name: 'phone_number')  String phoneNumber, @JsonKey(name: 'created_at', fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime createdAt, @JsonKey(name: 'is_anonymous')  bool isAnonymous,  String? username, @JsonKey(name: 'display_name')  String? displayName,  String? email, @JsonKey(name: 'photo_url')  String? photoUrl,  List<String> favorites)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppUser() when $default != null:
return $default(_that.uid,_that.phoneNumber,_that.createdAt,_that.isAnonymous,_that.username,_that.displayName,_that.email,_that.photoUrl,_that.favorites);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid, @JsonKey(name: 'phone_number')  String phoneNumber, @JsonKey(name: 'created_at', fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime createdAt, @JsonKey(name: 'is_anonymous')  bool isAnonymous,  String? username, @JsonKey(name: 'display_name')  String? displayName,  String? email, @JsonKey(name: 'photo_url')  String? photoUrl,  List<String> favorites)  $default,) {final _that = this;
switch (_that) {
case _AppUser():
return $default(_that.uid,_that.phoneNumber,_that.createdAt,_that.isAnonymous,_that.username,_that.displayName,_that.email,_that.photoUrl,_that.favorites);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid, @JsonKey(name: 'phone_number')  String phoneNumber, @JsonKey(name: 'created_at', fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime createdAt, @JsonKey(name: 'is_anonymous')  bool isAnonymous,  String? username, @JsonKey(name: 'display_name')  String? displayName,  String? email, @JsonKey(name: 'photo_url')  String? photoUrl,  List<String> favorites)?  $default,) {final _that = this;
switch (_that) {
case _AppUser() when $default != null:
return $default(_that.uid,_that.phoneNumber,_that.createdAt,_that.isAnonymous,_that.username,_that.displayName,_that.email,_that.photoUrl,_that.favorites);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppUser implements AppUser {
  const _AppUser({required this.uid, @JsonKey(name: 'phone_number') required this.phoneNumber, @JsonKey(name: 'created_at', fromJson: _timestampFromJson, toJson: _timestampToJson) required this.createdAt, @JsonKey(name: 'is_anonymous') this.isAnonymous = false, this.username, @JsonKey(name: 'display_name') this.displayName, this.email, @JsonKey(name: 'photo_url') this.photoUrl, final  List<String> favorites = const <String>[]}): _favorites = favorites;
  factory _AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);

/// Firebase Auth UID
@override final  String uid;
/// Phone number (+970 or +972 format)
@override@JsonKey(name: 'phone_number') final  String phoneNumber;
/// When the user first signed up
@override@JsonKey(name: 'created_at', fromJson: _timestampFromJson, toJson: _timestampToJson) final  DateTime createdAt;
/// Whether this is an anonymous/guest user
@override@JsonKey(name: 'is_anonymous') final  bool isAnonymous;
/// Unique username (@username)
@override final  String? username;
/// Display name (from Google Sign-In)
@override@JsonKey(name: 'display_name') final  String? displayName;
/// Email address (from Google Sign-In)
@override final  String? email;
/// Profile photo URL (from Google Sign-In)
@override@JsonKey(name: 'photo_url') final  String? photoUrl;
/// User's favorite venues (synced with Firestore)
 final  List<String> _favorites;
/// User's favorite venues (synced with Firestore)
@override@JsonKey() List<String> get favorites {
  if (_favorites is EqualUnmodifiableListView) return _favorites;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_favorites);
}


/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppUserCopyWith<_AppUser> get copyWith => __$AppUserCopyWithImpl<_AppUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppUser&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isAnonymous, isAnonymous) || other.isAnonymous == isAnonymous)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&const DeepCollectionEquality().equals(other._favorites, _favorites));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uid,phoneNumber,createdAt,isAnonymous,username,displayName,email,photoUrl,const DeepCollectionEquality().hash(_favorites));

@override
String toString() {
  return 'AppUser(uid: $uid, phoneNumber: $phoneNumber, createdAt: $createdAt, isAnonymous: $isAnonymous, username: $username, displayName: $displayName, email: $email, photoUrl: $photoUrl, favorites: $favorites)';
}


}

/// @nodoc
abstract mixin class _$AppUserCopyWith<$Res> implements $AppUserCopyWith<$Res> {
  factory _$AppUserCopyWith(_AppUser value, $Res Function(_AppUser) _then) = __$AppUserCopyWithImpl;
@override @useResult
$Res call({
 String uid,@JsonKey(name: 'phone_number') String phoneNumber,@JsonKey(name: 'created_at', fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime createdAt,@JsonKey(name: 'is_anonymous') bool isAnonymous, String? username,@JsonKey(name: 'display_name') String? displayName, String? email,@JsonKey(name: 'photo_url') String? photoUrl, List<String> favorites
});




}
/// @nodoc
class __$AppUserCopyWithImpl<$Res>
    implements _$AppUserCopyWith<$Res> {
  __$AppUserCopyWithImpl(this._self, this._then);

  final _AppUser _self;
  final $Res Function(_AppUser) _then;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? phoneNumber = null,Object? createdAt = null,Object? isAnonymous = null,Object? username = freezed,Object? displayName = freezed,Object? email = freezed,Object? photoUrl = freezed,Object? favorites = null,}) {
  return _then(_AppUser(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,isAnonymous: null == isAnonymous ? _self.isAnonymous : isAnonymous // ignore: cast_nullable_to_non_nullable
as bool,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,favorites: null == favorites ? _self._favorites : favorites // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
