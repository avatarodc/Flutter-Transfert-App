import 'periodicity_model.dart';

class PlanificationTransfert {
  final String? id;
  final String expediteurTelephone;
  final String destinataireTelephone;
  final double montant;
  final Periodicity periodicite;
  final DateTime? prochaineExecution;
  bool estActif;
  final String? referenceGroupe;
  final String? heureExecution; 

  PlanificationTransfert({
    this.id,
    required this.expediteurTelephone,
    required this.destinataireTelephone,
    required this.montant,
    required this.periodicite,
    this.prochaineExecution,
    this.estActif = true,
    this.referenceGroupe,
    this.heureExecution,
  });

  Map<String, dynamic> toJson() {
    return {
      "expediteurTelephone": expediteurTelephone,
      "destinataireTelephone": destinataireTelephone,
      "montant": montant,
      "periodicite": periodicite.name,
      "referenceGroupe": referenceGroupe ?? DateTime.now().millisecondsSinceEpoch.toString(),
      "heureExecution": heureExecution,  
    };
  }

  factory PlanificationTransfert.fromJson(Map<String, dynamic> json) {
    return PlanificationTransfert(
      id: json['id']?.toString(),
      expediteurTelephone: json['expediteurTelephone'],
      destinataireTelephone: json['destinataireTelephone'],
      montant: (json['montant'] as num).toDouble(),
      periodicite: Periodicity.fromJson(json['periodicite']),
      prochaineExecution: json['prochaineExecution'] != null 
        ? DateTime.parse(json['prochaineExecution']) 
        : null,
      estActif: json['estActif'] ?? true,
      referenceGroupe: json['referenceGroupe'],
      heureExecution: json['heureExecution'],  // Directly use the string format "HH:mm"
    );
  }
}
