import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';
import 'dart:math';

class ApiService {
  final storage = const FlutterSecureStorage();
  static const String TOKEN_KEY = 'jwt_token'; // Changé de 'token' à 'jwt_token'

  // GET Request
  Future<dynamic> get(String endpoint) async {
    try {
      // print('🌐 GET request to: ${ApiConfig.baseUrl}/$endpoint');
      final token = await storage.read(key: TOKEN_KEY);
      
      if (token == null && endpoint != 'auth/login') {
        print('⚠️ Pas de token trouvé pour la requête');
        throw Exception('Non authentifié');
      }

      // print('🔑 Token utilisé: ${token?.substring(0, min(20, token.length ?? 0))}...');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/$endpoint'),
        headers: {
          ...ApiConfig.headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      // print('📡 Status: ${response.statusCode}');
      // print('📦 Response: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('❌ GET Error: $e');
      await _handleError(e);
      rethrow;
    }
  }

  // POST Request
  Future<dynamic> post(String endpoint, dynamic data) async {
    try {
      print('🌐 POST request to: ${ApiConfig.baseUrl}/$endpoint');
      print('📦 Data: $data');
      
      final token = await storage.read(key: TOKEN_KEY);
      if (token == null && !endpoint.contains('auth')) {
        print('⚠️ Pas de token trouvé pour la requête');
        throw Exception('Non authentifié');
      }

      if (token != null) {
        // print('🔑 Token utilisé: ${token.substring(0, min(20, token.length))}...');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/$endpoint'),
        headers: {
          ...ApiConfig.headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      // print('📡 Status: ${response.statusCode}');
      // print('📦 Response: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('❌ POST Error: $e');
      await _handleError(e);
      rethrow;
    }
  }

  // PUT Request
  Future<dynamic> put(String endpoint, dynamic data) async {
    try {
      print('🌐 PUT request to: ${ApiConfig.baseUrl}/$endpoint');
      final token = await storage.read(key: TOKEN_KEY);
      
      if (token == null) {
        print('⚠️ Pas de token trouvé pour la requête');
        throw Exception('Non authentifié');
      }

      // print('🔑 Token utilisé: ${token.substring(0, min(20, token.length))}...');
      print('📦 Data: $data');

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/$endpoint'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      // print('📡 Status: ${response.statusCode}');
      // print('📦 Response: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('❌ PUT Error: $e');
      await _handleError(e);
      rethrow;
    }
  }

  // DELETE Request
  Future<dynamic> delete(String endpoint) async {
    try {
      print('🌐 DELETE request to: ${ApiConfig.baseUrl}/$endpoint');
      final token = await storage.read(key: TOKEN_KEY);
      
      if (token == null) {
        print('⚠️ Pas de token trouvé pour la requête');
        throw Exception('Non authentifié');
      }

      // print('🔑 Token utilisé: ${token.substring(0, min(20, token.length))}...');

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/$endpoint'),
        headers: {
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        },
      );

      // print('📡 Status: ${response.statusCode}');
      // print('📦 Response: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('❌ DELETE Error: $e');
      await _handleError(e);
      rethrow;
    }
  }

  // Gestion des réponses
  dynamic _handleResponse(http.Response response) {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return null;
        
        final decodedResponse = json.decode(response.body);
        // print('✅ Response décodée: $decodedResponse');
        
        // Vérifier si la réponse contient data
        if (decodedResponse is Map && decodedResponse.containsKey('data')) {
          return decodedResponse['data'];
        }
        
        return decodedResponse;
      } 
      
      if (response.statusCode == 401) {
        print('🚫 Erreur d\'authentification');
        throw Exception('Non autorisé');
      } 
      
      if (response.statusCode == 404) {
        print('🔍 Resource non trouvée');
        throw Exception('Resource non trouvée');
      }
      
      print('⚠️ Erreur serveur: ${response.statusCode}');
      throw Exception('Erreur serveur: ${response.statusCode}');
    } catch (e) {
      print('❌ Erreur traitement réponse: $e');
      throw Exception('Erreur de traitement: $e');
    }
  }

  // Gestion des erreurs
  Future<void> _handleError(dynamic error) async {
    if (error.toString().contains('Non autorisé') || 
        error.toString().contains('Non authentifié')) {
      print('🔄 Suppression du token suite à une erreur d\'authentification');
      await storage.delete(key: TOKEN_KEY);
    }
  }
}