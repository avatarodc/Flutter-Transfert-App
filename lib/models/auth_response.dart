class AuthResponse {
  final String accessToken;
  final String message;
  final String status;

  AuthResponse({
    required this.accessToken,
    required this.message,
    required this.status,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['data']['accessToken'],
      message: json['message'],
      status: json['status'],
    );
  }
}