import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/sos_button.dart';
import '../../core/widgets/epitrack_logo.dart';
import '../../models/vital_signs_model.dart';
import '../../models/seizure_model.dart';
import '../../providers/ble_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/seizure_provider.dart';

// ── Données aperçu habitudes (dashboard) ─────────────────────
const _habitPreviews = [
  _HabitPreview('Sommeil\nrégulier', Icons.bedtime_rounded,
    [Color(0xFFEEE6FF), Color(0xFFDDD0F8)]),   // mauve pastel clair
  _HabitPreview('Médica-\nments', Icons.medication_rounded,
    [Color(0xFFFFFBD0), Color(0xFFFFF3A0)]),   // jaune pastel clair
  _HabitPreview('Gestion\nstress', Icons.self_improvement_rounded,
    [Color(0xFFDDEEFF), Color(0xFFC4DCFA)]),   // bleu pastel clair
  _HabitPreview('Exercice\nadapté', Icons.directions_walk_rounded,
    [Color(0xFFD8F5E0), Color(0xFFB8EAC8)]),   // vert pastel clair
  _HabitPreview('Hydra-\ntation', Icons.water_drop_rounded,
    [Color(0xFFFFE8F2), Color(0xFFFFCCE4)]),   // rose bébé clair
  _HabitPreview('Sans\nalcool', Icons.no_drinks_rounded,
    [Color(0xFFFFEDD8), Color(0xFFFFDAB4)]),   // orangé pastel clair
];

class _HabitPreview {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  const _HabitPreview(this.label, this.icon, this.gradient);
}

class PatientDashboardScreen extends ConsumerWidget {
  const PatientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ble    = ref.watch(bleProvider);
    final auth   = ref.watch(authProvider);
    final uid    = auth.user!.uid.toString();
    final latest = ref.watch(latestSeizureProvider(uid));
    final seizureList = ref.watch(seizureListProvider(uid));
    final firstName = auth.user!.name.split(' ').first;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          color: AppColors.primaryLight,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            ref.invalidate(latestSeizureProvider(uid));
            ref.invalidate(seizureListProvider(uid));
          },
          child: CustomScrollView(
            slivers: [

              // ── Hero section ────────────────────────────────
              SliverToBoxAdapter(
                child: _HeroBanner(
                  firstName: firstName,
                  initial: auth.user!.name.substring(0, 1).toUpperCase(),
                  batteryLevel: ble.batteryLevel,
                  isConnected: ble.status == BleStatus.connected,
                ),
              ),

              // ── Corps ────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // ── Statut bracelet ──────────────────────
                    _BraceletStatusCard(status: ble.status),
                    const SizedBox(height: 12),

                    // ── Vitaux rapides ───────────────────────
                    if (ble.latestVitals != null) ...[
                      _VitalsRow(vitals: ble.latestVitals!),
                      const SizedBox(height: 12),
                    ],

                    // ── Dernière crise ───────────────────────
                    latest.when(
                      data: (seizure) => seizure != null
                        ? _LastSeizureCard(seizure: seizure)
                        : const _NoSeizureCard(),
                      loading: () => const _SkeletonCard(height: 70),
                      error: (_, __) => const SizedBox(),
                    ),
                    const SizedBox(height: 20),

                    // ── Bouton SOS ───────────────────────────
                    const SosButton(),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(AppStrings.sosHold,
                        style: TextStyle(
                          fontSize: 12, color: AppColors.textHint))),
                    const SizedBox(height: 24),

                    // ── Raccourcis ───────────────────────────
                    const _SectionLabel('Accès rapide'),
                    const SizedBox(height: 10),
                    Row(children: [
                      _QuickAction(
                        icon: Icons.show_chart_rounded,
                        label: 'Signaux\nlive',
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight]),
                        onTap: () => context.go('/patient/signals'),
                      ),
                      const SizedBox(width: 10),
                      _QuickAction(
                        icon: Icons.history_rounded,
                        label: 'Historique\ncrises',
                        gradient: const LinearGradient(
                          colors: [AppColors.tealDark, AppColors.teal]),
                        onTap: () => context.go('/patient/history'),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // ── Score ML ce mois ─────────────────────
                    const _SectionLabel('Ce mois'),
                    const SizedBox(height: 10),
                    seizureList.when(
                      data: (list) => _MlScoreCard(seizures: list),
                      loading: () => const _SkeletonCard(height: 80),
                      error: (_, __) => const SizedBox(),
                    ),
                    const SizedBox(height: 24),

                    // ── Bonnes habitudes ──────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _SectionLabel('Bonnes habitudes'),
                        GestureDetector(
                          onTap: () => context.go('/patient/habits'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPale,
                              borderRadius: BorderRadius.circular(20)),
                            child: const Row(children: [
                              Text('Voir tout',
                                style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                              SizedBox(width: 3),
                              Icon(Icons.arrow_forward_rounded,
                                size: 13, color: AppColors.primary),
                            ]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _HabitsPreviewSection(
                      onTap: () => context.go('/patient/habits')),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hero Banner ─────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final String firstName, initial;
  final int    batteryLevel;
  final bool   isConnected;
  const _HeroBanner({
    required this.firstName, required this.initial,
    required this.batteryLevel, required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    final batteryColor = batteryLevel > 50 ? Colors.greenAccent
                       : batteryLevel > 20 ? Colors.amberAccent
                       : Colors.redAccent;
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
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar: avatar + batterie
              Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25))),
                  child: Center(child: Text(initial,
                    style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800,
                      color: Colors.white)))),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Bonjour, $firstName',
                    style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: Colors.white, fontFamily: 'Inter')),
                  Row(children: [
                    const EpiTrackLogoSmall(size: 18),
                    const SizedBox(width: 5),
                    Text(isConnected
                      ? 'Surveillance active'
                      : 'Bracelet déconnecté',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.72))),
                  ]),
                ]),
                const Spacer(),
                // Batterie
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25))),
                  child: Row(children: [
                    Icon(
                      batteryLevel > 60 ? Icons.battery_full_rounded
                      : batteryLevel > 30 ? Icons.battery_4_bar_rounded
                      : Icons.battery_alert_rounded,
                      size: 14, color: batteryColor),
                    const SizedBox(width: 4),
                    Text('$batteryLevel%',
                      style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: Colors.white)),
                  ]),
                ),
              ]),

              const SizedBox(height: 24),

              // Stats rapides
              Row(children: [
                _HeroStat(label: 'Bracelet',
                  value: isConnected ? 'Connecté' : 'Hors ligne',
                  icon: Icons.watch_rounded,
                  color: isConnected
                    ? Colors.greenAccent : Colors.redAccent.shade100),
                Container(
                  width: 1, height: 40,
                  color: Colors.white.withValues(alpha: 0.2),
                  margin: const EdgeInsets.symmetric(horizontal: 16)),
                _HeroStat(label: 'Protection',
                  value: 'Actif 24/7',
                  icon: Icons.shield_rounded,
                  color: Colors.lightBlueAccent),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _HeroStat({
    required this.label, required this.value,
    required this.icon, required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 16, color: color)),
    const SizedBox(width: 8),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(
        fontSize: 10, color: Colors.white.withValues(alpha: 0.65),
        fontWeight: FontWeight.w500)),
      Text(value, style: const TextStyle(
        fontSize: 13, color: Colors.white,
        fontWeight: FontWeight.w700)),
    ]),
  ]);
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w700,
      color: AppColors.textSecondary, letterSpacing: 0.3));
}

// ─── Statut bracelet ─────────────────────────────────────────
class _BraceletStatusCard extends StatelessWidget {
  final BleStatus status;
  const _BraceletStatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final connected = status == BleStatus.connected;
    final color = connected ? AppColors.teal : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: connected ? AppColors.tealPale : AppColors.dangerLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12)),
          child: Icon(
            connected
              ? Icons.bluetooth_connected_rounded
              : Icons.bluetooth_disabled_rounded,
            color: color, size: 22)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(connected
              ? AppStrings.braceletConn
              : AppStrings.braceletDisc,
              style: TextStyle(fontSize: 14,
                fontWeight: FontWeight.w700, color: color)),
            Text(connected
              ? 'Surveillance active — données en temps réel'
              : 'Appuyez pour reconnecter le bracelet',
              style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
        if (!connected)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(10)),
            child: const Text('Reconnecter',
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: Colors.white))),
      ]),
    );
  }
}

// ─── Raccourcis ──────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Gradient gradient;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label,
    required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 20)),
          const SizedBox(width: 10),
          Text(label,
            style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: Colors.white, height: 1.3)),
        ]),
      ),
    ),
  );
}

// ─── Pas de crise ─────────────────────────────────────────────
class _NoSeizureCard extends StatefulWidget {
  const _NoSeizureCard();
  @override
  State<_NoSeizureCard> createState() => _NoSeizureCardState();
}

class _NoSeizureCardState extends State<_NoSeizureCard> {
  bool _pulse = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _pulse = true);
    });
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.tealPale,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
      boxShadow: [
        BoxShadow(
          color: AppColors.teal.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4)),
      ],
    ),
    child: Row(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
        width: _pulse ? 40 : 32,
        height: _pulse ? 40 : 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.teal.withValues(alpha: _pulse ? 0.2 : 0.1)),
        onEnd: () { if (mounted) setState(() => _pulse = !_pulse); },
        child: Icon(Icons.check_circle_rounded,
          color: AppColors.teal, size: _pulse ? 22 : 18)),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(AppStrings.noSeizure,
          style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: AppColors.tealDark)),
        const Text('Aucune activité anormale détectée',
          style: TextStyle(
            fontSize: 12, color: AppColors.textSecondary)),
      ]),
    ]),
  );
}

class _SkeletonCard extends StatelessWidget {
  final double height;
  const _SkeletonCard({required this.height});
  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(16)));
}

// ─── Vitaux ───────────────────────────────────────────────────
class _VitalsRow extends StatelessWidget {
  final VitalSignsModel vitals;
  const _VitalsRow({required this.vitals});

  @override
  Widget build(BuildContext context) => Row(children: [
    _MiniVital(
      label: 'FC', value: '${vitals.heartRate}', unit: 'bpm',
      color: AppColors.heartColor, icon: Icons.favorite_rounded,
      alert: vitals.isHeartRateElevated),
    const SizedBox(width: 8),
    _MiniVital(
      label: 'Accél.', value: vitals.accelMagnitude.toStringAsFixed(1),
      unit: 'g', color: AppColors.accelColor, icon: Icons.speed_rounded,
      alert: false),
    const SizedBox(width: 8),
    _MiniVital(
      label: 'GSR', value: (vitals.gsrValue * 100).toStringAsFixed(0),
      unit: '%', color: AppColors.gsrColor, icon: Icons.sensors_rounded,
      alert: vitals.isGsrElevated),
  ]);
}

class _MiniVital extends StatelessWidget {
  final String   label, value, unit;
  final Color    color;
  final IconData icon;
  final bool     alert;
  const _MiniVital({required this.label, required this.value,
    required this.unit, required this.color, required this.icon,
    required this.alert});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: alert ? color.withValues(alpha: 0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: alert ? color.withValues(alpha: 0.35) : AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: (alert ? color : Colors.black).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 14)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(
          fontSize: 11, color: AppColors.textSecondary,
          fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text('$value $unit', style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w800, color: color)),
      ]),
    ),
  );
}

// ─── Dernière crise ───────────────────────────────────────────
class _LastSeizureCard extends StatelessWidget {
  final SeizureModel seizure;
  const _LastSeizureCard({required this.seizure});

  Color _sevColor(double score) {
    if (score >= 0.92) return AppColors.seizureRed;
    if (score >= 0.85) return AppColors.warning;
    return AppColors.teal;
  }

  @override
  Widget build(BuildContext context) {
    final sevColor = _sevColor(seizure.mlScore);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryPale,
            borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.access_time_rounded,
            color: AppColors.primary, size: 22)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Dernière crise',
              style: TextStyle(fontSize: 11,
                color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            Text(
              '${seizure.datetime.day}/${seizure.datetime.month}'
              ' à ${seizure.datetime.hour}h'
              '${seizure.datetime.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: sevColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20)),
            child: Text(seizure.severityLabel,
              style: TextStyle(fontSize: 11,
                fontWeight: FontWeight.w700, color: sevColor))),
          const SizedBox(height: 4),
          Text(seizure.durationFormatted,
            style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: AppColors.textSecondary)),
        ]),
      ]),
    );
  }
}

// ─── Score ML ─────────────────────────────────────────────────
class _MlScoreCard extends StatelessWidget {
  final List<SeizureModel> seizures;
  const _MlScoreCard({required this.seizures});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thisMonth = seizures.where((s) =>
      s.datetime.month == now.month && s.datetime.year == now.year).toList();

    final avgScore = thisMonth.isEmpty
      ? null
      : thisMonth.map((s) => s.mlScore).reduce((a, b) => a + b)
          / thisMonth.length;

    final scoreColor = avgScore == null ? AppColors.textHint
      : avgScore >= 0.92 ? AppColors.seizureRed
      : avgScore >= 0.85 ? AppColors.warning
      : AppColors.teal;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              scoreColor.withValues(alpha: 0.2),
              scoreColor.withValues(alpha: 0.06)]),
            borderRadius: BorderRadius.circular(14)),
          child: Icon(Icons.analytics_rounded,
            color: scoreColor, size: 26)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Score moyen ML',
              style: TextStyle(fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500)),
            Text(
              avgScore == null
                ? 'Aucune crise ce mois'
                : '${(avgScore * 100).toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 22,
                fontWeight: FontWeight.w800, color: scoreColor)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${thisMonth.length}',
            style: TextStyle(fontSize: 28,
              fontWeight: FontWeight.w800, color: scoreColor)),
          Text('crise${thisMonth.length > 1 ? 's' : ''}',
            style: const TextStyle(
              fontSize: 11, color: AppColors.textSecondary)),
        ]),
      ]),
    );
  }
}

// ─── Aperçu habitudes (dashboard) ────────────────────────────
class _HabitsPreviewSection extends StatelessWidget {
  final VoidCallback onTap;
  const _HabitsPreviewSection({required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2E78C7), Color(0xFF4A90D9), Color(0xFF7B8FD4)]),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF4A90D9).withValues(alpha: 0.22),
          blurRadius: 20,
          offset: const Offset(0, 8)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.favorite_rounded,
                color: Colors.white, size: 18)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Vivre avec l\'épilepsie',
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800,
                  color: Colors.white, fontFamily: 'Inter')),
              Text('8 habitudes essentielles',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.65))),
            ]),
            const Spacer(),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25))),
                child: const Text('Voir tout',
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: Colors.white)),
              ),
            ),
          ]),
        ),

        // Grille 3x2 des icônes habitudes
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.1,
            children: _habitPreviews.map((h) =>
              GestureDetector(
                onTap: onTap,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: h.gradient),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: h.gradient.first.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(h.icon,
                        color: const Color(0xFF2D3A5A).withValues(alpha: 0.75),
                        size: 24),
                      const SizedBox(height: 6),
                      Text(h.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: Color(0xFF2D3A5A), height: 1.2)),
                    ],
                  ),
                ),
              ),
            ).toList(),
          ),
        ),
      ],
    ),
  );
}
