import 'dart:developer' as developer;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/numero_favori_model.dart';
import 'api_service.dart';
import 'api_config.dart';
import 'auth_service.dart';
import 'user_service.dart';

class NumeroFavoriService {
  final ApiService _apiService;
  final AuthService _authService;
  final storage = const FlutterSecureStorage();
  
  static const String _baseEndpoint = 'favoris';

  NumeroFavoriService(this._apiService) : _authService = AuthService();

  Future<int> _getCurrentUserId() async {
    try {
      final userService = UserService(_apiService);
      final currentUser = await userService.getCurrentUser();
      if (currentUser?.id == null) {
        throw Exception('Impossible de récupérer l\'ID utilisateur');
      }
      return int.parse(currentUser!.id!);
    } catch (e) {
      print('❌ Erreur récupération ID utilisateur: $e');
      rethrow;
    }
  }

  String _formatPhoneNumber(String phoneNumber) {
    try {
      String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      print('🔄 Formatage numéro: $phoneNumber -> $cleanNumber');
      
      if (cleanNumber.startsWith('+221')) {
        return cleanNumber;
      }
      
      if (cleanNumber.startsWith('221')) {
        return '+$cleanNumber';
      }
      
      if (cleanNumber.startsWith('7')) {
        return '+221$cleanNumber';
      }
      
      throw Exception('Le numéro doit commencer par 7 ou +221 ou 221');
    } catch (e) {
      print('❌ Erreur de formatage du numéro: $e');
      rethrow;
    }
  }

  Future<List<NumeroFavori>> getAllNumerosFavoris(int clientId) async {
    try {
      print('\n=== RÉCUPÉRATION DES FAVORIS ===');
      
      final currentUserId = await _getCurrentUserId();
      if (clientId != currentUserId) {
        print('⚠️ Attention: ID demandé ($clientId) différent de l\'ID utilisateur ($currentUserId)');
        clientId = currentUserId;
      }

      final userService = UserService(_apiService);
      final currentUser = await userService.getCurrentUser();
      print('👤 Utilisateur: ${currentUser?.nomComplet ?? 'Inconnu'} (ID: $clientId)');
      
      final isAuth = await _authService.isTokenValid();
      if (!isAuth) {
        throw Exception('Non authentifié');
      }

      print('\n📡 REQUÊTE:');
      print('Endpoint: $_baseEndpoint/$clientId');

      final response = await _apiService.get('$_baseEndpoint/$clientId');
      
      print('\n📦 RÉPONSE BRUTE:');
      print(response);

      if (response == null) {
        print('⚠️ Réponse null reçue');
        return [];
      }

      List<NumeroFavori> favoris = [];
      if (response is List) {
        favoris = response.map((json) => NumeroFavori.fromJson(json)).toList();
      } else if (response is Map<String, dynamic>) {
        if (response.containsKey('data')) {
          final data = response['data'];
          if (data is List) {
            favoris = data.map((json) => NumeroFavori.fromJson(json)).toList();
          } else if (data != null) {
            favoris = [NumeroFavori.fromJson(data)];
          }
        } else {
          favoris = [NumeroFavori.fromJson(response)];
        }
      }

      print('\n✅ RÉSULTAT:');
      print('Nombre de favoris: ${favoris.length}');
      favoris.forEach((f) => print('- ${f.numeroTelephone} (${f.nom ?? 'Sans nom'})'));
      
      return favoris;
    } catch (e) {
      print('\n❌ ERREUR:');
      print('Type: ${e.runtimeType}');
      print('Message: $e');
      rethrow;
    }
  }

  Future<NumeroFavori?> ajouterNumeroFavori({
    required int clientId,
    required String numeroTelephone,
    String? nom,
  }) async {
    try {
      print('\n=== AJOUT FAVORI ===');

      final currentUserId = await _getCurrentUserId();
      if (clientId != currentUserId) {
        print('⚠️ Correction de l\'ID client');
        clientId = currentUserId;
      }

      final formattedNumber = _formatPhoneNumber(numeroTelephone);
      print('📱 Numéro formaté: $formattedNumber');

      final isAuth = await _authService.isTokenValid();
      if (!isAuth) {
        throw Exception('Non authentifié');
      }

      // Vérification si déjà en favori
      final existingFavoris = await getAllNumerosFavoris(clientId);
      if (existingFavoris.any((f) => f.numeroTelephone == formattedNumber)) {
        throw Exception('Ce numéro est déjà dans vos favoris');
      }

      // Construction des paramètres de requête
      final queryParams = {
        'numeroTelephone': formattedNumber,
        if (nom != null && nom.isNotEmpty) 'nom': nom,
      };
      
      // Construction de l'URL avec les query parameters
      final endpoint = '$_baseEndpoint/$clientId';
      final queryString = Uri(queryParameters: queryParams).query;
      final fullEndpoint = '$endpoint?$queryString';

      print('\n📡 REQUÊTE:');
      print('Endpoint: $fullEndpoint');

      // Envoi de la requête sans body car les paramètres sont dans l'URL
      final response = await _apiService.post(fullEndpoint, null);

      print('\n📦 RÉPONSE:');
      print(response);

      if (response == null) {
        throw Exception('Erreur lors de l\'ajout du favori');
      }

      final favori = NumeroFavori.fromJson(response);
      print('\n✅ Favori ajouté avec succès (ID: ${favori.id})');

      return favori;
    } catch (e) {
      print('\n❌ ERREUR AJOUT FAVORI:');
      print('Type: ${e.runtimeType}');
      print('Message: $e');
      rethrow;
    }
  }

  Future<bool> supprimerNumeroFavori({
    required int clientId,
    required String numeroTelephone,
  }) async {
    try {
      print('\n=== SUPPRESSION FAVORI ===');

      final currentUserId = await _getCurrentUserId();
      if (clientId != currentUserId) {
        clientId = currentUserId;
      }

      final formattedNumber = _formatPhoneNumber(numeroTelephone);
      print('📱 Numéro à supprimer: $formattedNumber');

      final isAuth = await _authService.isTokenValid();
      if (!isAuth) {
        throw Exception('Non authentifié');
      }

      final queryParams = {'numeroTelephone': formattedNumber};
      final queryString = Uri(queryParameters: queryParams).query;
      final endpoint = '$_baseEndpoint/$clientId?$queryString';

      print('\n📡 REQUÊTE:');
      print('Endpoint: $endpoint');

      final response = await _apiService.delete(endpoint);
      
      print('\n✅ Suppression effectuée');
      return response != null;
    } catch (e) {
      print('\n❌ ERREUR SUPPRESSION:');
      print('Type: ${e.runtimeType}');
      print('Message: $e');
      rethrow;
    }
  }

  Future<bool> isNumeroFavori({
    required int clientId,
    required String numeroTelephone,
  }) async {
    try {
      final currentUserId = await _getCurrentUserId();
      if (clientId != currentUserId) {
        clientId = currentUserId;
      }

      final formattedNumber = _formatPhoneNumber(numeroTelephone);
      final favoris = await getAllNumerosFavoris(clientId);
      return favoris.any((favori) => favori.numeroTelephone == formattedNumber);
    } catch (e) {
      print('❌ Erreur vérification favori: $e');
      return false;
    }
  }
}