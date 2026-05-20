import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/habits_provider.dart';
import '../../providers/auth_provider.dart';

const _stressLabels = ['Aucun', 'Léger', 'Modéré', 'Élevé', 'Très élevé'];
const _stressColors = [
  Color(0xFF10B981),
  Color(0xFF84CC16),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFF7C3AED),
];

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});
  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  bool _saving = false;

  Future<void> _save() async {
    final user = ref.read(authProvider).user;
    final uid  = user?.linkedPatientId ?? user?.uid ?? '';
    if (uid.isEmpty) return;
    setState(() => _saving = true);
    final ok = await ref.read(habitsProvider.notifier).save(uid);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
          ? 'Habitudes enregistrées !'
          : 'Erreur lors de l\'enregistrement.'),
        backgroundColor: ok ? AppColors.primaryDark : AppColors.danger,
      ));
      if (ok) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitsProvider);
    final n      = ref.read(habitsProvider.notifier);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(children: [
          _buildHero(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _StressCard(
                  value:     habits.stress,
                  onChanged: n.setStress,
                ),
                const SizedBox(height: 12),
                _NumericCard(
                  icon:      Icons.bedtime_rounded,
                  title:     'Heures de sommeil',
                  subtitle:  'Durée de la nuit dernière',
                  value:     habits.sommeil,
                  unit:      'h',
                  max:       12,
                  step:      0.5,
                  gradient:  const [Color(0xFFEEE6FF), Color(0xFFDDD0F8)],
                  accent:    const Color(0xFF6B4FA8),
                  onChanged: n.setSommeil,
                ),
                const SizedBox(height: 12),
                _NumericCard(
                  icon:      Icons.water_drop_rounded,
                  title:     'Hydratation',
                  subtitle:  "Eau bue aujourd'hui",
                  value:     habits.hydratation,
                  unit:      'L',
                  max:       3.0,
                  step:      0.5,
                  gradient:  const [Color(0xFFD6F0FF), Color(0xFFB3E4FA)],
                  accent:    const Color(0xFF1A7AAA),
                  onChanged: n.setHydratation,
                ),
                const SizedBox(height: 12),
                _CheckCard(
                  icon:     Icons.medication_rounded,
                  title:    'Médicaments pris',
                  subtitle: 'Prise à heure fixe aujourd\'hui',
                  gradient: const [Color(0xFFFFFBD0), Color(0xFFFFF3A0)],
                  accent:   const Color(0xFF8A6F00),
                  value:    habits.medicaments,
                  onToggle: n.toggleMedicaments,
                ),
                const SizedBox(height: 12),
                _CheckCard(
                  icon:     Icons.directions_walk_rounded,
                  title:    'Sport / Activité physique',
                  subtitle: 'Activité physique réalisée aujourd\'hui',
                  gradient: const [Color(0xFFD8F5E0), Color(0xFFB8EAC8)],
                  accent:   const Color(0xFF1E7A45),
                  value:    habits.sport,
                  onToggle: n.toggleSport,
                ),
                const SizedBox(height: 12),
                _CheckCard(
                  icon:     Icons.no_drinks_rounded,
                  title:    'Alcool consommé',
                  subtitle: 'Consommation d\'alcool aujourd\'hui',
                  gradient: const [Color(0xFFFFE8E8), Color(0xFFFFCCCC)],
                  accent:   const Color(0xFFB03030),
                  value:    habits.alcool,
                  onToggle: n.toggleAlcool,
                ),
                const SizedBox(height: 24),
                _SaveButton(saving: _saving, onSave: _save),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final now    = DateTime.now();
    const months = ['Jan','Fév','Mar','Avr','Mai','Jun',
                    'Jul','Aoû','Sep','Oct','Nov','Déc'];
    final date = '${now.day} ${months[now.month - 1]}';

    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradientPatient,
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(32),
          bottomRight: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Row(children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2))),
                child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20)),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Habitudes de vie',
                style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800,
                  color: Colors.white)),
              Text('Suivi quotidien',
                style: TextStyle(
                  fontSize: 12, color: Colors.white.withValues(alpha: 0.72))),
            ]),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                const Icon(Icons.today_rounded, color: Colors.white, size: 13),
                const SizedBox(width: 4),
                Text(date,
                  style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: Colors.white)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Carte Stress (slider) ─────────────────────────────────────
class _StressCard extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _StressCard({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final idx   = value.round().clamp(0, 4);
    final label = _stressLabels[idx];
    final color = _stressColors[idx];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 16, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFFDDEEFF), Color(0xFFC4DCFA)]),
              borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.self_improvement_rounded,
              color: Color(0xFF2A5BAA), size: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Niveau de stress',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              const Text('Stress ressenti aujourd\'hui',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20)),
            child: Text(label,
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ),
        ]),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor:   color,
            inactiveTrackColor: color.withValues(alpha: 0.15),
            thumbColor:         color,
            overlayColor:       color.withValues(alpha: 0.12),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            trackHeight: 6,
          ),
          child: Slider(
            value:     value,
            min: 0, max: 4,
            divisions: 4,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _stressLabels.map((l) => Text(l,
            style: const TextStyle(
              fontSize: 9, color: AppColors.textHint,
              fontWeight: FontWeight.w500))).toList(),
        ),
      ]),
    );
  }
}

// ── Carte numérique (sommeil, hydratation) ────────────────────
class _NumericCard extends StatelessWidget {
  final IconData     icon;
  final String       title;
  final String       subtitle;
  final double       value;
  final String       unit;
  final double       max;
  final double       step;
  final List<Color>  gradient;
  final Color        accent;
  final ValueChanged<double> onChanged;

  const _NumericCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.unit,
    required this.max,
    required this.step,
    required this.gradient,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final display = step < 1
      ? value.toStringAsFixed(1)
      : value.toInt().toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.06),
            blurRadius: 16, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: gradient),
            borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: accent, size: 24)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
        const SizedBox(width: 12),
        Row(children: [
          _StepButton(
            icon:  Icons.remove_rounded,
            color: accent,
            onTap: () {
              final next = (value - step).clamp(0, max);
              if (next != value) onChanged(next.toDouble());
            },
          ),
          SizedBox(
            width: 72,
            child: Text(
              '$display $unit',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: accent)),
          ),
          _StepButton(
            icon:  Icons.add_rounded,
            color: accent,
            onTap: () {
              final next = (value + step).clamp(0, max);
              if (next != value) onChanged(next.toDouble());
            },
          ),
        ]),
      ]),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final VoidCallback onTap;
  const _StepButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25))),
      child: Icon(icon, size: 18, color: color),
    ),
  );
}

// ── Carte case à cocher ───────────────────────────────────────
class _CheckCard extends StatelessWidget {
  final IconData     icon;
  final String       title;
  final String       subtitle;
  final List<Color>  gradient;
  final Color        accent;
  final bool         value;
  final VoidCallback onToggle;

  const _CheckCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.accent,
    required this.value,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onToggle,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value
          ? gradient.first.withValues(alpha: 0.30)
          : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value ? accent.withValues(alpha: 0.35) : AppColors.cardBorder,
          width: value ? 1.5 : 1),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.06),
            blurRadius: 16, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: gradient),
            borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: accent, size: 24)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
              style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: value ? accent : AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle,
              style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
        const SizedBox(width: 12),
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: value ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: value ? accent : AppColors.cardBorder, width: 2)),
          child: value
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
            : null,
        ),
      ]),
    ),
  );
}

// ── Bouton Enregistrer ────────────────────────────────────────
class _SaveButton extends StatelessWidget {
  final bool         saving;
  final VoidCallback onSave;
  const _SaveButton({required this.saving, required this.onSave});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: saving ? null : onSave,
    child: Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradientPatient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Center(
        child: saving
          ? const SizedBox(
              width: 22, height: 22,
              child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2.5))
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Enregistrer',
                  style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: Colors.white)),
              ],
            ),
      ),
    ),
  );
}
