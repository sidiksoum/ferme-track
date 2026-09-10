import 'package:dartz/dartz.dart';

import '../../../core/exceptions/app_exceptions.dart';
import '../../../core/interfaces/network_checker.dart';
import '../../../core/utils/app_logger.dart';
import '../../../domain/entities/authentication.dart';
import '../../../domain/repositories/user_repository.dart';
import '../datasources/remote/api_client.dart';
import '../models/authentication_models.dart';

/// Implementation of UserRepository
class UserRepositoryImpl implements UserRepository {
  final ApiClient apiClient;
  final NetworkChecker networkChecker;

  UserRepositoryImpl({
    required this.apiClient,
    required this.networkChecker,
  });

  String _mapRoleToBackend(String role) {
    if (role == 'directeur') return 'director';
    if (role == 'technicien') return 'technician';
    if (role == 'magasinier') return 'warehouse';
    if (role == 'volailler') return 'poultrykeeper';
    return role;
  }

  @override
  Future<Either<AppException, List<User>>> getUsers({String? role}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (role != null) {
        queryParams['role'] = _mapRoleToBackend(role);
      }

      final response = await apiClient.get(
        '/users',
        queryParameters: queryParams,
        useCache: true,
      );

      // Parse list of users safely from any Map type
      final List<dynamic> usersJson = response is List ? response : [];
      final List<User> usersList = usersJson.whereType<Map>().map((jsonMap) {
        final map = Map<String, dynamic>.from(jsonMap);
        final dto = UserRemoteDto.fromMap(map);
        return dto.toEntity();
      }).toList();

      return Right(usersList);
    } on AppException catch (e) {
      AppLogger.error('Failed to get users: ${e.message}');
      return Left(e);
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error during getUsers', e, stackTrace);
      return Left(UnknownException(message: 'Échec de la récupération des utilisateurs', stackTrace: stackTrace));
    }
  }

  @override
  Future<Either<AppException, User>> createUser({
    required String email,
    required String username,
    required String fullName,
    required String phone,
    required String role,
    required String password,
  }) async {
    try {
      if (!await networkChecker.hasConnection) {
        return Left(NetworkException(message: 'Pas de connexion Internet.'));
      }

      final mappedRole = _mapRoleToBackend(role);

      final response = await apiClient.post(
        '/users',
        data: {
          'email': email,
          'username': username,
          'full_name': fullName,
          'phone': phone,
          'role': mappedRole,
          'must_change_password': true,
          'password': password,
        },
      );

      final dto = UserRemoteDto.fromMap(response);
      return Right(dto.toEntity());
    } on AppException catch (e) {
      AppLogger.error('Failed to create user: ${e.message}');
      return Left(e);
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error during createUser', e, stackTrace);
      return Left(UnknownException(message: 'Échec de la création de l\'utilisateur', stackTrace: stackTrace));
    }
  }

  @override
  Future<Either<AppException, User>> updateUser({
    required String userId,
    required String email,
    required String fullName,
    required String phone,
    required String role,
    required String status,
    required String farmId,
  }) async {
    try {
      if (!await networkChecker.hasConnection) {
        return Left(NetworkException(message: 'Pas de connexion Internet.'));
      }

      final mappedRole = _mapRoleToBackend(role);

      final response = await apiClient.put(
        '/users/$userId',
        data: {
          'email': email,
          'full_name': fullName,
          'phone': phone,
          'role': mappedRole,
          'status': status,
          'farm_id': farmId,
        },
      );

      final dto = UserRemoteDto.fromMap(response);
      return Right(dto.toEntity());
    } on AppException catch (e) {
      AppLogger.error('Failed to update user: ${e.message}');
      return Left(e);
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error during updateUser', e, stackTrace);
      return Left(UnknownException(message: 'Échec de la modification de l\'utilisateur', stackTrace: stackTrace));
    }
  }

  @override
  Future<Either<AppException, void>> deleteUser(String userId) async {
    try {
      if (!await networkChecker.hasConnection) {
        return Left(NetworkException(message: 'Pas de connexion Internet.'));
      }

      await apiClient.delete('/users/$userId');
      return const Right(null);
    } on AppException catch (e) {
      AppLogger.error('Failed to delete user: ${e.message}');
      return Left(e);
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error during deleteUser', e, stackTrace);
      return Left(UnknownException(message: 'Échec de la suppression de l\'utilisateur', stackTrace: stackTrace));
    }
  }
}
