import 'api_service.dart';

class UserService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> register({
    required String nomComplet,
    required String numeroTelephone,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await _apiService.post('users/register/client', {
        'nomComplet': nomComplet,
        'numeroTelephone': numeroTelephone,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
      });
      return response;
    } catch (e) {
      throw Exception('Erreur lors de l\'inscription: $e');
    }
  }
}
