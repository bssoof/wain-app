/// App Exception Classes
/// Unified error handling for the entire app
library;

import 'package:wain_app/l10n/app_localizations.dart';

sealed class AppException implements Exception {
  const AppException();

  /// Fallback English message (used when l10n unavailable)
  String get userMessage;
  String get technicalMessage;
  bool get isRetryable;

  /// Get localized user message using AppLocalizations.
  /// Call this from the UI layer where l10n is available.
  String localizedMessage(AppLocalizations l10n) {
    return switch (this) {
      NetworkException() => l10n.errNetwork,
      ServerException() => l10n.errServer,
      NoResultsException() => l10n.errNoResults,
      VenueNotFoundException() => l10n.errVenueNotFound,
      LocationPermissionException() => l10n.errLocationPermission,
      AppAuthException(code: final c) => switch (c) {
          'invalid-verification-code' => l10n.errAuthInvalidCode,
          'session-expired' => l10n.errAuthSessionExpired,
          'too-many-requests' => l10n.errAuthTooMany,
          'invalid-phone-number' => l10n.errAuthInvalidPhone,
          _ => l10n.errAuthGeneric,
        },
      CacheException() => l10n.errCache,
      ReviewException() => l10n.errReview,
      OfferException() => l10n.errOffer,
      AppTimeoutException() => l10n.errTimeout,
    };
  }
}

/// Network-related errors
class NetworkException extends AppException {
  final String? details;
  const NetworkException([this.details]);

  @override
  String get userMessage => 'Check your internet connection';

  @override
  String get technicalMessage =>
      'Network error: ${details ?? "connection failed"}';

  @override
  bool get isRetryable => true;
}

/// Server-side errors (5xx)
class ServerException extends AppException {
  final int? statusCode;
  final String? message;
  const ServerException({this.statusCode, this.message});

  @override
  String get userMessage => 'Server issue, try again';

  @override
  String get technicalMessage =>
      'Server error: ${message != null ? "$message ($statusCode)" : statusCode ?? "unknown"}';

  @override
  bool get isRetryable => true;
}

/// No results found
class NoResultsException extends AppException {
  const NoResultsException();

  @override
  String get userMessage => 'No matching results, try adjusting filters';

  @override
  String get technicalMessage => 'No results found for query';

  @override
  bool get isRetryable => false;
}

/// Venue not found
class VenueNotFoundException extends AppException {
  final String venueId;
  const VenueNotFoundException(this.venueId);

  @override
  String get userMessage => 'Venue not found or deleted';

  @override
  String get technicalMessage => 'Venue not found: $venueId';

  @override
  bool get isRetryable => false;
}

/// Location permission denied
class LocationPermissionException extends AppException {
  const LocationPermissionException();

  @override
  String get userMessage => 'Enable location for better results';

  @override
  String get technicalMessage => 'Location permission denied';

  @override
  bool get isRetryable => false;
}

/// Auth errors (renamed to avoid clash with auth_repository_impl.dart AuthException)
class AppAuthException extends AppException {
  final String code;
  const AppAuthException(this.code);

  @override
  String get userMessage {
    return switch (code) {
      'invalid-verification-code' => 'Invalid verification code',
      'session-expired' => 'Code expired, request a new one',
      'too-many-requests' => 'Too many attempts, try later',
      'invalid-phone-number' => 'Invalid phone number',
      _ => 'Verification error occurred',
    };
  }

  @override
  String get technicalMessage => 'Auth error: $code';

  @override
  bool get isRetryable => code == 'session-expired';
}

/// Generic cache error
class CacheException extends AppException {
  const CacheException();

  @override
  String get userMessage => 'Could not read local data';

  @override
  String get technicalMessage => 'Local cache read/write error';

  @override
  bool get isRetryable => false;
}

/// Review-related errors
class ReviewException extends AppException {
  final String? details;
  const ReviewException([this.details]);

  @override
  String get userMessage => 'Review submission failed, try again';

  @override
  String get technicalMessage => 'Review error: ${details ?? "unknown"}';

  @override
  bool get isRetryable => true;
}

/// Offer claim/save errors
class OfferException extends AppException {
  final String? details;
  const OfferException([this.details]);

  @override
  String get userMessage => 'Offer action failed, try again';

  @override
  String get technicalMessage => 'Offer error: ${details ?? "unknown"}';

  @override
  bool get isRetryable => true;
}

/// Timeout (slow network, not fully disconnected)
class AppTimeoutException extends AppException {
  const AppTimeoutException();

  @override
  String get userMessage => 'Connection timed out, try again';

  @override
  String get technicalMessage => 'Request timed out';

  @override
  bool get isRetryable => true;
}
