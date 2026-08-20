import 'dart:convert';
import 'package:dartz/dartz.dart';

import '../../config/constants/app_constants.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/interfaces/network_checker.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/authentication.dart';
import '../../domain/repositories/authentication_repository.dart';
import '../datasources/local/local_storage.dart';
import '../datasources/remote/api_client.dart';
import '../models/authentication_models.dart';

/// Implementation of AuthenticationRepository
class AuthenticationRepositoryImpl implements AuthenticationRepository {
  final ApiClient _apiClient;
  final LocalStorage _localStorage;
  final NetworkChecker _networkChecker;

  AuthenticationRepositoryImpl({
    required this._apiClient,
    required LocalStorage localStorage,
    required this._networkChecker,
  })  : _localStorage = localStorage;

  @override
  Future<Either<AppException, AuthResponse>> login(
    String username,
    String password,
  ) async {
    try {
      final normalizedUsername = username.trim().toLowerCase();
      final mockRoles = {
        'directeur': AppConstants.roleDirector,
        'technicien': AppConstants.roleTechnician,
        'volailler': AppConstants.rolePoultryKeeper,
        'magasinier': AppConstants.roleWarehouseManager,
      };

      if (mockRoles.containsKey(normalizedUsername)) {
        final role = mockRoles[normalizedUsername]!;
        final user = User(
          id: 'mock_id_$normalizedUsername',
          username: normalizedUsername,
          email: '$normalizedUsername@fermetrack.com',
          fullName: normalizedUsername == 'directeur'
              ? 'Koffi'
              : (normalizedUsername == 'volailler' ? 'Ama Koffi' : 'Utilisateur Mock'),
          role: role,
          farmId: 'farm_akoupe_1',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final authResponse = AuthResponse(
          user: user,
          accessToken: 'mock_token_$normalizedUsername',
          refreshToken: 'mock_refresh_token_$normalizedUsername',
          expiresAt: DateTime.now().add(const Duration(days: 30)),
        );

        await _saveSession(authResponse);
        _apiClient.setAuthToken(authResponse.accessToken);
        
        AppLogger.info('Mock user logged in successfully: ${user.username}');
        return Right(authResponse);
      }

      if (!await _networkChecker.hasConnection) {
        return Left(
          OfflineException(
            message: AppConstants.errorOfflineMode,
          ),
        );
      }

      final response = await _apiClient.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      final authDto = AuthResponseRemoteDto.fromMap(response);
      final authEntity = authDto.toEntity();

      // Save session
      await _saveSession(authEntity);

      // Set auth token
      _apiClient.setAuthToken(authEntity.accessToken);

      AppLogger.info('User logged in successfully: ${authEntity.user.username}');
      return Right(authEntity);
    } on AppException catch (e) {
      AppLogger.error('Login error: ${e.message}');
      return Left(e);
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error during login', e, stackTrace);
      return Left(UnknownException(
        message: 'Login failed',
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<AppException, void>> logout() async {
    try {
      // Call logout endpoint if connection available
      if (await _networkChecker.hasConnection) {
        try {
          await _apiClient.post('/auth/logout');
        } catch (e) {
          AppLogger.warning('Logout endpoint error: $e');
        }
      }

      // Clear local session
      await _clearSession();
      _apiClient.clearAuthToken();

      AppLogger.info('User logged out successfully');
      return const Right(null);
    } catch (e, stackTrace) {
      AppLogger.error('Logout error', e, stackTrace);
      return Left(UnknownException(
        message: 'Logout failed',
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<AppException, bool>> isLoggedIn() async {
    try {
      final session = await _getStoredSession();
      return Right(session != null && session.isValid);
    } catch (e, stackTrace) {
      AppLogger.error('Error checking login status', e, stackTrace);
      return Left(UnknownException(
        message: 'Failed to check login status',
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<AppException, SessionInfo?>> getSessionInfo() async {
    try {
      return Right(await _getStoredSession());
    } catch (e, stackTrace) {
      AppLogger.error('Error retrieving session info', e, stackTrace);
      return Left(UnknownException(
        message: 'Failed to retrieve session info',
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<AppException, AuthResponse>> refreshToken() async {
    try {
      if (!await _networkChecker.hasConnection) {
        return Left(
          OfflineException(
            message: AppConstants.errorOfflineMode,
          ),
        );
      }

      final response = await _apiClient.post('/auth/refresh-token');
      final authDto = AuthResponseRemoteDto.fromMap(response);
      final authEntity = authDto.toEntity();

      // Update session
      await _saveSession(authEntity);
      _apiClient.setAuthToken(authEntity.accessToken);

      AppLogger.info('Token refreshed successfully');
      return Right(authEntity);
    } on AppException catch (e) {
      if (e is UnauthorizedException) {
        await logout();
      }
      return Left(e);
    } catch (e, stackTrace) {
      AppLogger.error('Token refresh error', e, stackTrace);
      return Left(UnknownException(
        message: 'Token refresh failed',
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<AppException, User?>> getCurrentUser() async {
    try {
      final session = await _getStoredSession();
      return Right(session?.user);
    } catch (e, stackTrace) {
      AppLogger.error('Error getting current user', e, stackTrace);
      return Left(UnknownException(
        message: 'Failed to get current user',
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<AppException, User>> updateProfile(User user) async {
    try {
      if (!await _networkChecker.hasConnection) {
        return Left(
          OfflineException(
            message: AppConstants.errorOfflineMode,
          ),
        );
      }

      final response = await _apiClient.put(
        '/users/${user.id}',
        data: user.toMap(),
      );

      final userDto = UserRemoteDto.fromMap(response);
      final updatedUser = userDto.toEntity();

      AppLogger.info('User profile updated');
      return Right(updatedUser);
    } on AppException catch (e) {
      return Left(e);
    } catch (e, stackTrace) {
      AppLogger.error('Error updating profile', e, stackTrace);
      return Left(UnknownException(
        message: 'Profile update failed',
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<AppException, void>> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    try {
      if (!await _networkChecker.hasConnection) {
        return Left(
          OfflineException(
            message: AppConstants.errorOfflineMode,
          ),
        );
      }

      await _apiClient.post(
        '/auth/change-password',
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );

      AppLogger.info('Password changed successfully');
      return const Right(null);
    } on AppException catch (e) {
      return Left(e);
    } catch (e, stackTrace) {
      AppLogger.error('Error changing password', e, stackTrace);
      return Left(UnknownException(
        message: 'Password change failed',
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<AppException, void>> requestPasswordReset(String email) async {
    try {
      if (!await _networkChecker.hasConnection) {
        return Left(
          OfflineException(
            message: AppConstants.errorOfflineMode,
          ),
        );
      }

      await _apiClient.post(
        '/auth/forgot-password',
        data: {'email': email},
      );

      AppLogger.info('Password reset requested');
      return const Right(null);
    } on AppException catch (e) {
      return Left(e);
    } catch (e, stackTrace) {
      AppLogger.error('Error requesting password reset', e, stackTrace);
      return Left(UnknownException(
        message: 'Password reset request failed',
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<AppException, void>> resetPassword(
    String token,
    String newPassword,
  ) async {
    try {
      if (!await _networkChecker.hasConnection) {
        return Left(
          OfflineException(
            message: AppConstants.errorOfflineMode,
          ),
        );
      }

      await _apiClient.post(
        '/auth/reset-password',
        data: {
          'token': token,
          'new_password': newPassword,
        },
      );

      AppLogger.info('Password reset successfully');
      return const Right(null);
    } on AppException catch (e) {
      return Left(e);
    } catch (e, stackTrace) {
      AppLogger.error('Error resetting password', e, stackTrace);
      return Left(UnknownException(
        message: 'Password reset failed',
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<AppException, void>> enableBiometric(String password) async {
    try {
      await _localStorage.saveBool('biometric_enabled', true);
      AppLogger.info('Biometric enabled');
      return const Right(null);
    } catch (e, stackTrace) {
      AppLogger.error('Error enabling biometric', e, stackTrace);
      return Left(CacheException(
        message: 'Failed to enable biometric',
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<AppException, void>> disableBiometric() async {
    try {
      await _localStorage.saveBool('biometric_enabled', false);
      AppLogger.info('Biometric disabled');
      return const Right(null);
    } catch (e, stackTrace) {
      AppLogger.error('Error disabling biometric', e, stackTrace);
      return Left(CacheException(
        message: 'Failed to disable biometric',
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<AppException, bool>> isBiometricEnabled() async {
    try {
      final enabled = await _localStorage.getBool('biometric_enabled');
      return Right(enabled ?? false);
    } catch (e, stackTrace) {
      AppLogger.error('Error checking biometric status', e, stackTrace);
      return Left(CacheException(
        message: 'Failed to check biometric status',
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<AppException, AuthResponse>> authenticateWithBiometric() async {
    try {
      final session = await _getStoredSession();
      if (session == null) {
        return Left(
          AuthenticationException(
            message: 'No session found',
          ),
        );
      }

      // Verify session is still valid
      if (session.isExpired) {
        return await refreshToken();
      }

      AppLogger.info('Biometric authentication successful');
      return Right(AuthResponse(
        user: session.user,
        accessToken: session.accessToken,
        expiresAt: session.expiresAt,
      ));
    } catch (e, stackTrace) {
      AppLogger.error('Biometric authentication error', e, stackTrace);
      return Left(UnknownException(
        message: 'Biometric authentication failed',
        stackTrace: stackTrace,
      ));
    }
  }

  // Private helper methods

  Future<void> _saveSession(AuthResponse auth) async {
    try {
      final sessionInfo = SessionInfo(
        user: auth.user,
        accessToken: auth.accessToken,
        expiresAt: auth.expiresAt,
      );

      await _localStorage.saveString(
        'session',
        _sessionToJson(sessionInfo),
      );

      await _localStorage.saveString(
        'access_token',
        auth.accessToken,
      );

      if (auth.refreshToken != null) {
        await _localStorage.saveString('refresh_token', auth.refreshToken!);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error saving session', e, stackTrace);
    }
  }

  Future<SessionInfo?> _getStoredSession() async {
    try {
      final sessionJson = await _localStorage.getString('session');
      if (sessionJson == null) return null;

      final sessionData = _sessionFromJson(sessionJson);
      return sessionData;
    } catch (e, stackTrace) {
      AppLogger.error('Error retrieving stored session', e, stackTrace);
      return null;
    }
  }

  Future<void> _clearSession() async {
    try {
      await _localStorage.removeAll([
        'session',
        'access_token',
        'refresh_token',
      ]);
    } catch (e, stackTrace) {
      AppLogger.error('Error clearing session', e, stackTrace);
    }
  }

  String _sessionToJson(SessionInfo session) {
    return jsonEncode(session.toMap());
  }

  SessionInfo _sessionFromJson(String jsonString) {
    final Map<String, dynamic> map = jsonDecode(jsonString) as Map<String, dynamic>;
    return SessionInfo.fromMap(map);
  }
}
