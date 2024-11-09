import 'package:intl/intl.dart';
import '../models/user_model.dart';

extension UserExtensions on User {
  bool get isAdmin => typeNotification == 'ADMIN';
  bool get isAgent => typeNotification == 'AGENT';
  bool get isClient => typeNotification == 'CLIENT';

  String get formattedSolde {
    final formatter = NumberFormat.currency(
      symbol: 'FCFA',
      decimalDigits: 0,
      locale: 'fr_FR',
    );
    return formatter.format(solde);
  }
}