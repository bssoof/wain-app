/// App Exception Classes
/// Unified error handling for the entire app
library;

sealed class AppException implements Exception {
  const AppException();

  String get userMessage;
  String get technicalMessage;
  bool get isRetryable;
}

/// Network-related errors
class NetworkException extends AppException {
  final String? details;
  const NetworkException([this.details]);

  @override
  String get userMessage => 'تحقق من اتصالك بالإنترنت';

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
  String get userMessage => 'في مشكلة من السيرفر، حاول مرة ثانية';

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
  String get userMessage => 'لا توجد نتائج مطابقة، جرّب تعديل الفلاتر';

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
  String get userMessage => 'المكان غير موجود أو تم حذفه';

  @override
  String get technicalMessage => 'Venue not found: $venueId';

  @override
  bool get isRetryable => false;
}

/// Location permission denied
class LocationPermissionException extends AppException {
  const LocationPermissionException();

  @override
  String get userMessage => 'فعّل الموقع للحصول على نتائج أدق';

  @override
  String get technicalMessage => 'Location permission denied';

  @override
  bool get isRetryable => false;
}

/// Auth errors
class AuthException extends AppException {
  final String code;
  const AuthException(this.code);

  @override
  String get userMessage {
    return switch (code) {
      'invalid-verification-code' => 'رمز التحقق غير صحيح',
      'session-expired' => 'انتهت صلاحية الرمز، اطلب رمزًا جديدًا',
      'too-many-requests' => 'عدد المحاولات كبير، حاول لاحقًا',
      'invalid-phone-number' => 'رقم الهاتف غير صحيح',
      _ => 'حدث خطأ في التحقق',
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
  String get userMessage => 'تعذر قراءة البيانات المحلية';

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
  String get userMessage => 'فشل إرسال التقييم، حاول مرة ثانية';

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
  String get userMessage => 'فشل تنفيذ العملية على العرض، حاول مرة ثانية';

  @override
  String get technicalMessage => 'Offer error: ${details ?? "unknown"}';

  @override
  bool get isRetryable => true;
}

/// Timeout (slow network, not fully disconnected)
class AppTimeoutException extends AppException {
  const AppTimeoutException();

  @override
  String get userMessage => 'انتهت مهلة الاتصال، حاول مرة ثانية';

  @override
  String get technicalMessage => 'Request timed out';

  @override
  bool get isRetryable => true;
}
