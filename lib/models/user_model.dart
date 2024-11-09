import 'dart:convert';

class User {
  final String? id;
  final String numeroTelephone;
  final String nomComplet;
  final String? email;
  final String password;
  final String? codeQr;
  final double solde;
  final bool estActif;
  final String typeNotification;

  User({
    this.id,
    required this.numeroTelephone,
    required this.nomComplet,
    this.email,
    required this.password,
    this.codeQr,
    this.solde = 0.0,
    this.estActif = false,
    this.typeNotification = 'EMAIL',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString(),
      numeroTelephone: json['numeroTelephone'],
      nomComplet: json['nomComplet'],
      email: json['email'],
      password: json['password'],
      codeQr: json['codeQr'],
      solde: (json['solde'] is num) ? (json['solde'] as num).toDouble() : 0.0,
      estActif: json['estActif'] ?? false,
      typeNotification: json['typeNotification'] ?? 'EMAIL',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numeroTelephone': numeroTelephone,
      'nomComplet': nomComplet,
      'email': email,
      'password': password,
      'codeQr': codeQr,
      'solde': solde,
      'estActif': estActif,
      'typeNotification': typeNotification,
    };
  }

  User copyWith({
    String? id,
    String? numeroTelephone,
    String? nomComplet,
    String? email,
    String? password,
    String? codeQr,
    double? solde,
    bool? estActif,
    String? typeNotification,
  }) {
    return User(
      id: id ?? this.id,
      numeroTelephone: numeroTelephone ?? this.numeroTelephone,
      nomComplet: nomComplet ?? this.nomComplet,
      email: email ?? this.email,
      password: password ?? this.password,
      codeQr: codeQr ?? this.codeQr,
      solde: solde ?? this.solde,
      estActif: estActif ?? this.estActif,
      typeNotification: typeNotification ?? this.typeNotification,
    );
  }
}
