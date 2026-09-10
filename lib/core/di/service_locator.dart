import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../../data/datasources/local/cache_manager.dart';
import '../../../data/datasources/local/local_storage.dart';
import '../../../data/datasources/remote/api_client.dart';
import '../../../data/repositories/authentication_repository_impl.dart';
import '../../../data/repositories/user_repository_impl.dart';
import '../../../domain/repositories/authentication_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import '../interfaces/network_checker.dart';
import '../services/offline_sync_service.dart';
import '../services/socket_client_service.dart';

final getIt = GetIt.instance;

/// Service Locator Setup
/// Organizes dependency injection for the entire application
class ServiceLocator {
  static Future<void> init() async {
    // External packages
    _setupExternalDependencies();

    // Data sources & Cache
    await _setupDataSources();

    // Repositories
    _setupRepositories();

    // Core Services (Sync & WebSockets)
    await _setupCoreServices();

    // Use cases
    _setupUseCases();

    // Bloc/Providers
    _setupBlocProviders();
  }

  /// Setup external dependencies (plugins)
  static void _setupExternalDependencies() {
    // Real network connectivity checker
    getIt.registerSingleton<NetworkChecker>(
      NetworkCheckerImpl(),
    );

    // Secure storage
    getIt.registerSingleton<FlutterSecureStorage>(
      const FlutterSecureStorage(),
    );

    // HTTP Client (Dio)
    getIt.registerSingleton<Dio>(
      Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      )..interceptors.add(LoggingInterceptor()),
    );
  }

  /// Setup data sources
  static Future<void> _setupDataSources() async {
    // Cache Manager
    final cacheManager = CacheManager();
    await cacheManager.init();
    getIt.registerSingleton<CacheManager>(cacheManager);

    // Local secure storage
    getIt.registerSingleton<LocalStorage>(
      LocalStorageImpl(getIt<FlutterSecureStorage>()),
    );

    // API Client with Cache integration
    getIt.registerSingleton<ApiClient>(
      ApiClient(getIt<Dio>(), getIt<CacheManager>()),
    );
  }

  /// Setup repositories
  static void _setupRepositories() {
    // Authentication repository
    getIt.registerSingleton<AuthenticationRepository>(
      AuthenticationRepositoryImpl(
        apiClient: getIt.get<ApiClient>(),
        localStorage: getIt.get<LocalStorage>(),
        networkChecker: getIt.get<NetworkChecker>(),
      ),
    );

    // User repository
    getIt.registerSingleton<UserRepository>(
      UserRepositoryImpl(
        apiClient: getIt.get<ApiClient>(),
        networkChecker: getIt.get<NetworkChecker>(),
      ),
    );
  }

  /// Setup core services (Offline Sync Engine & Real-time Socket.IO)
  static Future<void> _setupCoreServices() async {
    // Offline Sync Service
    final offlineSyncService = OfflineSyncService(
      apiClient: getIt<ApiClient>(),
      networkChecker: getIt<NetworkChecker>(),
      cacheManager: getIt<CacheManager>(),
    );
    await offlineSyncService.init();
    getIt.registerSingleton<OfflineSyncService>(offlineSyncService);

    // Real-time Socket.IO Service
    final socketClientService = SocketClientService(
      cacheManager: getIt<CacheManager>(),
      networkChecker: getIt<NetworkChecker>(),
    );
    getIt.registerSingleton<SocketClientService>(socketClientService);
  }

  /// Setup use cases
  static void _setupUseCases() {}

  /// Setup Bloc/Providers
  static void _setupBlocProviders() {}
}

/// Logging Interceptor for Dio
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('REQUEST[${options.method}] => PATH: ${options.path}');
    if (options.data != null) {
      print('REQUEST DATA: ${options.data}');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
    if (response.data != null) {
      print('RESPONSE DATA: ${response.data}');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
    super.onError(err, handler);
  }
}
