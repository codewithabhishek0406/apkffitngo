/// A simple Result type for repository methods.
/// Avoids throwing exceptions across async boundaries.
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

final class Failure<T> extends Result<T> {
  const Failure(this.message, {this.error});
  final String message;
  final Object? error;
}

extension ResultExtensions<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => switch (this) {
        Success<T> s => s.data,
        Failure<T> _ => null,
      };

  String? get errorMessage => switch (this) {
        Success<T> _ => null,
        Failure<T> f => f.message,
      };

  R when<R>({
    required R Function(T data) success,
    required R Function(String message, Object? error) failure,
  }) =>
      switch (this) {
        Success<T> s => success(s.data),
        Failure<T> f => failure(f.message, f.error),
      };
}
