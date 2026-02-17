// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppUser _$AppUserFromJson(Map<String, dynamic> json) => _AppUser(
  uid: json['uid'] as String,
  phoneNumber: json['phone_number'] as String,
  createdAt: _timestampFromJson(json['created_at']),
  isAnonymous: json['is_anonymous'] as bool? ?? false,
  username: json['username'] as String?,
  displayName: json['display_name'] as String?,
  email: json['email'] as String?,
  photoUrl: json['photo_url'] as String?,
  favorites:
      (json['favorites'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
);

Map<String, dynamic> _$AppUserToJson(_AppUser instance) => <String, dynamic>{
  'uid': instance.uid,
  'phone_number': instance.phoneNumber,
  'created_at': _timestampToJson(instance.createdAt),
  'is_anonymous': instance.isAnonymous,
  'username': instance.username,
  'display_name': instance.displayName,
  'email': instance.email,
  'photo_url': instance.photoUrl,
  'favorites': instance.favorites,
};
