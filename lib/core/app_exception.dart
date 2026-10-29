/// Error with a message that is safe to show to the user.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Converts any error into a user-friendly message.
String errorMessage(Object error) {
  return error is AppException
      ? error.message
      : 'Something went wrong. Please try again.';
}
