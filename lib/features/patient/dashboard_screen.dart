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
import '../../providers/rdv_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/seizure_confirmation_service.dart';

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
    final ble       = ref.watch(bleProvider);
    final auth      = ref.watch(authProvider);
    final uid       = auth.user!.uid.toString();
    final latest    = ref.watch(latestSeizureProvider(uid));
    final seizureList = ref.watch(seizureListProvider(uid));
    final firstName = auth.user!.name.split(' ').first;
    final nextRdv   = ref.watch(nextRdvProvider(uid)).value;

    // ── Déclencheurs automatiques de localisation ─────────────
    ref.listen(patientLocationTriggerProvider(uid), (_, next) {
      next.whenData((trigger) {
        final sharing = ref.read(locationSharingProvider);
        if (sharing.isSharing) return;
        if (trigger.seizureDetected) {
          ref.read(locationSharingProvider.notifier)
              .startSharing(uid, LocationTrigger.seizure);
        } else if (trigger.riskScore > 0.66) {
          ref.read(locationSharingProvider.notifier)
              .startSharing(uid, LocationTrigger.riskScore);
        }
      });
    });

    final triggerData = ref.watch(patientLocationTriggerProvider(uid))
        .maybeWhen(data: (t) => t, orElse: () => null);
    final showConfirmButton = triggerData != null &&
        (triggerData.seizureDetected || triggerData.riskScore > 0.66);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
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

                    // ── Prochain RDV ─────────────────────────
                    if (nextRdv != null && nextRdv.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _NextRdvCard(rdv: nextRdv),
                    ],
                    const SizedBox(height: 12),

                    // ── Bouton SOS ───────────────────────────
                    const SosButton(),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(AppStrings.sosHold,
                        style: TextStyle(
                          fontSize: 12, color: AppColors.textHint))),

                    // ── Confirmer la crise ────────────────────
                    if (showConfirmButton) ...[
                      const SizedBox(height: 16),
                      _ConfirmSeizureButton(uid: uid),
                    ],
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
                        onTap: () => context.push('/patient/signals'),
                      ),
                      const SizedBox(width: 10),
                      _QuickAction(
                        icon: Icons.history_rounded,
                        label: 'Historique\ncrises',
                        gradient: const LinearGradient(
                          colors: [AppColors.tealDark, AppColors.teal]),
                        onTap: () => context.push('/patient/history'),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // ── Score de risque ce mois ──────────────
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
                          onTap: () => context.push('/patient/habits'),
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
                      onTap: () => context.push('/patient/habits')),
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
                      color: Colors.white)),
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
class _NoSeizureCard extends StatelessWidget {
  const _NoSeizureCard();

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
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.teal.withValues(alpha: 0.15)),
        child: const Icon(Icons.check_circle_rounded,
          color: AppColors.teal, size: 22)),
      const SizedBox(width: 14),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(AppStrings.noSeizure,
          style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: AppColors.tealDark)),
        Text('Aucune activité anormale détectée',
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

// ─── Cartes mois : crises + score de risque ───────────────────
class _MlScoreCard extends StatelessWidget {
  final List<SeizureModel> seizures;
  const _MlScoreCard({required this.seizures});

  @override
  Widget build(BuildContext context) {
    final now       = DateTime.now();
    final thisMonth = seizures.where((s) =>
      s.datetime.month == now.month && s.datetime.year == now.year).toList();
    final count    = thisMonth.length;
    final avgScore = thisMonth.isEmpty
      ? null
      : thisMonth.map((s) => s.mlScore).reduce((a, b) => a + b) / thisMonth.length;

    return Row(children: [
      Expanded(child: _SeizureCountCard(count: count)),
      const SizedBox(width: 12),
      Expanded(child: _RiskScoreCard(avgScore: avgScore)),
    ]);
  }
}

// ── Nombre de crises ──────────────────────────────────────────
class _SeizureCountCard extends StatelessWidget {
  final int count;
  const _SeizureCountCard({required this.count});

  @override
  Widget build(BuildContext context) {
    final color = count == 0
      ? AppColors.teal
      : count <= 2 ? AppColors.warning : AppColors.seizureRed;
    final bg = count == 0
      ? AppColors.tealPale
      : count <= 2 ? AppColors.warningLight : AppColors.dangerLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.bolt_rounded, color: color, size: 22)),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$count',
            style: TextStyle(
              fontSize: 34, fontWeight: FontWeight.w800,
              color: color, height: 1)),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('crise${count > 1 ? 's' : ''}',
              style: TextStyle(fontSize: 12,
                fontWeight: FontWeight.w600, color: color))),
        ]),
        const SizedBox(height: 4),
        const Text('Ce mois-ci',
          style: TextStyle(fontSize: 11,
            color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ── Score de risque ───────────────────────────────────────────
class _RiskScoreCard extends StatelessWidget {
  final double? avgScore;
  const _RiskScoreCard({required this.avgScore});

  @override
  Widget build(BuildContext context) {
    final String  label;
    final Color   color;
    final Color   bg;
    final IconData icon;

    if (avgScore == null) {
      label = 'Inconnu';
      color = AppColors.textHint;
      bg    = AppColors.surfaceAlt;
      icon  = Icons.analytics_rounded;
    } else if (avgScore! >= 0.85) {
      label = 'Élevé';
      color = AppColors.seizureRed;
      bg    = AppColors.dangerLight;
      icon  = Icons.warning_rounded;
    } else if (avgScore! >= 0.50) {
      label = 'Moyen';
      color = AppColors.warning;
      bg    = AppColors.warningLight;
      icon  = Icons.error_outline_rounded;
    } else {
      label = 'Faible';
      color = AppColors.teal;
      bg    = AppColors.tealPale;
      icon  = Icons.check_circle_rounded;
    }

    final pct = avgScore == null
      ? null : (avgScore! * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22)),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(pct ?? '—',
            style: TextStyle(
              fontSize: 34, fontWeight: FontWeight.w800,
              color: color, height: 1)),
          if (pct != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text('%',
                style: TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w700, color: color))),
        ]),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                color: color, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(label,
              style: TextStyle(fontSize: 11,
                fontWeight: FontWeight.w700, color: color)),
          ]),
        ),
        const SizedBox(height: 3),
        const Text('Score de risque',
          style: TextStyle(fontSize: 11,
            color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ─── Prochain RDV ─────────────────────────────────────────────
class _NextRdvCard extends StatelessWidget {
  final String rdv;
  const _NextRdvCard({required this.rdv});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.07),
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
        child: const Icon(Icons.calendar_today_rounded,
          color: AppColors.primary, size: 20)),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Prochain rendez-vous',
            style: TextStyle(fontSize: 11,
              color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          Text(rdv,
            style: const TextStyle(fontSize: 15,
              fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ]),
      ),
    ]),
  );
}

// ─── Bouton confirmer la crise ───────────────────────────────
class _ConfirmSeizureButton extends ConsumerStatefulWidget {
  final String uid;
  const _ConfirmSeizureButton({required this.uid});

  @override
  ConsumerState<_ConfirmSeizureButton> createState() =>
      _ConfirmSeizureButtonState();
}

class _ConfirmSeizureButtonState
    extends ConsumerState<_ConfirmSeizureButton> {
  bool _loading = false;

  Future<void> _onTap() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer une crise ?'),
        content: const Text(
            'Cette action alimentera l\'amélioration du modèle IA.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.seizureRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _loading = true);
    try {
      await SeizureConfirmationService().confirmSeizure(widget.uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Crise confirmée ✅ Merci, le modèle IA sera amélioré.'),
          backgroundColor: AppColors.tealDark,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.seizureRed,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _loading ? null : _onTap,
          icon: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.check_circle_outline_rounded,
                  color: Colors.white),
          label: Text(
            _loading ? 'Confirmation…' : 'Confirmer la crise',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white),
          ),
        ),
      );
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
        colors: [Color(0xFF3DADA0), Color(0xFF5EC5B8), Color(0xFF8DD9D1)]),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF5EC5B8).withValues(alpha: 0.22),
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
                  color: Colors.white)),
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


