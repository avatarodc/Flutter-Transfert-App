import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';
import 'auth_service.dart';
import '../models/user_model.dart';

class UserService {
  final ApiService _apiService;
  final AuthService _authService;
  final storage = const FlutterSecureStorage();
  User? _currentUser;
  Timer? _refreshTimer; // Timer pour le rafraîchissement
  static const String TOKEN_KEY = 'jwt_token';

  UserService(this._apiService) : _authService = AuthService() {
    _startAutoRefresh(); // Démarrer le rafraîchissement automatique
  }

  User? get currentUser => _currentUser;

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await refreshUserData(); // Appeler refreshUserData toutes les 5 secondes
    });
  }

  void dispose() {
    stopAutoRefresh(); // Appel correct, ne tente pas d'utiliser la valeur de retour
  }

     Future<void> stopAutoRefresh() async {
  _refreshTimer?.cancel();
}

  // Récupérer tous les utilisateurs
  Future<List<User>> getAllUsers() async {
    try {
      developer.log('📋 Récupération de tous les utilisateurs', name: 'UserService');

      final isAuth = await _checkAuthentication();
      if (!isAuth) throw Exception('Non authentifié');

      final response = await _apiService.get('users');
      final users = (response as List).map((json) => User.fromJson(json)).toList();
      // developer.log('✅ ${users.length} utilisateurs récupérés', name: 'UserService');
      return users;
    } catch (e) {
      // developer.log('❌ Erreur dans getAllUsers()', name: 'UserService', error: e);
      throw Exception('Erreur lors de la récupération des utilisateurs: $e');
    }
  }

  // Créer un nouvel utilisateur
  Future<User> createUser(Map<String, dynamic> userData) async {
    try {
      developer.log('👤 Création d\'un nouvel utilisateur: $userData', name: 'UserService');

      final isAuth = await _checkAuthentication();
      if (!isAuth) throw Exception('Non authentifié');

      final response = await _apiService.post('users', userData);
      final user = User.fromJson(response);
      developer.log('✅ Utilisateur créé avec succès: ${user.toJson()}', name: 'UserService');
      return user;
    } catch (e) {
      developer.log('❌ Erreur dans createUser()', name: 'UserService', error: e);
      throw Exception('Erreur lors de la création de l\'utilisateur: $e');
    }
  }

  // Inscription d'un client
  Future<Map<String, dynamic>> register({
    required String nomComplet,
    required String numeroTelephone,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      developer.log('📝 Inscription: $email, $nomComplet, $numeroTelephone', name: 'UserService');

      final response = await _apiService.post('users/register/client', {
        'nomComplet': nomComplet,
        'numeroTelephone': numeroTelephone,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
      });

      developer.log('✅ Inscription réussie', name: 'UserService');
      return response;
    } catch (e) {
      developer.log('❌ Erreur dans register()', name: 'UserService', error: e);
      throw Exception('Erreur lors de l\'inscription: $e');
    }
  }

  // Récupérer un utilisateur par ID
  Future<User> getUserById(String id) async {
    try {
      developer.log('🔍 Récupération utilisateur ID: $id', name: 'UserService');

      final isAuth = await _checkAuthentication();
      if (!isAuth) throw Exception('Non authentifié');

      final response = await _apiService.get('users/$id');
      final user = User.fromJson(response);
      developer.log('✅ Utilisateur récupéré: ${user.toJson()}', name: 'UserService');
      return user;
    } catch (e) {
      developer.log('❌ Erreur dans getUserById()', name: 'UserService', error: e);
      throw Exception('Erreur lors de la récupération de l\'utilisateur: $e');
    }
  }

  // Supprimer un utilisateur
  Future<void> deleteUser(String id) async {
    try {
      developer.log('🗑️ Suppression utilisateur: $id', name: 'UserService');

      final isAuth = await _checkAuthentication();
      if (!isAuth) throw Exception('Non authentifié');

      await _apiService.delete('users/$id');
      developer.log('✅ Utilisateur supprimé avec succès', name: 'UserService');
    } catch (e) {
      developer.log('❌ Erreur dans deleteUser()', name: 'UserService', error: e);
      throw Exception('Erreur lors de la suppression de l\'utilisateur: $e');
    }
  }

  // Récupérer un utilisateur par numéro de téléphone
  Future<User> getUserByPhone(String numeroTelephone) async {
    try {
      developer.log('📱 Recherche par téléphone: $numeroTelephone', name: 'UserService');

      final isAuth = await _checkAuthentication();
      if (!isAuth) throw Exception('Non authentifié');

      final response = await _apiService.get('users/telephone/$numeroTelephone');
      final user = User.fromJson(response);
      developer.log('✅ Utilisateur trouvé: ${user.toJson()}', name: 'UserService');
      return user;
    } catch (e) {
      developer.log('❌ Erreur dans getUserByPhone()', name: 'UserService', error: e);
      throw Exception('Erreur lors de la récupération de l\'utilisateur: $e');
    }
  }

  // Récupérer les utilisateurs par rôle
  Future<List<User>> getUsersByRole(String roleId) async {
    try {
      developer.log('👥 Recherche utilisateurs rôle: $roleId', name: 'UserService');

      final isAuth = await _checkAuthentication();
      if (!isAuth) throw Exception('Non authentifié');

      final response = await _apiService.get('users/role/$roleId');
      final users = (response as List).map((json) => User.fromJson(json)).toList();
      developer.log('✅ ${users.length} utilisateurs trouvés', name: 'UserService');
      return users;
    } catch (e) {
      developer.log('❌ Erreur dans getUsersByRole()', name: 'UserService', error: e);
      throw Exception('Erreur lors de la récupération des utilisateurs par rôle: $e');
    }
  }

  // Récupérer un utilisateur par email
  Future<User> getUserByEmail(String email) async {
    try {
      developer.log('📧 Recherche par email: $email', name: 'UserService');

      final isAuth = await _checkAuthentication();
      if (!isAuth) throw Exception('Non authentifié');

      final response = await _apiService.get('users/email/$email');
      final user = User.fromJson(response);
      developer.log('✅ Utilisateur trouvé: ${user.toJson()}', name: 'UserService');
      return user;
    } catch (e) {
      developer.log('❌ Erreur dans getUserByEmail()', name: 'UserService', error: e);
      throw Exception('Erreur lors de la récupération de l\'utilisateur: $e');
    }
  }

  // Récupérer les utilisateurs actifs
  Future<List<User>> getActiveUsers() async {
    try {
      developer.log('👥 Récupération utilisateurs actifs', name: 'UserService');

      final isAuth = await _checkAuthentication();
      if (!isAuth) throw Exception('Non authentifié');

      final response = await _apiService.get('users/active');
      final users = (response as List).map((json) => User.fromJson(json)).toList();
      developer.log('✅ ${users.length} utilisateurs actifs trouvés', name: 'UserService');
      return users;
    } catch (e) {
      developer.log('❌ Erreur dans getActiveUsers()', name: 'UserService', error: e);
      throw Exception('Erreur lors de la récupération des utilisateurs actifs: $e');
    }
  }

  // Vérifier l'authentification
  Future<bool> isAuthenticated() async {
    try {
      developer.log('🔒 Vérification authentification', name: 'UserService');
      final token = await storage.read(key: TOKEN_KEY);
      final isAuth = token != null && token.isNotEmpty;
      developer.log(isAuth ? '✅ Authentifié' : '⚠️ Non authentifié', name: 'UserService');
      return isAuth;
    } catch (e) {
      developer.log('❌ Erreur dans isAuthenticated()', name: 'UserService', error: e);
      return false;
    }
  }

  // Déconnexion
  Future<void> logout() async {
    try {
      developer.log('🔓 Déconnexion...', name: 'UserService');
      await storage.delete(key: TOKEN_KEY);
      _currentUser = null;
      developer.log('✅ Déconnexion réussie', name: 'UserService');
    } catch (e) {
      developer.log('❌ Erreur dans logout()', name: 'UserService', error: e);
      throw Exception('Erreur lors de la déconnexion: $e');
    }
  }

  // Décoder le token JWT
  Map<String, dynamic> _decodeToken(String token) {
    try {
      developer.log('🔑 Décodage du token JWT', name: 'UserService');
      final parts = token.split('.');
      if (parts.length != 3) {
        throw Exception('Token JWT invalide');
      }

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final decodedJson = json.decode(decoded);
      developer.log('✅ Token décodé avec succès', name: 'UserService');
      return decodedJson;
    } catch (e) {
      developer.log('❌ Erreur dans _decodeToken()', name: 'UserService', error: e);
      throw Exception('Erreur lors du décodage du token: $e');
    }
  }

  // Récupérer l'utilisateur courant
  Future<User?> getCurrentUser() async {
    try {
      developer.log('👤 Récupération utilisateur courant', name: 'UserService');

      final isAuth = await _checkAuthentication();
      if (!isAuth) {
        developer.log('⚠️ Non authentifié', name: 'UserService');
        return null;
      }

      if (_currentUser != null) {
        // developer.log('✅ Utilisateur en cache: ${_currentUser?.toJson()}', name: 'UserService');
        return _currentUser;
      }

      final token = await storage.read(key: TOKEN_KEY);
      if (token == null) {
        developer.log('⚠️ Aucun token trouvé', name: 'UserService');
        return null;
      }

      final decodedToken = _decodeToken(token);
      final email = decodedToken['sub'] as String;
      // developer.log('📧 Email extrait: $email', name: 'UserService');

      final user = await getUserByEmail(email);
      _currentUser = user;
      // developer.log('✅ Utilisateur récupéré: ${user.toJson()}', name: 'UserService');

      return user;
    } catch (e) {
      developer.log('❌ Erreur dans getCurrentUser()', name: 'UserService', error: e);
      await _handleAuthError(e);
      throw Exception('Erreur lors de la récupération de l\'utilisateur courant: $e');
    }
  }

  // Rafraîchir les données utilisateur
  Future<void> refreshUserData() async {
    try {
      developer.log('🔄 Rafraîchissement données utilisateur', name: 'UserService');
      _currentUser = null;
      await getCurrentUser(); // Assurez-vous que getCurrentUser() est correctement appelé
    } catch (e) {
      developer.log('❌ Erreur dans refreshUserData()', name: 'UserService', error: e);
      throw Exception('Erreur lors du rafraîchissement des données: $e');
    }
  }

  // Obtenir les informations du token
  Future<Map<String, dynamic>?> getTokenInfo() async {
    try {
      developer.log('🔍 Récupération infos token', name: 'UserService');
      final token = await storage.read(key: TOKEN_KEY);
      if (token == null) {
        developer.log('⚠️ Aucun token trouvé', name: 'UserService');
        return null;
      }
      return _decodeToken(token);
    } catch (e) {
      developer.log('❌ Erreur dans getTokenInfo()', name: 'UserService', error: e);
      throw Exception('Erreur lors de la récupération des informations du token: $e');
    }
  }

  // Vérifier si le token est expiré
  Future<bool> isTokenExpired() async {
    try {
      developer.log('⏰ Vérification expiration token', name: 'UserService');
      final tokenInfo = await getTokenInfo();
      if (tokenInfo == null) return true;

      final expiration = DateTime.fromMillisecondsSinceEpoch(
        (tokenInfo['exp'] as int) * 1000,
      );
      final isExpired = DateTime.now().isAfter(expiration);
      developer.log(isExpired ? '⚠️ Token expiré' : '✅ Token valide', name: 'UserService');
      return isExpired;
    } catch (e) {
      developer.log('❌ Erreur dans isTokenExpired()', name: 'UserService', error: e);
      return true;
    }
  }

  // Méthodes privées d'aide
  Future<bool> _checkAuthentication() async {
    final isAuth = await isAuthenticated();
    if (!isAuth) return false;

    final isExpired = await isTokenExpired();
    if (isExpired) {
      await logout();
      return false;
    }
    return true;
  }

  Future<void> _handleAuthError(dynamic error) async {
    if (error.toString().contains('Non authentifié') ||
        error.toString().contains('Token expiré')) {
      await logout();
    }
  }
}
