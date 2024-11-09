import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';
import 'api_config.dart';

class TransactionService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<List<Transaction>> getMyTransactions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/my-transactions'),
        headers: await ApiConfig.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        // Vérifier si la réponse contient une clé 'data'
        if (jsonResponse['data'] == null) {
          return [];
        }

        // S'assurer que nous avons une liste
        final List<dynamic> transactionsData = jsonResponse['data'] is List 
          ? jsonResponse['data'] 
          : [jsonResponse['data']];

        // Logger pour debug
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
}