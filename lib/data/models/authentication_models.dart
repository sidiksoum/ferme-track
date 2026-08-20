import '../../domain/entities/authentication.dart';

/// Remote User DTO (Data Transfer Object)
class UserRemoteDto {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String role;
  final String? farmId;
  final String? avatarUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserRemoteDto({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    this.farmId,
    this.avatarUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  User toEntity() {
    return User(
      id: id,
      username: username,
      email: email,
      fullName: fullName,
      role: role,
      farmId: farmId,
      avatarUrl: avatarUrl,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory UserRemoteDto.fromMap(Map<String, dynamic> map) {
    return UserRemoteDto(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      fullName: map['full_name'] ?? map['fullName'] ?? '',
      role: map['role'] ?? '',
      farmId: map['farm_id'] ?? map['farmId'],
      avatarUrl: map['avatar_url'] ?? map['avatarUrl'],
      isActive: map['is_active'] ?? map['isActive'] ?? false,
      createdAt: DateTime.tryParse(map['created_at'] ?? map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'role': role,
      'farm_id': farmId,
      'avatar_url': avatarUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Auth Response DTO
class AuthResponseRemoteDto {
  final UserRemoteDto user;
  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;

  AuthResponseRemoteDto({
    required this.user,
    required this.accessToken,
    this.refreshToken,
    required this.expiresAt,
  });

  AuthResponse toEntity() {
    return AuthResponse(
      user: user.toEntity(),
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }

  factory AuthResponseRemoteDto.fromMap(Map<String, dynamic> map) {
    return AuthResponseRemoteDto(
      user: UserRemoteDto.fromMap(map['user'] ?? {}),
      accessToken: map['access_token'] ?? map['accessToken'] ?? '',
      refreshToken: map['refresh_token'] ?? map['refreshToken'],
      expiresAt: DateTime.tryParse(map['expires_at'] ?? map['expiresAt'] ?? '') ?? 
                  DateTime.now().add(const Duration(hours: 24)),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user': user.toMap(),
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_at': expiresAt.toIso8601String(),
    };
  }
}

/// Local User DTO
class UserLocalDto {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String role;
  final String? farmId;
  final String? avatarUrl;

  UserLocalDto({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    this.farmId,
    this.avatarUrl,
  });

  User toEntity() {
    return User(
      id: id,
      username: username,
      email: email,
      fullName: fullName,
      role: role,
      farmId: farmId,
      avatarUrl: avatarUrl,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory UserLocalDto.fromEntity(User user) {
    return UserLocalDto(
      id: user.id,
      username: user.username,
      email: user.email,
      fullName: user.fullName,
      role: user.role,
      farmId: user.farmId,
      avatarUrl: user.avatarUrl,
    );
  }

  factory UserLocalDto.fromMap(Map<String, dynamic> map) {
    return UserLocalDto(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      fullName: map['full_name'] ?? '',
      role: map['role'] ?? '',
      farmId: map['farm_id'],
      avatarUrl: map['avatar_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'role': role,
      'farm_id': farmId,
      'avatar_url': avatarUrl,
    };
  }
}
