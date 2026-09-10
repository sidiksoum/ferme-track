import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/utils/app_logger.dart';
import '../local/cache_manager.dart';

/// API Client for remote communication with intelligent local caching and offline fallback
class ApiClient {
  final Dio _dio;
  final CacheManager? _cacheManager;

  ApiClient(this._dio, [this._cacheManager]) {
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

  /// GET request avec support du cache local (Cache-First avec rafraîchissement ou Network-First)
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool useCache = true,
    Duration cacheTtl = const Duration(hours: 12),
    bool forceRefresh = false,
  }) async {
    final cacheKey = CacheManager.makeKey(endpoint, queryParameters);

    // 1. Si le cache est demandé et qu'on ne force pas le rafraîchissement, vérifier le cache local
    if (useCache && !forceRefresh && _cacheManager != null) {
      final cachedData = _cacheManager.getCachedResponse(cacheKey);
      if (cachedData != null) {
        AppLogger.debug('⚡ [CACHE HIT] $cacheKey');

        // Déclencher un rafraîchissement silencieux en arrière-plan (Stale-While-Revalidate)
        unawaited(_fetchAndCacheInBackground(endpoint, queryParameters, options, cacheKey, cacheTtl));

        return cachedData;
      }
    }

    // 2. Appel réseau direct
    try {
      AppLogger.debug('🌐 [NETWORK GET] $endpoint');
      final response = await _dio.get<dynamic>(
        endpoint,
        queryParameters: queryParameters,
        options: options,
      );
      final data = _handleResponse(response);

      // Mettre en cache la nouvelle réponse
      if (useCache && _cacheManager != null) {
        await _cacheManager.cacheResponse(cacheKey, data, ttl: cacheTtl);
      }

      return data;
    } on DioException catch (e) {
      // 3. En cas d'échec réseau, tenter un fallback sur le cache même expiré (mode dégradé hors-ligne)
      if (useCache && _cacheManager != null) {
        final fallbackData = _cacheManager.getCachedResponse(cacheKey, ignoreExpiration: true);
        if (fallbackData != null) {
          AppLogger.warning('📴 [OFFLINE FALLBACK CACHE] Réponse servie depuis le cache pour: $cacheKey');
          return fallbackData;
        }
      }
      throw _handleError(e);
    } catch (e) {
      if (useCache && _cacheManager != null) {
        final fallbackData = _cacheManager.getCachedResponse(cacheKey, ignoreExpiration: true);
        if (fallbackData != null) return fallbackData;
      }
      rethrow;
    }
  }

  Future<void> _fetchAndCacheInBackground(
    String endpoint,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String cacheKey,
    Duration cacheTtl,
  ) async {
    try {
      final response = await _dio.get<dynamic>(
        endpoint,
        queryParameters: queryParameters,
        options: options,
      );
      final data = _handleResponse(response);
      await _cacheManager?.cacheResponse(cacheKey, data, ttl: cacheTtl);
    } catch (_) {
      // Ignorer silencieusement les erreurs de rafraîchissement d'arrière-plan
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
