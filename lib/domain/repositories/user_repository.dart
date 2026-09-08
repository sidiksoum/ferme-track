import 'package:dartz/dartz.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../entities/authentication.dart';

/// Repository interface for User management (Director feature)
abstract class UserRepository {
  /// Fetch list of users for the farm
  Future<Either<AppException, List<User>>> getUsers({String? role});

  /// Create a new user / collaborator
  Future<Either<AppException, User>> createUser({
    required String email,
    required String username,
    required String fullName,
    required String phone,
    required String role,
    required String password,
  });

  /// Update an existing user / collaborator
  Future<Either<AppException, User>> updateUser({
    required String userId,
    required String email,
    required String fullName,
    required String phone,
    required String role,
    required String status,
    required String farmId,
  });

  /// Delete / Deactivate a user
  Future<Either<AppException, void>> deleteUser(String userId);
}
