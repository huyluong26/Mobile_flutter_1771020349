/// Login request DTO - matches backend LoginDto
class LoginRequest {
  final String username;
  final String password;

  LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() {
    return {'username': username, 'password': password};
  }
}

/// Register request DTO - matches backend RegisterDto
class RegisterRequest {
  final String username;
  final String fullName;
  final String email;
  final String password;

  RegisterRequest({
    required this.username,
    required this.fullName,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'fullName': fullName,
      'email': email,
      'password': password,
    };
  }
}

/// Token response from login - matches backend TokenResponseDto
class TokenResponse {
  final String token;
  final String validTo;
  final String username;
  final String email;

  TokenResponse({
    required this.token,
    required this.validTo,
    required this.username,
    required this.email,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      token: json['token'] ?? '',
      validTo: json['validTo'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

/// User profile model - matches backend /api/auth/me response
class UserProfile {
  final int id;
  final String fullName;
  final String? username;
  final String? email;
  final double walletBalance;
  final String tier;
  final String? avatarUrl;
  final String? role;

  UserProfile({
    required this.id,
    required this.fullName,
    this.username,
    this.email,
    this.walletBalance = 0.0,
    this.tier = 'Standard',
    this.avatarUrl,
    this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      username: json['username'],
      email: json['email'],
      walletBalance: (json['walletBalance'] ?? 0).toDouble(),
      tier: json['tier'] ?? 'Standard',
      avatarUrl: json['avatarUrl'],
      role: json['role'],
    );
  }
}
