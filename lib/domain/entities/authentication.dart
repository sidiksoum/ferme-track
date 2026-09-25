/// Domain User Entity
class User {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String role;
  final String? farmId;
  final String? farmName;
  final String? avatarUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    this.farmId,
    this.farmName,
    this.avatarUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? fullName,
    String? role,
    String? farmId,
    String? farmName,
    String? avatarUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      farmId: farmId ?? this.farmId,
      farmName: farmName ?? this.farmName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'role': role,
      'farmId': farmId,
      'farmName': farmName,
      'avatarUrl': avatarUrl,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? map['full_name'] ?? '',
      role: map['role'] ?? '',
      farmId: map['farmId'] ?? map['farm_id'],
      farmName: map['farmName'] ?? map['farm_name'] ?? (map['farm'] is Map ? map['farm']['name'] : null),
      avatarUrl: map['avatarUrl'] ?? map['avatar_url'],
      isActive: map['isActive'] ?? map['is_active'] ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] ?? map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Authentication credentials
class AuthCredentials {
  final String username;
  final String password;

  AuthCredentials({
    required this.username,
    required this.password,
  });
}

/// Authentication response
class AuthResponse {
  final User user;
  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;

  AuthResponse({
    required this.user,
    required this.accessToken,
    this.refreshToken,
    required this.expiresAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user': user.toMap(),
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory AuthResponse.fromMap(Map<String, dynamic> map) {
    return AuthResponse(
      user: User.fromMap(map['user'] ?? {}),
      accessToken: map['accessToken'] ?? '',
      refreshToken: map['refreshToken'],
      expiresAt: DateTime.tryParse(map['expiresAt'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Session info
class SessionInfo {
  final User user;
  final String accessToken;
  final DateTime expiresAt;

  SessionInfo({
    required this.user,
    required this.accessToken,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isExpired;

  Map<String, dynamic> toMap() {
    return {
      'user': user.toMap(),
      'accessToken': accessToken,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory SessionInfo.fromMap(Map<String, dynamic> map) {
    return SessionInfo(
      user: User.fromMap(map['user'] ?? {}),
      accessToken: map['accessToken'] ?? '',
      expiresAt: DateTime.tryParse(map['expiresAt'] ?? '') ?? DateTime.now(),
    );
  }
}
