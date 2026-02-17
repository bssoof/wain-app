import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wain_app/features/auth/domain/entities/app_user.dart';

void main() {
  group('AppUser', () {
    group('fromJson', () {
      test('creates AppUser from complete JSON', () {
        final json = {
          'uid': 'test-uid-123',
          'phone_number': '+970599123456',
          'created_at': Timestamp.fromDate(DateTime(2026, 1, 1)),
          'is_anonymous': false,
          'username': 'testuser',
          'display_name': 'Test User',
          'email': 'test@example.com',
          'photo_url': 'https://example.com/photo.jpg',
          'favorites': ['venue1', 'venue2'],
        };

        final user = AppUser.fromJson(json);

        expect(user.uid, 'test-uid-123');
        expect(user.phoneNumber, '+970599123456');
        expect(user.createdAt, DateTime(2026, 1, 1));
        expect(user.isAnonymous, false);
        expect(user.username, 'testuser');
        expect(user.displayName, 'Test User');
        expect(user.email, 'test@example.com');
        expect(user.photoUrl, 'https://example.com/photo.jpg');
        expect(user.favorites, ['venue1', 'venue2']);
      });

      test('handles missing optional fields', () {
        final json = {
          'uid': 'test-uid-456',
          'phone_number': '+972501234567',
          'created_at': Timestamp.fromDate(DateTime(2026, 2, 1)),
        };

        final user = AppUser.fromJson(json);

        expect(user.uid, 'test-uid-456');
        expect(user.phoneNumber, '+972501234567');
        expect(user.isAnonymous, false); // default
        expect(user.username, isNull);
        expect(user.displayName, isNull);
        expect(user.email, isNull);
        expect(user.photoUrl, isNull);
        expect(user.favorites, isEmpty); // default empty list
      });

      test('parses String date in created_at', () {
        final json = {
          'uid': 'uid-str-date',
          'phone_number': '',
          'created_at': '2026-03-15T10:30:00.000',
        };

        final user = AppUser.fromJson(json);

        expect(user.createdAt.year, 2026);
        expect(user.createdAt.month, 3);
        expect(user.createdAt.day, 15);
      });
    });

    group('guest factory', () {
      test('creates anonymous user with empty phone', () {
        final guest = AppUser.guest('anon-uid');

        expect(guest.uid, 'anon-uid');
        expect(guest.phoneNumber, '');
        expect(guest.isAnonymous, true);
        expect(guest.username, isNull);
        expect(guest.displayName, isNull);
        expect(guest.email, isNull);
        expect(guest.favorites, isEmpty);
      });
    });

    group('toJson', () {
      test('serializes AppUser to JSON', () {
        final user = AppUser(
          uid: 'uid-json',
          phoneNumber: '+970599000000',
          createdAt: DateTime(2026, 6, 1),
          isAnonymous: false,
          username: 'jsonuser',
        );

        final json = user.toJson();

        expect(json['uid'], 'uid-json');
        expect(json['phone_number'], '+970599000000');
        expect(json['is_anonymous'], false);
        expect(json['username'], 'jsonuser');
        expect(json['created_at'], isA<Timestamp>());
      });
    });

    group('equality', () {
      test('two AppUsers with same data are equal (freezed)', () {
        final dateTime = DateTime(2026, 1, 1);
        final user1 = AppUser(
          uid: 'same-uid',
          phoneNumber: '+970599999999',
          createdAt: dateTime,
        );
        final user2 = AppUser(
          uid: 'same-uid',
          phoneNumber: '+970599999999',
          createdAt: dateTime,
        );

        expect(user1, equals(user2));
      });

      test('two AppUsers with different UIDs are not equal', () {
        final dateTime = DateTime(2026, 1, 1);
        final user1 = AppUser(
          uid: 'uid-a',
          phoneNumber: '+970599999999',
          createdAt: dateTime,
        );
        final user2 = AppUser(
          uid: 'uid-b',
          phoneNumber: '+970599999999',
          createdAt: dateTime,
        );

        expect(user1, isNot(equals(user2)));
      });
    });

    group('copyWith', () {
      test('creates a copy with updated fields', () {
        final user = AppUser(
          uid: 'copy-uid',
          phoneNumber: '+970599111111',
          createdAt: DateTime(2026, 1, 1),
          username: 'old_name',
        );

        final updated = user.copyWith(username: 'new_name');

        expect(updated.uid, 'copy-uid');
        expect(updated.username, 'new_name');
        expect(updated.phoneNumber, '+970599111111');
      });
    });
  });
}
