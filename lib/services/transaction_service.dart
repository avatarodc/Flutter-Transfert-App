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
    print('🔄 Notification de mise à jour émise');
    _transactionStreamController.add(null);
  }

  Future<List<Transaction>> getMyTransactions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/my-transactions'),
        headers: await ApiConfig.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse['data'] == null) {
          return [];
        }

        final List<dynamic> transactionsData = jsonResponse['data'] is List 
          ? jsonResponse['data'] 
          : [jsonResponse['data']];

        print('📦 Transactions data: $transactionsData');

        final transactions = transactionsData.map((json) {
          try {
            return Transaction.fromJson(json);
          } catch (e) {
            print('❌ Error parsing transaction: $e');
            print('🔍 Problematic JSON: $json');
            throw Exception('Erreur de parsing: $e');
          }
        }).toList();

        _notifyTransactionCompleted(); // Notifier après récupération réussie
        return transactions;

      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('📦 Response body: ${response.body}');
        throw Exception('Erreur lors de la récupération des transactions');
      }
    } catch (e) {
      print('❌ Service error: $e');
      throw Exception('Impossible de récupérer les transactions: $e');
    }
  }

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
        print('- Numéro original destinataire: $recipientPhone');
        print('- Numéro formaté destinataire: $formattedRecipientPhone');
        print('- Numéro original expéditeur: ${currentUser.numeroTelephone}');
        print('- Numéro formaté expéditeur: $senderPhone');
        
      } catch (e) {
        print('❌ Erreur de formatage des numéros: $e');
        throw Exception('Numéro de téléphone invalide: $e');
      }

      if (formattedRecipientPhone == senderPhone) {
        throw Exception('Vous ne pouvez pas transférer de l\'argent à vous-même');
      }

      print('\n🔄 Détails du transfert:');
      print('👤 Expéditeur: ${currentUser.nomComplet}');
      print('📱 Numéro expéditeur: $senderPhone');
      print('👥 Destinataire: Numéro $formattedRecipientPhone');
      print('💰 Montant: $amount FCFA\n');

      final requestBody = {
        'senderPhoneNumber': senderPhone,
        'recipientPhoneNumber': formattedRecipientPhone,
        'amount': amount,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/transactions/transfer'),
        headers: {
          ...await ApiConfig.getAuthHeaders(),
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse['data'] == null) {
          throw Exception('Données de transaction invalides');
        }

        try {
          final transaction = Transaction.fromJson(jsonResponse['data']);
          print('\n✅ Transfert réussi!');
          print('📋 ID Transaction: ${transaction.id}');
          print('💰 Montant: ${transaction.amount} FCFA');
          print('📱 De: $senderPhone');
          print('📱 Vers: $formattedRecipientPhone\n');

          _notifyTransactionCompleted(); // Notifier après transfert réussi
          return transaction;
          
        } catch (e) {
          print('❌ Error parsing transaction: $e');
          print('🔍 Problematic JSON: ${jsonResponse['data']}');
          throw Exception('Erreur lors du traitement de la transaction');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else if (response.statusCode == 400) {
        final errorResponse = json.decode(response.body);
        throw Exception(errorResponse['message'] ?? errorResponse['data'] ?? 'Données invalides');
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('📦 Response body: ${response.body}');
        final errorResponse = json.decode(response.body);
        throw Exception(errorResponse['data'] ?? errorResponse['message'] ?? 'Erreur lors du transfert');
      }
    } catch (e) {
      print('❌ Transfer error: $e');
      rethrow;
    }
  }

  Future<List<Transaction>> transferMultiple({
    required List<String> recipientPhoneNumbers,
    required double amount,
  }) async {
    try {
      final currentUser = await _userService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      String senderPhone = currentUser.numeroTelephone;
      if (!senderPhone.startsWith('+')) {
        senderPhone = '+221${currentUser.numeroTelephone}';
      }

      final formattedRecipientNumbers = recipientPhoneNumbers.map((phone) {
        if (!phone.startsWith('+')) {
          return '+221$phone';
        }
        return phone;
      }).toList();

      if (formattedRecipientNumbers.contains(senderPhone)) {
        throw Exception('Vous ne pouvez pas transférer de l\'argent à vous-même');
      }

      final requestBody = {
        'senderPhoneNumber': senderPhone,
        'recipientPhoneNumbers': formattedRecipientNumbers,
        'amount': amount,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/transactions/transfer/multiple'),
        headers: {
          ...await ApiConfig.getAuthHeaders(),
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
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
            print('❌ Error parsing transaction: $e');
            print('🔍 Problematic JSON: $json');
            throw Exception('Erreur lors du parsing des transactions');
          }
        }).toList();

        _notifyTransactionCompleted(); // Notifier après transferts multiples réussis
        return transactions;

      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else if (response.statusCode == 400) {
        final errorResponse = json.decode(response.body);
        throw Exception(errorResponse['message'] ?? errorResponse['data'] ?? 'Données invalides');
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('📦 Response body: ${response.body}');
        final errorResponse = json.decode(response.body);
        throw Exception(errorResponse['message'] ?? errorResponse['data'] ?? 'Erreur lors des transferts multiples');
      }
    } catch (e) {
      print('❌ Multiple transfer error: $e');
      rethrow;
    }
  }

    Future<void> cancelTransaction(String transactionId) async {
      try {
        print('🔄 Tentative d\'annulation de la transaction: $transactionId');
        
        final requestBody = {
          'transactionId': transactionId
        };
        print('📤 Request body: $requestBody');
        
        final response = await http.post(
          Uri.parse('$baseUrl/transactions/cancel'),
          body: json.encode(requestBody),
          headers: {
            ...await ApiConfig.getAuthHeaders(),
            'Content-Type': 'application/json',
          },
        );
        
        print('📥 Response status: ${response.statusCode}');
        print('📥 Response body: ${response.body}');
        
        if (response.statusCode == 200) {
          print('✅ Transaction annulée avec succès');
          _notifyTransactionCompleted();
        } else {
          final errorResponse = json.decode(response.body);
          print('❌ Erreur HTTP: ${response.statusCode}');
          print('❌ Message d\'erreur: ${errorResponse['message'] ?? errorResponse['data'] ?? 'Aucun message'}');
          
          if (response.statusCode == 401) {
            throw Exception('Session expirée. Veuillez vous reconnecter.');
          } else if (response.statusCode == 400) {
            throw Exception(errorResponse['message'] ?? errorResponse['data'] ?? 'Requête invalide');
          } else {
            throw Exception(errorResponse['message'] ?? 
                          errorResponse['data'] ?? 
                          'Impossible d\'annuler la transaction (Code: ${response.statusCode})');
          }
        }
      } catch (e) {
        print('❌ Erreur lors de l\'annulation: $e');
        print('❌ Stack trace: ${StackTrace.current}');
        throw Exception('Erreur lors de l\'annulation de la transaction: $e');
      }
    }

  Future<Transaction> getTransactionById(String id) async {
    try {
      print('🔍 Fetching transaction with ID: $id');
      final response = await http.get(
        Uri.parse('$baseUrl/$id'),
        headers: await ApiConfig.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        print('✅ Transaction fetched successfully: ${response.body}');
        return Transaction.fromJson(json.decode(response.body));
      } else {
        print('❌ Failed to fetch transaction: ${response.statusCode}');
        throw Exception('Transaction non trouvée');
      }
    } catch (e) {
      print('❌ Get transaction error: $e');
      rethrow;
    }
  }

  // Méthode pour forcer un rafraîchissement
  Future<void> refreshTransactions() async {
    await getMyTransactions();
  }

  // Nettoyage des ressources
  static void dispose() {
    _transactionStreamController.close();
  }
}