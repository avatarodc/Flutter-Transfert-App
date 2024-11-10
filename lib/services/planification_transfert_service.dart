import 'dart:developer' as developer;
import 'api_service.dart';
import 'auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/planification_transfert_model.dart';
import '../models/user_model.dart';

class PlanificationTransfertService {
  final ApiService _apiService;
  final AuthService _authService;
  final storage = const FlutterSecureStorage();
  
  PlanificationTransfertService(this._apiService) : _authService = AuthService();

  // Créer une nouvelle planification
  Future<PlanificationTransfert> createPlanification(PlanificationTransfert planification) async {
    try {
      developer.log('📝 Création d\'une nouvelle planification: ${planification.toString()}', 
        name: 'PlanificationService');

      final isAuth = await _checkAuthentication();
      if (!isAuth) throw Exception('Non authentifié');

      final response = await _apiService.post('planification', planification.toJson());
      final nouvellePlanification = PlanificationTransfert.fromJson(response);
      developer.log('✅ Planification créée avec succès: ${nouvellePlanification.toString()}', 
        name: 'PlanificationService');
      
      return nouvellePlanification;
    } catch (e) {
      developer.log('❌ Erreur dans createPlanification()', 
        name: 'PlanificationService', error: e);
      throw Exception('Erreur lors de la création de la planification: $e');
    }
  }

  // Relancer une planification
  Future<void> relancerPlanification(String id) async {
    try {
      developer.log('🔄 Relance de la planification: $id', 
        name: 'PlanificationService');

      final isAuth = await _checkAuthentication();
      if (!isAuth) throw Exception('Non authentifié');

      await _apiService.post('planification/relancer/$id', {});
      developer.log('✅ Planification relancée avec succès', 
        name: 'PlanificationService');
    } catch (e) {
      developer.log('❌ Erreur dans relancerPlanification()', 
        name: 'PlanificationService', error: e);
      throw Exception('Erreur lors de la relance de la planification: $e');
    }
  }

  // Annuler une planification
  Future<void> annulerPlanification(String id) async {
    try {
      developer.log('🚫 Annulation de la planification: $id', 
        name: 'PlanificationService');

      final isAuth = await _checkAuthentication();
      if (!isAuth) throw Exception('Non authentifié');

      await _apiService.post('planification/annuler/$id', {});
      developer.log('✅ Planification annulée avec succès', 
        name: 'PlanificationService');
    } catch (e) {
      developer.log('❌ Erreur dans annulerPlanification()', 
        name: 'PlanificationService', error: e);
      throw Exception('Erreur lors de l\'annulation de la planification: $e');
    }
  }

  // Désactiver une planification
  Future<void> desactiverPlanification(String id) async {
    try {
      developer.log('⏸️ Désactivation de la planification: $id', 
        name: 'PlanificationService');

      final isAuth = await _checkAuthentication();
      if (!isAuth) throw Exception('Non authentifié');

      await _apiService.post('planification/desactiver/$id', {});
      developer.log('✅ Planification désactivée avec succès', 
        name: 'PlanificationService');
    } catch (e) {
      developer.log('❌ Erreur dans desactiverPlanification()', 
        name: 'PlanificationService', error: e);
      throw Exception('Erreur lors de la désactivation de la planification: $e');
    }
  }

  // Vérification de l'authentification
  Future<bool> _checkAuthentication() async {
    try {
      final token = await storage.read(key: AuthService.TOKEN_KEY);
      if (token == null) return false;

      final isValid = await _authService.isTokenValid();
      if (!isValid) {
        await _authService.logout();
        return false;
      }
      return true;
    } catch (e) {
      developer.log('❌ Erreur de vérification d\'authentification', 
        name: 'PlanificationService', error: e);
      return false;
    }
  }
}