import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';
import '../models/user_model.dart';
import 'api_config.dart';
import 'api_service.dart';
import 'user_service.dart';

class TransactionService {
  final String baseUrl = ApiConfig.baseUrl;
  final UserService _userService;
  
  // StreamController pour les notifications
  static final _transactionStreamController = StreamController<void>.broadcast();
  static Stream<void> get onTransactionCompleted => _transactionStreamController.stream;

  TransactionService() : _userService = UserService(ApiService());

  // Méthode pour notifier les observateurs
  void _notifyTransactionCompleted() {
    // print('🔄 Notification de mise à jour émise');
    _transactionStreamController.add(null);
  }

  // Formatage des numéros de téléphone
  String _formatPhoneNumber(String phoneNumber) {
    String cleanNumber = phoneNumber.replaceAll(' ', '');
    
    if (cleanNumber.startsWith('+221')) {
      return cleanNumber;
    }
    
    if (cleanNumber.startsWith('221')) {
      return '+$cleanNumber';
    }
    
    if (cleanNumber.startsWith('7')) {
      return '+221$cleanNumber';
    }
    
    throw Exception('Format de numéro de téléphone invalide. Le numéro doit commencer par 7 ou +221 ou 221');
  }

  // Récupération des transactions
  Future<List<Transaction>> getMyTransactions() async {
    try {
      // print('📋 Récupération des transactions...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/my-transactions'),
        headers: await ApiConfig.getAuthHeaders(),
      );

      // print('📥 Status: ${response.statusCode}');
      // print('📥 Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse['data'] == null) {
          return [];
        }

        final List<dynamic> transactionsData = jsonResponse['data'] is List 
          ? jsonResponse['data'] 
          : [jsonResponse['data']];

        final transactions = transactionsData.map((json) {
          try {
            return Transaction.fromJson(json);
          } catch (e) {
            print('❌ Erreur parsing: $e');
            print('🔍 JSON problématique: $json');
            throw Exception('Erreur de parsing: $e');
          }
        }).toList();

        _notifyTransactionCompleted();
        return transactions;

      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception(
          errorResponse['message'] ?? 
          errorResponse['data'] ?? 
          'Erreur lors de la récupération des transactions'
        );
      }
    } catch (e) {
      print('❌ Erreur service: $e');
      rethrow;
    }
  }

  // Transfert simple
Future<Transaction> transferMoney({
  required String recipientPhone,
  required double amount,
}) async {
  try {
    final currentUser = await _userService.getCurrentUser();
    if (currentUser == null) {
      throw Exception('Aucun utilisateur connecté');
    }

    String formattedRecipientPhone;
    String senderPhone;
    
    try {
      formattedRecipientPhone = _formatPhoneNumber(recipientPhone);
      senderPhone = _formatPhoneNumber(currentUser.numeroTelephone);
      
      print('📱 Validation des numéros:');
      print('- Numéro destinataire: $formattedRecipientPhone');
      print('- Numéro expéditeur: $senderPhone');
    } catch (e) {
      throw Exception('Numéro de téléphone invalide: $e');
    }

    if (formattedRecipientPhone == senderPhone) {
      throw Exception('Vous ne pouvez pas transférer de l\'argent à vous-même');
    }

    print('\n💰 Transfert: $amount FCFA de $senderPhone vers $formattedRecipientPhone');

    final response = await http.post(
      Uri.parse('$baseUrl/transactions/transfer'),
      headers: {
        ...await ApiConfig.getAuthHeaders(),
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'senderPhoneNumber': senderPhone,
        'recipientPhoneNumber': formattedRecipientPhone,
        'amount': amount,
      }),
    );

    print('📥 Status: ${response.statusCode}');
    print('📥 Response: ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      
      if (jsonResponse['data'] == null) {
        throw Exception('Données invalides');
      }

      final transaction = Transaction.fromJson(jsonResponse['data']);
      _notifyTransactionCompleted();
      return transaction;

    } else {
      final errorResponse = json.decode(response.body);
      String message = errorResponse['message'] ?? errorResponse['data'] ?? '';

      // Vérifier si c'est une erreur de solde insuffisant
      if (message.toLowerCase().contains('solde insuffisant')) {
        // Extraire les montants de l'erreur
        RegExp regExp = RegExp(r'Nécessaire: (\d+\.\d+), Disponible: (\d+\.\d+)');
        var match = regExp.firstMatch(message);
        
        if (match != null) {
          double necessaire = double.parse(match.group(1)!);
          double disponible = double.parse(match.group(2)!);
          
          throw Exception(
            'Solde insuffisant pour effectuer le transfert.\n'
            'Montant nécessaire: ${necessaire.toStringAsFixed(0)} FCFA\n'
            'Solde disponible: ${disponible.toStringAsFixed(0)} FCFA'
          );
        } else {
          throw Exception(
            'Solde insuffisant pour effectuer le transfert de ${amount.toStringAsFixed(0)} FCFA\n'
            'Veuillez vérifier votre solde et réessayer.'
          );
        }
      }
      
      // Vérifier si c'est une erreur de destinataire introuvable
      if (message.toLowerCase().contains('destinataire non trouvé') ||
          message.toLowerCase().contains('utilisateur non trouvé')) {
        throw Exception(
          'Le numéro $formattedRecipientPhone n\'est pas inscrit sur la plateforme'
        );
      }
      
      // Pour les autres types d'erreurs
      throw Exception(message.isEmpty ? 'Erreur lors du transfert' : message);
    }
  } catch (e) {
    print('❌ Erreur: $e');
    rethrow;
  }
}

  // Transfert multiple
Future<List<Transaction>> transferMultiple({
  required List<String> recipientPhoneNumbers,
  required double amount,
}) async {
  try {
    final currentUser = await _userService.getCurrentUser();
    if (currentUser == null) {
      throw Exception('Aucun utilisateur connecté');
    }

    String senderPhone = _formatPhoneNumber(currentUser.numeroTelephone);

    // Formater tous les numéros
    final formattedRecipientNumbers = recipientPhoneNumbers.map((phone) {
      try {
        return _formatPhoneNumber(phone);
      } catch (e) {
        throw Exception('Numéro invalide ($phone): ${e.toString()}');
      }
    }).toList();

    // Vérifier si l'expéditeur est dans la liste
    if (formattedRecipientNumbers.contains(senderPhone)) {
      throw Exception('Vous ne pouvez pas vous inclure dans les destinataires');
    }

    print('📱 Transfert groupé:');
    print('- Expéditeur: $senderPhone');
    print('- Destinataires: $formattedRecipientNumbers');
    print('- Montant par personne: $amount FCFA');

    final response = await http.post(
      Uri.parse('$baseUrl/transactions/transfer/multiple'),
      headers: {
        ...await ApiConfig.getAuthHeaders(),
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'senderPhoneNumber': senderPhone,
        'recipientPhoneNumbers': formattedRecipientNumbers,
        'amount': amount,
      }),
    );

    print('📥 Status: ${response.statusCode}');
    print('📥 Response: ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['data'] == null) {
        return [];
      }

      final transactionsData = jsonResponse['data'] is List 
        ? jsonResponse['data'] 
        : [jsonResponse['data']];

      final transactions = transactionsData.map((json) => 
        Transaction.fromJson(json)
      ).toList();

      _notifyTransactionCompleted();
      return transactions;

    } else {
      final errorResponse = json.decode(response.body);
      
      // Vérifier si c'est une erreur de solde insuffisant
      String message = errorResponse['message'] ?? errorResponse['data'] ?? '';
      if (message.toLowerCase().contains('solde insuffisant')) {
        // Extraire les montants de l'erreur
        RegExp regExp = RegExp(r'Nécessaire: (\d+\.\d+), Disponible: (\d+\.\d+)');
        var match = regExp.firstMatch(message);
        
        if (match != null) {
          double necessaire = double.parse(match.group(1)!);
          double disponible = double.parse(match.group(2)!);
          
          throw Exception(
            'Solde insuffisant pour effectuer les transferts.\n'
            'Montant nécessaire: ${necessaire.toStringAsFixed(0)} FCFA\n'
            'Solde disponible: ${disponible.toStringAsFixed(0)} FCFA'
          );
        } else {
          throw Exception('Solde insuffisant pour effectuer les transferts');
        }
      }
      
      // Pour les autres types d'erreurs
      throw Exception(message.isEmpty ? 'Erreur lors du transfert multiple' : message);
    }
  } catch (e) {
    print('❌ Erreur transfert multiple: $e');
    rethrow;
  }
}

  // Annulation de transaction
  Future<void> cancelTransaction(String transactionId) async {
    try {
      print('🔄 Annulation de la transaction: $transactionId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/transactions/cancel'),
        headers: {
          ...await ApiConfig.getAuthHeaders(),
          'Content-Type': 'application/json',
        },
        body: json.encode({'transactionId': transactionId}),
      );

      // print('📥 Status: ${response.statusCode}');
      // print('📥 Response: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Transaction annulée avec succès');
        _notifyTransactionCompleted();
      } else {
        final errorResponse = json.decode(response.body);
        final errorMessage = errorResponse['message'] ?? 
                           errorResponse['data'] ?? 
                           'Erreur lors de l\'annulation';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Erreur annulation: $e');
      rethrow;
    }
  }

  // Récupération d'une transaction par ID
  Future<Transaction> getTransactionById(String id) async {
    try {
      print('🔍 Recherche transaction: $id');
      
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/$id'),
        headers: await ApiConfig.getAuthHeaders(),
      );

      print('📥 Status: ${response.statusCode}');
      print('📥 Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return Transaction.fromJson(jsonResponse['data']);
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception(
          errorResponse['message'] ?? 
          errorResponse['data'] ?? 
          'Transaction non trouvée'
        );
      }
    } catch (e) {
      print('❌ Erreur recherche: $e');
      rethrow;
    }
  }

  // Rafraîchissement des transactions
  Future<void> refreshTransactions() async {
    await getMyTransactions();
  }

  // Nettoyage des ressources
  static void dispose() {
    _transactionStreamController.close();
  }
}