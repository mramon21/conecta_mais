enum EventCategory {
  musica('Música'),
  educacao('Educação'),
  gastronomia('Gastronomia'),
  esporte('Esporte'),
  arte('Arte'),
  tecnologia('Tecnologia'),
  entretenimento('Entretenimento'),
  bemEstar('Bem-estar');

  final String label;
  const EventCategory(this.label);

  static List<String> get allLabels => EventCategory.values.map((e) => e.label).toList();

  static EventCategory fromLabel(String label) {
    return EventCategory.values.firstWhere(
      (e) => e.label == label,
      orElse: () => EventCategory.entretenimento,
    );
  }
}
