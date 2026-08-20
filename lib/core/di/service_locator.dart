import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../interfaces/network_checker.dart';
import '../../../data/datasources/local/local_storage.dart';
import '../../../data/datasources/remote/api_client.dart';
import '../../../data/repositories/authentication_repository_impl.dart';
import '../../../domain/repositories/authentication_repository.dart';

final getIt = GetIt.instance;

/// Service Locator Setup
/// Organizes dependency injection for the entire application
class ServiceLocator {
  static Future<void> init() async {
    // External packages
    _setupExternalDependencies();

    // Core
    _setupCoreDependencies();

    // Data sources
    _setupDataSources();

    // Repositories
    _setupRepositories();

    // Use cases
    _setupUseCases();

    // Bloc/Providers
    _setupBlocProviders();
  }

  /// Setup external dependencies (plugins)
  static void _setupExternalDependencies() {
    // Network connectivity checker - use NetworkCheckerStub for now
    getIt.registerSingleton<NetworkChecker>(
      NetworkCheckerStub(),
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

  /// Setup core dependencies (utilities, helpers)
  static void _setupCoreDependencies() {
    // Add your core utilities here
  }

  /// Setup data sources
  static void _setupDataSources() {
    // Local storage
    getIt.registerSingleton<LocalStorage>(
      LocalStorageImpl(getIt<FlutterSecureStorage>()),
    );

    // API Client
    getIt.registerSingleton<ApiClient>(
      ApiClient(getIt<Dio>()),
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
  }

  /// Setup use cases
  static void _setupUseCases() {
    // Add use cases here as needed
  }

  /// Setup Bloc/Providers
  static void _setupBlocProviders() {
    // Add bloc/providers here as needed
  }
}

/// Logging Interceptor for Dio
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('REQUEST[${options.method}] => PATH: ${options.path}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
    super.onError(err, handler);
  }
}
