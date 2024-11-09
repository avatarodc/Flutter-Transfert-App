import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_response.dart';
import 'api_config.dart';
import 'dart:async';
import 'dart:math';

class AuthService {
  final storage = const FlutterSecureStorage();
  static const String TOKEN_KEY = 'jwt_token';
  Timer? _tokenRefreshTimer;

  Future<AuthResponse> login(String phone, String password) async {
    try {
      print('🔐 === TENTATIVE DE CONNEXION ===');
      print('📱 Téléphone: $phone');
      print('🌐 URL: ${ApiConfig.baseUrl}/auth/login');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: ApiConfig.headers,
        body: json.encode({
          'username': phone,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 60));

      print('📡 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      switch (response.statusCode) {
        case 200:
          try {
            final decodedResponse = json.decode(response.body);
            print('✅ Connexion réussie');
            print('🔄 Décodage de la réponse...');
            
            final authResponse = AuthResponse.fromJson(decodedResponse);
            
            // Stockage du token
            await _saveToken(authResponse.accessToken);
            
            // Démarrer le timer de rafraîchissement si nécessaire
            _setupTokenRefresh(authResponse.accessToken);
            
            return authResponse;
          } catch (e) {
            print('❌ Erreur de traitement: $e');
            throw Exception('Erreur lors du traitement de la réponse: $e');
          }
        case 401:
          print('❌ Authentification échouée');
          final errorBody = json.decode(response.body);
          throw Exception('Identifiants incorrects');
        default:
          print('❌ Erreur ${response.statusCode}');
          throw Exception('Erreur de connexion (${response.statusCode})');
      }
    } catch (e) {
      print('❌ ERREUR: $e');
      rethrow;
    }
  }

  Future<void> _saveToken(String token) async {
    try {
      await storage.write(key: TOKEN_KEY, value: token);
      print('💾 Token sauvegardé');
    } catch (e) {
      print('❌ Erreur de sauvegarde du token: $e');
      throw Exception('Impossible de sauvegarder le token');
    }
  }

  Future<String?> getToken() async {
    try {
      final token = await storage.read(key: TOKEN_KEY);
      if (token != null && token.isNotEmpty) {
        return token;
      }
      print('⚠️ Aucun token trouvé');
      return null;
    } catch (e) {
      print('❌ Erreur de récupération du token: $e');
      return null;
    }
  }

  Future<bool> isTokenValid() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      // Décoder le token
      final parts = token.split('.');
      if (parts.length != 3) return false;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final data = json.decode(decoded);

      // Vérifier l'expiration
      final expiration = DateTime.fromMillisecondsSinceEpoch(data['exp'] * 1000);
      final isValid = DateTime.now().isBefore(expiration);
      
      print(isValid ? '✅ Token valide' : '⚠️ Token expiré');
      return isValid;
    } catch (e) {
      print('❌ Erreur de validation du token: $e');
      return false;
    }
  }

  void _setupTokenRefresh(String token) {
    // Annuler l'ancien timer s'il existe
    _tokenRefreshTimer?.cancel();

    try {
      // Décoder le token pour obtenir l'expiration
      final parts = token.split('.');
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final data = json.decode(decoded);

      final expiration = DateTime.fromMillisecondsSinceEpoch(data['exp'] * 1000);
      final now = DateTime.now();
      
      // Calculer le délai avant l'expiration (moins 5 minutes pour la marge)
      final refreshDelay = expiration.difference(now) - const Duration(minutes: 5);
      
      if (refreshDelay.isNegative) {
        print('⚠️ Token déjà expiré ou proche de l\'expiration');
        return;
      }

      // Configurer le timer pour le rafraîchissement
      _tokenRefreshTimer = Timer(refreshDelay, () async {
        print('🔄 Rafraîchissement du token nécessaire');
        // Implémenter la logique de rafraîchissement ici si nécessaire
      });
    } catch (e) {
      print('❌ Erreur dans la configuration du refresh: $e');
    }
  }

  Future<void> logout() async {
    try {
      print('🔐 Déconnexion...');
      await storage.delete(key: TOKEN_KEY);
      _tokenRefreshTimer?.cancel();
      print('✅ Déconnexion réussie');
    } catch (e) {
      print('❌ Erreur de déconnexion: $e');
      throw Exception('Échec de la déconnexion');
    }
  }

  Future<bool> checkAuthStatus() async {
    final isValid = await isTokenValid();
    if (!isValid) {
      await logout();
      return false;
    }
    return true;
  }
}