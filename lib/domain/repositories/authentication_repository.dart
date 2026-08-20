import 'package:dartz/dartz.dart';

import '../../../../core/exceptions/app_exceptions.dart';
import '../entities/authentication.dart';

/// Authentication Repository Interface
abstract class AuthenticationRepository {
  /// Login user with credentials
  Future<Either<AppException, AuthResponse>> login(
    String username,
    String password,
  );

  /// Logout current user
  Future<Either<AppException, void>> logout();

  /// Check if user is already logged in
  Future<Either<AppException, bool>> isLoggedIn();

  /// Get current session info
  Future<Either<AppException, SessionInfo?>> getSessionInfo();

  /// Refresh access token
  Future<Either<AppException, AuthResponse>> refreshToken();

  /// Get current user
  Future<Either<AppException, User?>> getCurrentUser();

  /// Update user profile
  Future<Either<AppException, User>> updateProfile(User user);

  /// Change password
  Future<Either<AppException, void>> changePassword(
    String oldPassword,
    String newPassword,
  );

  /// Request password reset
  Future<Either<AppException, void>> requestPasswordReset(String email);

  /// Reset password with token
  Future<Either<AppException, void>> resetPassword(
    String token,
    String newPassword,
  );

  /// Enable biometric authentication
  Future<Either<AppException, void>> enableBiometric(String password);

  /// Disable biometric authentication
  Future<Either<AppException, void>> disableBiometric();

  /// Check if biometric is enabled
  Future<Either<AppException, bool>> isBiometricEnabled();

  /// Authenticate with biometric
  Future<Either<AppException, AuthResponse>> authenticateWithBiometric();
}
