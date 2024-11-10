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

  TransactionService() : _userService = UserService(ApiService());

  // Get My Transactions
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

        return transactionsData.map((json) {
          try {
            return Transaction.fromJson(json);
          } catch (e) {
            print('❌ Error parsing transaction: $e');
            print('🔍 Problematic JSON: $json');
            throw Exception('Erreur de parsing: $e');
          }
        }).toList();
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
    // Supprimer tous les espaces
    String cleanNumber = phoneNumber.replaceAll(' ', '');
    
    // Si le numéro commence déjà par +221, le retourner tel quel
    if (cleanNumber.startsWith('+221')) {
      return cleanNumber;
    }
    
    // Si le numéro commence par 221 sans +, ajouter le +
    if (cleanNumber.startsWith('221')) {
      return '+$cleanNumber';
    }
    
    // Si le numéro commence par un 7, ajouter +221
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
      // Récupérer l'utilisateur connecté
      final currentUser = await _userService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      // Formater les numéros de téléphone
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

      // Vérifier que l'utilisateur ne transfère pas à lui-même
      if (formattedRecipientPhone == senderPhone) {
        throw Exception('Vous ne pouvez pas transférer de l\'argent à vous-même');
      }

      // Logs détaillés avant le transfert
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

      print('📤 Request sent: ${json.encode(requestBody)}');

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

  // Multiple Transfers
Future<List<Transaction>> transferMultiple({
  required List<String> recipientPhoneNumbers,
  required double amount,
}) async {
  try {
    // Récupérer l'utilisateur connecté
    final currentUser = await _userService.getCurrentUser();
    if (currentUser == null) {
      throw Exception('Aucun utilisateur connecté');
    }

    // Formater le numéro de l'expéditeur
    String senderPhone = currentUser.numeroTelephone;
    if (!senderPhone.startsWith('+')) {
      senderPhone = '+221${currentUser.numeroTelephone}';
    }

    // Formater les numéros des destinataires
    final formattedRecipientNumbers = recipientPhoneNumbers.map((phone) {
      if (!phone.startsWith('+')) {
        return '+221$phone';
      }
      return phone;
    }).toList();

    // Vérifier qu'aucun destinataire n'est l'expéditeur
    if (formattedRecipientNumbers.contains(senderPhone)) {
      throw Exception('Vous ne pouvez pas transférer de l\'argent à vous-même');
    }

    // Préparer le corps de la requête
    final requestBody = {
      'senderPhoneNumber': senderPhone,
      'recipientPhoneNumbers': formattedRecipientNumbers,
      'amount': amount,
    };

    print('📤 Multiple transfer request: ${json.encode(requestBody)}');

    final response = await http.post(
      Uri.parse('$baseUrl/transactions/transfer/multiple'),
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
        return [];
      }

      final List<dynamic> transactionsData = jsonResponse['data'] is List 
        ? jsonResponse['data'] 
        : [jsonResponse['data']];

      return transactionsData.map((json) {
        try {
          return Transaction.fromJson(json);
        } catch (e) {
          print('❌ Error parsing transaction: $e');
          print('🔍 Problematic JSON: $json');
          throw Exception('Erreur lors du parsing des transactions');
        }
      }).toList();
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
    final response = await http.post(
      Uri.parse('$baseUrl/cancel'),
      body: json.encode({'transactionId': transactionId}),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode != 200) {
      throw Exception('Impossible d\'annuler la transaction');
    }
  }


Future<Transaction> getTransactionById(String id) async {
    print('Fetching transaction with ID: $id'); // Log avant l'appel HTTP
    final response = await http.get(Uri.parse('$baseUrl/$id'));

    if (response.statusCode == 200) {
      print('Transaction fetched successfully: ${response.body}'); // Log de succès
      return Transaction.fromJson(json.decode(response.body));
    } else {
      print('Failed to fetch transaction: ${response.statusCode}'); // Log d'erreur
      throw Exception('Transaction non trouvée');
    }
  }
 
}