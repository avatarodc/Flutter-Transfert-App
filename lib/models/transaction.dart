import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum TransactionType {
  TRANSFERT,
  DEPOT,
  RETRAIT,
  PAIEMENT_MARCHAND,
  ANNULE;

  String get label {
    switch (this) {
      case TransactionType.TRANSFERT:
        return 'Transfert';
      case TransactionType.DEPOT:
        return 'Dépôt';
      case TransactionType.RETRAIT:
        return 'Retrait';
      case TransactionType.PAIEMENT_MARCHAND:
        return 'Paiement marchand';
      case TransactionType.ANNULE:
        return 'Annulé';
    }
  }

  IconData get icon {
    switch (this) {
      case TransactionType.TRANSFERT:
        return Icons.swap_horiz;
      case TransactionType.DEPOT:
        return Icons.arrow_downward;
      case TransactionType.RETRAIT:
        return Icons.arrow_upward;
      case TransactionType.PAIEMENT_MARCHAND:
        return Icons.shopping_cart;
      case TransactionType.ANNULE:
        return Icons.cancel;
    }
  }

  Color get color {
    switch (this) {
      case TransactionType.TRANSFERT:
        return const Color(0xFF8E21F0);
      case TransactionType.DEPOT:
        return Colors.green;
      case TransactionType.RETRAIT:
        return Colors.orange;
      case TransactionType.PAIEMENT_MARCHAND:
        return Colors.blue;
      case TransactionType.ANNULE:
        return Colors.red;
    }
  }
}

class Transaction {
  final dynamic id;
  final TransactionType type;
  final String recipient;
  final String sender;
  final double amount;
  final String status;
  final String date;
  final double? fees;
  final String? reference;
  final String? motifAnnulation;
  final DateTime? dateAnnulation;
  final String? description;  // Ajouté pour le drawer

  Transaction({
    required this.id,
    required this.type,
    required this.recipient,
    required this.sender,
    required this.amount,
    required this.status,
    required this.date,
    this.fees,
    this.reference,
    this.motifAnnulation,
    this.dateAnnulation,
    this.description,
  });

  // Getter pour vérifier si la transaction peut être annulée
  bool get isCancleable {
    return status.toUpperCase() == 'EN_ATTENTE' && 
           type != TransactionType.ANNULE && 
           dateAnnulation == null;
  }

String get formattedDate {
  try {
    final dateTime = DateTime.parse(date);
    return DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(dateTime);
  } catch (e) {
    return date; 
  }
}


  String get formattedAmount {
    final numberFormat = NumberFormat.currency(
      symbol: 'FCFA',
      decimalDigits: 0,
      locale: 'fr_FR',
    );
    return numberFormat.format(amount);
  }

  String get statusFormatted {
    switch (status.toUpperCase()) {
      case 'EN_ATTENTE':
        return 'En attente';
      case 'TERMINE':
        return 'Terminé';
      case 'ANNULE':
        return 'Annulé';
      default:
        return status;
    }
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    print('🔄 Converting JSON to Transaction: $json');

    try {
      return Transaction(
        id: json['id'],
        type: _parseTransactionType(json['typeTransaction']),
        recipient: json['autrePartiePrenante']?.toString() ?? '',
        sender: json['estEmetteur'] == true 
            ? '' 
            : json['autrePartiePrenante']?.toString() ?? '',
        amount: _parseDouble(json['montant']),
        status: json['statut']?.toString() ?? 'EN_ATTENTE',
        date: json['dateCreation']?.toString() ?? '',
        fees: _parseDouble(json['fraisTransfert']),
        reference: json['referenceGroupe']?.toString(),
        motifAnnulation: json['motifAnnulation']?.toString(),
        dateAnnulation: json['dateAnnulation'] != null
            ? DateTime.parse(json['dateAnnulation'].toString())
            : null,
        description: json['description']?.toString(),
      );
    } catch (e) {
      print('❌ Error in Transaction.fromJson: $e');
      rethrow;
    }
  }

  static TransactionType _parseTransactionType(dynamic value) {
    if (value == null) return TransactionType.TRANSFERT;
    
    String typeStr = value.toString().toUpperCase();
    return TransactionType.values.firstWhere(
      (type) => type.name == typeStr,
      orElse: () => TransactionType.TRANSFERT,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}