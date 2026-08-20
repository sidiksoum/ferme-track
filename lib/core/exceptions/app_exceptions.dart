/// Base Exception
abstract class AppException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  AppException({required this.message, this.stackTrace});

  @override
  String toString() => message;
}

/// Network Exceptions
class NetworkException extends AppException {
  NetworkException({
    required super.message,
    super.stackTrace,
  });
}

class SocketException extends AppException {
  SocketException({
    required super.message,
    super.stackTrace,
  });
}

class TimeoutException extends AppException {
  TimeoutException({
    required super.message,
    super.stackTrace,
  });
}

/// Server Exceptions
class ServerException extends AppException {
  final int? statusCode;
  final Map<String, dynamic>? response;

  ServerException({
    required super.message,
    this.statusCode,
    this.response,
    super.stackTrace,
  });
}

class UnauthorizedException extends AppException {
  UnauthorizedException({
    required super.message,
    super.stackTrace,
  });
}

class ForbiddenException extends AppException {
  ForbiddenException({
    required super.message,
    super.stackTrace,
  });
}

class NotFoundException extends AppException {
  NotFoundException({
    required super.message,
    super.stackTrace,
  });
}

class ConflictException extends AppException {
  ConflictException({
    required super.message,
    super.stackTrace,
  });
}

/// Local Storage Exceptions
class CacheException extends AppException {
  CacheException({
    required super.message,
    super.stackTrace,
  });
}

class DatabaseException extends AppException {
  DatabaseException({
    required super.message,
    super.stackTrace,
  });
}

/// Authentication Exceptions
class AuthenticationException extends AppException {
  AuthenticationException({
    required super.message,
    super.stackTrace,
  });
}

class SessionExpiredException extends AppException {
  SessionExpiredException({
    super.stackTrace,
  }) : super(message: 'Session expired');
}

/// Validation Exceptions
class ValidationException extends AppException {
  final Map<String, String>? errors;

  ValidationException({
    required super.message,
    this.errors,
    super.stackTrace,
  });
}

/// Business Logic Exceptions
class BusinessException extends AppException {
  final String code;

  BusinessException({
    required super.message,
    this.code = 'UNKNOWN',
    super.stackTrace,
  });
}

class InsufficientStockException extends BusinessException {
  InsufficientStockException({
    required super.message,
    super.stackTrace,
  }) : super(code: 'INSUFFICIENT_STOCK');
}

class CreditLimitExceededException extends BusinessException {
  CreditLimitExceededException({
    required super.message,
    super.stackTrace,
  }) : super(code: 'CREDIT_LIMIT_EXCEEDED');
}

class DuplicateException extends BusinessException {
  DuplicateException({
    required super.message,
    super.stackTrace,
  }) : super(code: 'DUPLICATE');
}

/// Offline Mode Exception
class OfflineException extends AppException {
  OfflineException({
    required super.message,
    super.stackTrace,
  });
}

/// File Exceptions
class FileException extends AppException {
  FileException({
    required super.message,
    super.stackTrace,
  });
}

class FileTooBigException extends FileException {
  FileTooBigException({
    super.stackTrace,
  }) : super(message: 'File is too large');
}

class InvalidFileException extends FileException {
  InvalidFileException({
    required super.message,
    super.stackTrace,
  });
}

/// Unknown Exception
class UnknownException extends AppException {
  UnknownException({
    required super.message,
    super.stackTrace,
  });
}
