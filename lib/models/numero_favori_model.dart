class NumeroFavori {
  final int? id;
  final int clientId; // ID de l'utilisateur (client)
  final String numeroTelephone;
  final String? nom;
  final DateTime dateAjout;

  NumeroFavori({
    this.id,
    required this.clientId,
    required this.numeroTelephone,
    this.nom,
    DateTime? dateAjout,
  }) : dateAjout = dateAjout ?? DateTime.now();

  // Création à partir d'un JSON
  factory NumeroFavori.fromJson(Map<String, dynamic> json) {
    return NumeroFavori(
      id: json['id'],
      clientId: json['client']?['id'] ?? json['clientId'], // Gestion des deux cas possibles
      numeroTelephone: json['numeroTelephone'],
      nom: json['nom'],
      dateAjout: json['dateAjout'] != null 
          ? DateTime.parse(json['dateAjout'])
          : DateTime.now(),
    );
  }

  // Conversion en JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'clientId': clientId,
      'numeroTelephone': numeroTelephone,
      if (nom != null) 'nom': nom,
      'dateAjout': dateAjout.toIso8601String(),
    };
  }

  // Copie avec modifications
  NumeroFavori copyWith({
    int? id,
    int? clientId,
    String? numeroTelephone,
    String? nom,
    DateTime? dateAjout,
  }) {
    return NumeroFavori(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      numeroTelephone: numeroTelephone ?? this.numeroTelephone,
      nom: nom ?? this.nom,
      dateAjout: dateAjout ?? this.dateAjout,
    );
  }

  // Override toString pour le débogage
  @override
  String toString() {
    return 'NumeroFavori{id: $id, clientId: $clientId, numeroTelephone: $numeroTelephone, nom: $nom, dateAjout: $dateAjout}';
  }

  // Override equals pour la comparaison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is NumeroFavori &&
      other.id == id &&
      other.clientId == clientId &&
      other.numeroTelephone == numeroTelephone &&
      other.nom == nom &&
      other.dateAjout == dateAjout;
  }

  // Override hashCode pour la comparaison
  @override
  int get hashCode {
    return id.hashCode ^
      clientId.hashCode ^
      numeroTelephone.hashCode ^
      nom.hashCode ^
      dateAjout.hashCode;
  }
}