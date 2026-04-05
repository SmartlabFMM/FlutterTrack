import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

// ── Modèle public ─────────────────────────────────────────────
class HabitItem {
  final String       title;
  final String       subtitle;
  final String       tip;
  final IconData     icon;
  final List<Color>  gradient;
  final Color        accent;   // couleur foncée pour le texte
  final String       category;
  final List<String> details;

  const HabitItem({
    required this.title,
    required this.subtitle,
    required this.tip,
    required this.icon,
    required this.gradient,
    required this.accent,
    required this.category,
    required this.details,
  });
}

// ── Données ───────────────────────────────────────────────────
const kHabits = [
  HabitItem(
    title: 'Sommeil régulier',
    subtitle: '7 à 9h par nuit',
    tip: 'Le manque de sommeil est le déclencheur #1 des crises',
    icon: Icons.bedtime_rounded,
    gradient: [Color(0xFFEEE6FF), Color(0xFFDDD0F8)],
    accent: Color(0xFF6B4FA8),
    category: 'Sommeil',
    details: [
      'Se coucher et se lever à la même heure chaque jour',
      'Éviter les écrans 1h avant le coucher',
      'Maintenir une chambre fraîche (18-20°C)',
      'Pas de caféine après 15h',
      "Un rituel de relaxation aide à s'endormir",
    ],
  ),
  HabitItem(
    title: 'Médicaments',
    subtitle: 'Prise à heure fixe',
    tip: 'Ne jamais sauter une dose — réduit la protection',
    icon: Icons.medication_rounded,
    gradient: [Color(0xFFFFFBD0), Color(0xFFFFF3A0)],
    accent: Color(0xFF8A6F00),
    category: 'Traitement',
    details: [
      'Programmer une alarme quotidienne',
      'Utiliser un pilulier hebdomadaire',
      'Ne jamais arrêter sans avis médical',
      'Signaler tout effet secondaire au médecin',
      'Emporter le médicament en voyage',
    ],
  ),
  HabitItem(
    title: 'Gestion du stress',
    subtitle: 'Respiration & relaxation',
    tip: 'Le stress chronique amplifie le risque de crise',
    icon: Icons.self_improvement_rounded,
    gradient: [Color(0xFFDDEEFF), Color(0xFFC4DCFA)],
    accent: Color(0xFF2A5BAA),
    category: 'Mental',
    details: [
      '5 min de respiration profonde matin et soir',
      'Pratiquer la méditation ou le yoga',
      'Identifier et éviter les situations de stress',
      'Partager ses inquiétudes avec un proche',
      'Consulter un psychologue si besoin',
    ],
  ),
  HabitItem(
    title: 'Exercice adapté',
    subtitle: '30 min/jour modéré',
    tip: "L'exercice réduit le stress et améliore le sommeil",
    icon: Icons.directions_walk_rounded,
    gradient: [Color(0xFFD8F5E0), Color(0xFFB8EAC8)],
    accent: Color(0xFF1E7A45),
    category: 'Activité',
    details: [
      'Marche, natation ou vélo sont idéaux',
      "Toujours prévenir l'accompagnant",
      'Éviter les sports à risque de chute seul',
      "S'hydrater correctement pendant l'effort",
      'Ne pas faire de sport trop tard le soir',
    ],
  ),
  HabitItem(
    title: 'Hydratation',
    subtitle: "1,5 L d'eau/jour",
    tip: 'La déshydratation peut déclencher une crise',
    icon: Icons.water_drop_rounded,
    gradient: [Color(0xFFFFE8F2), Color(0xFFFFCCE4)],
    accent: Color(0xFFA03070),
    category: 'Alimentation',
    details: [
      'Boire régulièrement sans attendre la soif',
      'Augmenter l\'apport en cas de chaleur',
      'Éviter les boissons alcoolisées',
      'Limiter les boissons sucrées et caféinées',
      "Une bouteille d'eau à portée de main",
    ],
  ),
  HabitItem(
    title: 'Alimentation',
    subtitle: 'Repas équilibrés',
    tip: 'Les repas sautés peuvent provoquer une hypoglycémie',
    icon: Icons.restaurant_rounded,
    gradient: [Color(0xFFFFEDD8), Color(0xFFFFDAB4)],
    accent: Color(0xFFB05A10),
    category: 'Alimentation',
    details: [
      'Ne jamais sauter de repas',
      'Privilégier les sucres lents (céréales, légumineuses)',
      'Augmenter les oméga-3 (poissons gras, noix)',
      'Réduire la caféine et les aliments ultra-transformés',
      'Régime cétogène possible sur avis médical',
    ],
  ),
  HabitItem(
    title: "Éviter l'alcool",
    subtitle: 'Risque élevé de crise',
    tip: "L'alcool interfère avec les médicaments antiépileptiques",
    icon: Icons.no_drinks_rounded,
    gradient: [Color(0xFFFFE8F2), Color(0xFFFFCCE4)],
    accent: Color(0xFFA03070),
    category: 'Éviter',
    details: [
      "L'alcool abaisse le seuil épileptique",
      '1 verre peut interagir avec les médicaments',
      'Le sevrage alcoolique est aussi dangereux',
      'Informer les amis pour éviter la pression sociale',
      'Des boissons sans alcool festives existent',
    ],
  ),
  HabitItem(
    title: 'Lumières & écrans',
    subtitle: 'Photosensibilité',
    tip: 'Concerne ~3% des épileptiques — vérifier avec le médecin',
    icon: Icons.lightbulb_rounded,
    gradient: [Color(0xFFEEE6FF), Color(0xFFDDD0F8)],
    accent: Color(0xFF6B4FA8),
    category: 'Environnement',
    details: [
      'Utiliser le mode sombre sur les écrans',
      'Porter des lunettes polarisantes si sensible',
      'Éviter les jeux vidéo en cas de photosensibilité',
      "Tenir l'écran à au moins 50 cm",
      'Faire des pauses régulières (règle 20-20-20)',
    ],
  ),
];

const kHabitCategories = [
  'Tous', 'Sommeil', 'Traitement', 'Mental',
  'Activité', 'Alimentation', 'Éviter', 'Environnement'
];

// ── Carte habitude partagée ────────────────────────────────────
class HabitCard extends StatefulWidget {
  final HabitItem   habit;
  final bool        isChecked;
  final VoidCallback onToggle;
  const HabitCard({super.key,
    required this.habit, required this.isChecked, required this.onToggle});
  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _anim;
  late Animation<double>   _expandAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300));
    _expandAnim = CurvedAnimation(parent: _anim, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _anim.forward() : _anim.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final habit  = widget.habit;
    final grad   = habit.gradient;
    final accent = habit.accent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: widget.isChecked
          ? grad.first.withValues(alpha: 0.35) : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isChecked
            ? accent.withValues(alpha: 0.40) : AppColors.cardBorder,
          width: widget.isChecked ? 1.5 : 1),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 16, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(children: [
        GestureDetector(
          onTap: _toggle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: grad),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.18),
                      blurRadius: 12, offset: const Offset(0, 4)),
                  ]),
                child: Icon(habit.icon, color: accent, size: 26)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit.title,
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: widget.isChecked
                          ? accent : AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    Text(habit.subtitle,
                      style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
                    const SizedBox(height: 5),
                    Row(children: [
                      Icon(Icons.lightbulb_outline_rounded,
                        size: 11, color: accent),
                      const SizedBox(width: 4),
                      Expanded(child: Text(habit.tip,
                        style: TextStyle(
                          fontSize: 11, color: accent,
                          fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: widget.onToggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        gradient: widget.isChecked
                          ? LinearGradient(colors: grad) : null,
                        color: widget.isChecked ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.isChecked
                            ? accent : AppColors.cardBorder,
                          width: 2)),
                      child: widget.isChecked
                        ? Icon(Icons.check_rounded, color: accent, size: 16)
                        : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textHint, size: 20)),
                ],
              ),
            ]),
          ),
        ),

        SizeTransition(
          sizeFactor: _expandAnim,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Divider(
                height: 1, thickness: 0.8,
                color: accent.withValues(alpha: 0.15)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: grad.first.withValues(alpha: 0.60),
                      borderRadius: BorderRadius.circular(20)),
                    child: Text(habit.category,
                      style: TextStyle(fontSize: 11,
                        fontWeight: FontWeight.w700, color: accent)),
                  ),
                ),
                const SizedBox(height: 12),
                ...habit.details.asMap().entries.map((e) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: grad.first.withValues(alpha: 0.70),
                            borderRadius: BorderRadius.circular(6)),
                          child: Center(child: Text('${e.key + 1}',
                            style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800,
                              color: accent)))),
                        const SizedBox(width: 10),
                        Expanded(child: Text(e.value,
                          style: const TextStyle(
                            fontSize: 13, color: AppColors.textPrimary,
                            height: 1.4))),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}
