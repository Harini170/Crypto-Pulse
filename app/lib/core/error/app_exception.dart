enum ErrorKind { network, timeout, server, parse, unknown }

/// The only exception type that leaves the data layer.
class AppException implements Exception {
  const AppException(this.message, [this.kind = ErrorKind.unknown]);

  final String message;
  final ErrorKind kind;

  @override
  String toString() => 'AppException($kind): $message';
}
