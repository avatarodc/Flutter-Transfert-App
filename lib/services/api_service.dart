// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';

class ApiService {
  final storage = const FlutterSecureStorage();

  // GET Request
  Future<dynamic> get(String endpoint) async {
    try {
      final token = await storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/$endpoint'),
        headers: {
          ...ApiConfig.headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // POST Request
  Future<dynamic> post(String endpoint, dynamic data) async {
    try {
      final token = await storage.read(key: 'token');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/$endpoint'),
        headers: {
          ...ApiConfig.headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // PUT Request
  Future<dynamic> put(String endpoint, dynamic data) async {
    try {
      final token = await storage.read(key: 'token');
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/$endpoint'),
        headers: {
          ...ApiConfig.headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // DELETE Request
  Future<dynamic> delete(String endpoint) async {
    try {
      final token = await storage.read(key: 'token');
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/$endpoint'),
        headers: {
          ...ApiConfig.headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Gestion des réponses
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Non autorisé');
    } else if (response.statusCode == 404) {
      throw Exception('Resource non trouvée');
    } else {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }
  }
}