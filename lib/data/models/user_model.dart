class AuthSession {
  final String? userId;
  final String username;
  final String? email;
  final String? accessToken;
  final String? refreshToken;
  final String authScheme; // 'Bearer' or 'Token'
  final bool isDemo;
  final bool isSupabaseConnected;
  final DateTime loggedInAt;

  const AuthSession({
    this.userId,
    required this.username,
    this.email,
    this.accessToken,
    this.refreshToken,
    this.authScheme = 'Bearer',
    this.isDemo = false,
    this.isSupabaseConnected = false,
    required this.loggedInAt,
  });

  bool get hasToken => accessToken != null && accessToken!.isNotEmpty;

  String? get authorizationHeader {
    if (!hasToken) return null;
    return '$authScheme $accessToken';
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'username': username,
        'email': email,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'authScheme': authScheme,
        'isDemo': isDemo,
        'isSupabaseConnected': isSupabaseConnected,
        'loggedInAt': loggedInAt.toIso8601String(),
      };

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      userId: json['userId'] as String?,
      username: (json['username'] ?? 'Athlete') as String,
      email: json['email'] as String?,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      authScheme: (json['authScheme'] ?? 'Bearer') as String,
      isDemo: (json['isDemo'] ?? false) as bool,
      isSupabaseConnected: (json['isSupabaseConnected'] ?? false) as bool,
      loggedInAt: DateTime.tryParse(json['loggedInAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
