enum AuthStatus {
  unauthenticated,
  authenticating,
  authenticated,
  pinLocked,
  error,
}

class UserProfile {
  final String id;
  final String name;
  final String phone;
  final String role;
  final String restaurantId;
  final String restaurantName;

  UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.restaurantId,
    required this.restaurantName,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
      restaurantId: json['restaurantId'] as String,
      restaurantName: json['restaurantName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
    };
  }
}

class AuthState {
  final AuthStatus status;
  final UserProfile? user;
  final String? accessToken;
  final String? refreshToken;
  final String? errorMessage;

  AuthState({
    required this.status,
    this.user,
    this.accessToken,
    this.refreshToken,
    this.errorMessage,
  });

  factory AuthState.initial() {
    return AuthState(status: AuthStatus.unauthenticated);
  }

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? user,
    String? accessToken,
    String? refreshToken,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
