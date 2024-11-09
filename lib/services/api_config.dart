import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';

class ApiConfig {
  // Configuration de base
  static const String _ipAddress = '192.168.1.12';  // Votre IP locale
  static const String _port = '8081';
  
  // Construction de l'URL de base
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://$_ipAddress:$_port/api/v1';
    } else {
      return 'http://localhost:$_port/api/v1';  
    }
  }

  // En-têtes de base
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Cache-Control': 'no-cache',
    'Pragma': 'no-cache',
  };

  // En-têtes avec authentification
  static Future<Map<String, String>> getAuthHeaders() async {
    try {
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token');
      
      return {
        ...headers,
        if (token != null) 'Authorization': 'Bearer $token',
      };
    } catch (e) {
      print('Erreur lors de la récupération du token: $e');
      return headers;
    }
  }

  // Méthode utilitaire pour vérifier la connexion au serveur
  static Future<bool> checkServerConnection() async {
    try {
      final socket = await Socket.connect(_ipAddress, int.parse(_port), 
          timeout: const Duration(seconds: 5));
      await socket.close();
      return true;
    } catch (e) {
      print('Erreur de connexion au serveur: $e');
      return false;
    }
  }
}