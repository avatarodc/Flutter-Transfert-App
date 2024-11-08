class ApiConstants {
  static const String baseUrl = 'http://10.0.2.2:8080/api'; // Pour l'émulateur Android
  // static const String baseUrl = 'http://localhost:8080/api'; // Pour iOS
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  
  // User endpoints
  static const String userProfile = '/users/profile';
  static const String updateProfile = '/users/update';
  
  // Transaction endpoints
  static const String transactions = '/transactions';
  static const String transfer = '/transactions/transfer';
}