/// Result type for operations that can fail
/// Use this instead of try-catch for expected errors
library;

sealed class Result<T> {
  const Result();

  /// Check if success
  bool get isSuccess => this is Success<T>;

  /// Check if failure
  bool get isFailure => this is Failure<T>;

  /// Get data or null
  T? get dataOrNull => switch (this) {
    Success(:final data) => data,
    Failure() => null,
  };

  /// Map success value
  Result<R> map<R>(R Function(T data) mapper) {
    return switch (this) {
      Success(:final data) => Success(mapper(data)),
      Failure(:final error) => Failure(error),
    };
  }

  /// Handle both cases
  R when<R>({
    required R Function(T data) success,
    required R Function(Exception error) failure,
  }) {
    return switch (this) {
      Success(:final data) => success(data),
      Failure(:final error) => failure(error),
    };
  }
}

/// Successful result
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

/// Failed result
class Failure<T> extends Result<T> {
  final Exception error;
  const Failure(this.error);
}
