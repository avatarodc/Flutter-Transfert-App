// lib/models/user_model.dart
class User {
  final String? id;
  final String nomComplet;
  final String email;
  final String telephone;
  final String password;

  User({
    this.id,
    required this.nomComplet,
    required this.email,
    required this.telephone,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'nom': nomComplet,
      'email': email,
      'telephone': telephone,
      'password': password,
    };
  }
}