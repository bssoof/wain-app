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
  String get technicalMessage => 'Network error: ${details ?? "connection failed"}';
  
  @override
  bool get isRetryable => true;
}

/// Server-side errors (5xx)
/// Server-side errors (5xx)
class ServerException extends AppException {
  final int? statusCode;
  final String? message;
  const ServerException({this.statusCode, this.message});
  
  @override
  String get userMessage => 'في مشكلة عنا، جاري الإصلاح';
  
  @override
  String get technicalMessage => 'Server error: ${message != null ? "$message ($statusCode)" : statusCode ?? "unknown"}';
  
  @override
  bool get isRetryable => true;
}

/// No results found
class NoResultsException extends AppException {
  const NoResultsException();
  
  @override
  String get userMessage => 'ما لقينا نتائج، جرب تخفف الفلاتر';
  
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
  String get userMessage => 'المكان مش موجود أو اتحذف';
  
  @override
  String get technicalMessage => 'Venue not found: $venueId';
  
  @override
  bool get isRetryable => false;
}

/// Location permission denied
class LocationPermissionException extends AppException {
  const LocationPermissionException();
  
  @override
  String get userMessage => 'فعّل الموقع لنتائج أدق';
  
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
      'invalid-verification-code' => 'الرمز غلط، حاول مرة ثانية',
      'session-expired' => 'انتهت صلاحية الرمز، طلبنا رمز جديد',
      'too-many-requests' => 'حاولت كثير، انتظر شوية',
      'invalid-phone-number' => 'رقم الهاتف مش صحيح',
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
  String get userMessage => 'أنت على بيانات محفوظة';
  
  @override
  String get technicalMessage => 'Local cache read/write error';
  
  @override
  bool get isRetryable => false;
}
