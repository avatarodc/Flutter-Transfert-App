import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_response.dart';
import 'api_config.dart';
import 'dart:async';
import 'dart:math';

class AuthService {
  final storage = const FlutterSecureStorage();

  Future<AuthResponse> login(String phone, String password) async {
    try {
      print('Tentative de connexion à : ${ApiConfig.baseUrl}/auth/login');
      print('Données envoyées : phone=$phone');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: ApiConfig.headers,
        body: json.encode({
          'username': phone,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 60));

      print('Code de statut de la réponse : ${response.statusCode}');
      print('Corps de la réponse : ${response.body}');
      print('En-têtes de la réponse : ${response.headers}');

      switch (response.statusCode) {
        case 200:
          try {
            final decodedResponse = json.decode(response.body);
            print('Réponse décodée : $decodedResponse');
            final authResponse = AuthResponse.fromJson(decodedResponse);
            await storage.write(key: 'jwt_token', value: authResponse.accessToken);
            return authResponse;
          } catch (e) {
            throw Exception('Erreur lors du traitement de la réponse: $e\nRéponse reçue: ${response.body}');
          }
        case 302:
          final redirectUrl = response.headers['location'];
          if (redirectUrl != null) {
            final redirectResponse = await http.post(
              Uri.parse(redirectUrl),
              headers: ApiConfig.headers,
              body: json.encode({
                'username': phone,
                'password': password,
              }),
            ).timeout(const Duration(seconds: 60));
            return handleResponse(redirectResponse); 
          }
          throw Exception('Redirection détectée sans URL');
        case 400:
          final errorBody = json.decode(response.body);
          throw Exception('Requête invalide: ${errorBody['message'] ?? 'Erreur inconnue'}');
        case 401:
          final errorBody = json.decode(response.body);
          throw Exception('Non autorisé: ${errorBody['message'] ?? 'Erreur inconnue'}');
        case 404:
          throw Exception('Route non trouvée');
        case 500:
          final errorBody = json.decode(response.body);
          if (errorBody['data'] == 'Bad credentials') {
            throw Exception('Login ou mot de passe incorrect');
          } else {
            throw Exception('Erreur serveur: ${errorBody['message'] ?? 'Erreur inconnue'}');
          }
        default:
          throw Exception('Erreur inattendue (${response.statusCode})');
      }
    } on http.ClientException catch (e) {
      throw Exception('Erreur de connexion au serveur. Vérifiez votre connexion internet.');
    } on TimeoutException catch (e) {
      throw Exception('Le serveur ne répond pas. Veuillez réessayer plus tard.');
    } on FormatException catch (e) {
      throw Exception('Erreur de format de réponse');
    } catch (e) {
      if (e.toString().contains('Login ou mot de passe incorrect')) {
        rethrow;  // Renvoie l'erreur originale si c'est déjà une erreur de credentials
      }
      throw Exception('Une erreur est survenue. Veuillez réessayer.');
    }
  }

  Future<String?> getToken() async {
    try {
      final token = await storage.read(key: 'jwt_token');
      if (token != null && token.isNotEmpty) {
        print('Token récupéré : ${token.substring(0, min(10, token.length))}...');
        return token;
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération du token : $e');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await storage.delete(key: 'jwt_token');
      print('Déconnexion réussie - Token supprimé');
    } catch (e) {
      print('Erreur lors de la déconnexion : $e');
      throw Exception('Échec de la déconnexion');
    }
  }

  Future<AuthResponse> handleResponse(http.Response response) async {
    try {
      final decodedResponse = json.decode(response.body);
      return AuthResponse.fromJson(decodedResponse);
    } catch (e) {
      throw Exception('Erreur lors du traitement de la réponse');
    }
  }
}