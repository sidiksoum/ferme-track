import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/utils/app_logger.dart';

/// API Client for remote communication
class ApiClient {
  final Dio _dio;

  ApiClient(this._dio) {
    _dio.options = BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.connectionTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      contentType: 'application/json',
    );
  }

  /// Set authorization header
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Clear authorization header
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      AppLogger.debug('GET: $endpoint');
      final response = await _dio.get<dynamic>(
        endpoint,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<dynamic> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      AppLogger.debug('POST: $endpoint');
      final response = await _dio.post<dynamic>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<dynamic> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      AppLogger.debug('PUT: $endpoint');
      final response = await _dio.put<dynamic>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PATCH request
  Future<dynamic> patch(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      AppLogger.debug('PATCH: $endpoint');
      final response = await _dio.patch<dynamic>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<dynamic> delete(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      AppLogger.debug('DELETE: $endpoint');
      final response = await _dio.delete<dynamic>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Download file
  Future<void> downloadFile(
    String url,
    String savePath, {
    void Function(int, int)? onReceiveProgress,
  }) async {
    try {
      AppLogger.debug('DOWNLOAD: $url');
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Upload file
  Future<dynamic> uploadFile(
    String endpoint,
    String filePath, {
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      AppLogger.debug('UPLOAD: $endpoint');
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
        ...?additionalData,
      });

      final response = await _dio.post<dynamic>(
        endpoint,
        data: formData,
        onSendProgress: onSendProgress,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle successful response
  dynamic _handleResponse(Response<dynamic> response) {
    if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300) {
      throw ServerException(
        message: 'Server error',
        statusCode: response.statusCode,
        response: response.data,
      );
    }
    return response.data;
  }

  /// Handle error response
  AppException _handleError(DioException error) {
    AppLogger.error('API Error: ${error.message}', error);

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return TimeoutException(
          message: 'Connection timeout',
          stackTrace: error.stackTrace,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final response = error.response?.data;
        String message = 'Server error';
        if (response is Map<String, dynamic>) {
          final msg = response['message'];
          final err = response['error'];
          final detail = response['detail'];
          if (msg is String) {
            message = msg;
          } else if (err is String) {
            message = err;
          } else if (detail is String) {
            message = detail;
          } else if (detail != null) {
            message = detail.toString();
          }
        } else if (response is String) {
          message = response;
        }

        switch (statusCode) {
          case 400:
            return ServerException(
              message: message,
              statusCode: statusCode,
              response: response is Map<String, dynamic> ? response : null,
            );
          case 401:
            return UnauthorizedException(
              message: message,
              stackTrace: error.stackTrace,
            );
          case 403:
            return ForbiddenException(
              message: message,
              stackTrace: error.stackTrace,
            );
          case 404:
            return NotFoundException(
              message: message,
              stackTrace: error.stackTrace,
            );
          case 409:
            return ConflictException(
              message: message,
              stackTrace: error.stackTrace,
            );
          default:
            return ServerException(
              message: message,
              statusCode: statusCode,
              response: response is Map<String, dynamic> ? response : null,
            );
        }

      case DioExceptionType.connectionError:
        return NetworkException(
          message: 'Connection error',
          stackTrace: error.stackTrace,
        );

      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return SocketException(
            message: 'Socket error',
            stackTrace: error.stackTrace,
          );
        }
        return UnknownException(
          message: error.message ?? 'Unknown error',
          stackTrace: error.stackTrace,
        );

      default:
        return UnknownException(
          message: 'Unexpected error',
          stackTrace: error.stackTrace,
        );
    }
  }
}
