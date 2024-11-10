enum Periodicity {
  JOURNALIER,
  HEBDOMADAIRE,
  MENSUEL;

  String toJson() => name;
  
  static Periodicity fromJson(String json) => 
    values.firstWhere((e) => e.name == json);
    
  String get libelle {
    switch (this) {
      case Periodicity.JOURNALIER:
        return 'Quotidien';
      case Periodicity.HEBDOMADAIRE:
        return 'Hebdomadaire';
      case Periodicity.MENSUEL:
        return 'Mensuel';
    }
  }
}