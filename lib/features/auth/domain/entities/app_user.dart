// ignore_for_file: invalid_annotation_target
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

/// Represents an authenticated user in the app
@freezed
sealed class AppUser with _$AppUser {
  const factory AppUser({
    /// Firebase Auth UID
    required String uid,

    /// Phone number (+970 or +972 format)
    @JsonKey(name: 'phone_number') required String phoneNumber,

    /// When the user first signed up
    @JsonKey(
      name: 'created_at',
      fromJson: _timestampFromJson,
      toJson: _timestampToJson,
    )
    required DateTime createdAt,

    /// Whether this is an anonymous/guest user
    @JsonKey(name: 'is_anonymous') @Default(false) bool isAnonymous,

    /// Unique username (@username)
    String? username,

    /// Display name (from Google Sign-In)
    @JsonKey(name: 'display_name') String? displayName,

    /// Email address (from Google Sign-In)
    String? email,

    /// Profile photo URL (from Google Sign-In)
    @JsonKey(name: 'photo_url') String? photoUrl,

    /// User's favorite venues (synced with Firestore)
    @Default(<String>[]) List<String> favorites,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return AppUser.fromJson({...data, 'uid': doc.id});
  }

  /// Create a guest user
  factory AppUser.guest(String uid) => AppUser(
    uid: uid,
    phoneNumber: '',
    createdAt: DateTime.now(),
    isAnonymous: true,
  );
}

// Helper functions for Timestamp conversion
DateTime _timestampFromJson(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.parse(value);
  return DateTime.now();
}

dynamic _timestampToJson(DateTime date) => Timestamp.fromDate(date);
