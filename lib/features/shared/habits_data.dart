// Données de référence sur les habitudes épilepsie-friendly
// (utilisé pour référence interne — les écrans utilisent habits_provider.dart)

class HabitItem {
  final String       title;
  final String       subtitle;
  final String       tip;
  final String       category;
  final List<String> details;

  const HabitItem({
    required this.title,
    required this.subtitle,
    required this.tip,
    required this.category,
    required this.details,
  });
}

const kHabits = [
  HabitItem(
    title:    'Sommeil régulier',
    subtitle: '7 à 9h par nuit',
    tip:      'Le manque de sommeil est le déclencheur #1 des crises',
    category: 'Sommeil',
    details:  [
      'Se coucher et se lever à la même heure chaque jour',
      'Éviter les écrans 1h avant le coucher',
      'Maintenir une chambre fraîche (18-20°C)',
      'Pas de caféine après 15h',
    ],
  ),
  HabitItem(
    title:    'Médicaments',
    subtitle: 'Prise à heure fixe',
    tip:      'Ne jamais sauter une dose — réduit la protection',
    category: 'Traitement',
    details:  [
      'Programmer une alarme quotidienne',
      'Utiliser un pilulier hebdomadaire',
      'Ne jamais arrêter sans avis médical',
    ],
  ),
  HabitItem(
    title:    'Gestion du stress',
    subtitle: 'Respiration & relaxation',
    tip:      'Le stress chronique amplifie le risque de crise',
    category: 'Mental',
    details:  [
      '5 min de respiration profonde matin et soir',
      'Pratiquer la méditation ou le yoga',
      'Identifier et éviter les situations de stress',
    ],
  ),
  HabitItem(
    title:    'Exercice adapté',
    subtitle: '30 min/jour modéré',
    tip:      "L'exercice réduit le stress et améliore le sommeil",
    category: 'Activité',
    details:  [
      'Marche, natation ou vélo sont idéaux',
      "Toujours prévenir l'accompagnant",
      'Éviter les sports à risque de chute seul',
    ],
  ),
  HabitItem(
    title:    'Hydratation',
    subtitle: "1,5 L d'eau/jour",
    tip:      'La déshydratation peut déclencher une crise',
    category: 'Alimentation',
    details:  [
      'Boire régulièrement sans attendre la soif',
      'Augmenter l\'apport en cas de chaleur',
      'Éviter les boissons alcoolisées',
    ],
  ),
  HabitItem(
    title:    "Éviter l'alcool",
    subtitle: 'Risque élevé de crise',
    tip:      "L'alcool interfère avec les médicaments antiépileptiques",
    category: 'Éviter',
    details:  [
      "L'alcool abaisse le seuil épileptique",
      '1 verre peut interagir avec les médicaments',
      'Le sevrage alcoolique est aussi dangereux',
    ],
  ),
];
