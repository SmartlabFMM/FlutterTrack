import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/epitrack_logo.dart';
import '../../models/seizure_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/alert_provider.dart';
import '../../providers/seizure_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/notification_service.dart';

class FamilyDashboardScreen extends ConsumerWidget {
  const FamilyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user   = ref.watch(authProvider).user!;
    final unread = ref.watch(unreadAlertCountProvider);
    final patId  = user.linkedPatientId ?? '';
    final latest = ref.watch(latestSeizureProvider(patId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [

            // ── Hero section ──────────────────────────────────
            SliverToBoxAdapter(
              child: _FamilyHeroBanner(
                firstName: user.name.split(' ').first,
                initial: user.name.substring(0, 1).toUpperCase(),
                unreadCount: unread.maybeWhen(data: (c) => c, orElse: () => 0),
                onAlertsTap: () => context.go('/family/alerts'),
              ),
            ),

            // ── Corps ─────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── Statut patient ─────────────────────────
                  latest.when(
                    data: (seizure) => _PatientStatusCard(
                      hasRecentSeizure: seizure != null &&
                        DateTime.now().difference(seizure.datetime).inHours < 6,
                      lastSeizure: seizure),
                    loading: () => const _SkeletonCard(height: 80),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(height: 12),

                  // ── Dernière alerte ────────────────────────
                  latest.when(
                    data: (seizure) => seizure != null
                      ? _LastAlertCard(seizure: seizure)
                      : const SizedBox(),
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(height: 12),

                  // ── Carte localisation ─────────────────────
                  _LocationCard(patientId: patId),
                  const SizedBox(height: 20),

                  // ── Actions rapides ────────────────────────
                  const _SectionLabel('Actions rapides'),
                  const SizedBox(height: 10),
                  Row(children: [
                    _ActionTile(
                      icon: Icons.history_rounded,
                      label: 'Historique\ncrises',
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryDark, AppColors.primary]),
                      onTap: () => context.go('/family/alerts')),
                    const SizedBox(width: 10),
                    _ActionTile(
                      icon: Icons.contacts_rounded,
                      label: 'Contacts\nurgence',
                      gradient: const LinearGradient(
                        colors: [AppColors.tealDark, AppColors.teal]),
                      onTap: () => context.go('/family/contacts')),
                    const SizedBox(width: 10),
                    _ActionTile(
                      icon: Icons.checklist_rounded,
                      label: 'Bonnes\nhabitudes',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF10B981)]),
                      onTap: () => context.push('/family/habits')),
                  ]),
                  const SizedBox(height: 12),

                  // ── Appel médecin ──────────────────────────
                  const _CallDoctorCard(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero Banner ─────────────────────────────────────────────
class _FamilyHeroBanner extends StatelessWidget {
  final String firstName, initial;
  final int    unreadCount;
  final VoidCallback onAlertsTap;
  const _FamilyHeroBanner({
    required this.firstName, required this.initial,
    required this.unreadCount, required this.onAlertsTap,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: AppColors.heroGradientFamily,
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
            // Top bar
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
                  Text('EpiTrack · Famille',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.72))),
                ]),
              ]),
              const Spacer(),
              if (unreadCount > 0)
                GestureDetector(
                  onTap: onAlertsTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.seizureRed,
                      borderRadius: BorderRadius.circular(20)),
                    child: Row(children: [
                      const Icon(Icons.notifications_rounded,
                        size: 14, color: Colors.white),
                      const SizedBox(width: 5),
                      Text('$unreadCount',
                        style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w800,
                          color: Colors.white)),
                    ]),
                  ),
                ),
            ]),

            const SizedBox(height: 24),

            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2))),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.shield_rounded,
                    size: 18, color: Colors.white)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Surveillance activée',
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: Colors.white)),
                  Text('Alertes en temps réel · SMS automatique',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.72))),
                ]),
              ]),
            ),
          ],
        ),
      ),
    ),
  );
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

// ─── Statut patient ──────────────────────────────────────────
class _PatientStatusCard extends StatelessWidget {
  final bool hasRecentSeizure;
  final SeizureModel? lastSeizure;
  const _PatientStatusCard(
      {required this.hasRecentSeizure, this.lastSeizure});

  @override
  Widget build(BuildContext context) {
    final color = hasRecentSeizure ? AppColors.seizureRed : AppColors.teal;
    final fill  = hasRecentSeizure ? AppColors.dangerLight : AppColors.tealPale;
    final label = hasRecentSeizure
      ? 'Crise récente — Vigilance requise'
      : 'État stable — Aucune anomalie';
    final sub = hasRecentSeizure
      ? 'Crise détectée il y a moins de 6h'
      : 'Le bracelet surveille en continu';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14)),
          child: Icon(
            hasRecentSeizure
              ? Icons.warning_amber_rounded
              : Icons.favorite_rounded,
            color: color, size: 26)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                style: TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w700, color: color)),
              const SizedBox(height: 2),
              Text(sub,
                style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
              if (lastSeizure != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Dernière crise : ${_elapsedHuman(lastSeizure!.datetime)}',
                  style: TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.85))),
              ],
            ],
          ),
        ),
      ]),
    );
  }
}

// ─── Dernière alerte ─────────────────────────────────────────
class _LastAlertCard extends StatelessWidget {
  final SeizureModel seizure;
  const _LastAlertCard({required this.seizure});

  Color _scoreColor(double s) {
    if (s >= 0.92) return AppColors.seizureRed;
    if (s >= 0.85) return AppColors.warning;
    return AppColors.teal;
  }

  @override
  Widget build(BuildContext context) {
    final sc = _scoreColor(seizure.mlScore);
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryPale,
              borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.access_time_rounded,
              color: AppColors.primary, size: 20)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Dernière crise',
              style: TextStyle(fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500)),
            Text(
              DateFormat('dd MMM à HH:mm', 'fr').format(seizure.datetime),
              style: const TextStyle(fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
          ]),
          const Spacer(),
          Text(seizure.durationFormatted,
            style: const TextStyle(
              fontSize: 13, color: AppColors.textSecondary,
              fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _InfoBadge(
            icon: Icons.analytics_rounded,
            label: 'Score ML : ${(seizure.mlScore * 100).toStringAsFixed(0)}%',
            color: sc),
          const SizedBox(width: 8),
          _InfoBadge(
            icon: Icons.timer_outlined,
            label: seizure.durationFormatted,
            color: AppColors.primary),
        ]),
      ]),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  const _InfoBadge({required this.icon,
    required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    ]),
  );
}

// ─── Boutons action ───────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData   icon;
  final String     label;
  final Gradient   gradient;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label,
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
              color: AppColors.primary.withValues(alpha: 0.22),
              blurRadius: 14,
              offset: const Offset(0, 5)),
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
              fontSize: 12, fontWeight: FontWeight.w700,
              color: Colors.white, height: 1.3)),
        ]),
      ),
    ),
  );
}

// ─── Appeler médecin ─────────────────────────────────────────
class _CallDoctorCard extends StatefulWidget {
  const _CallDoctorCard();
  @override
  State<_CallDoctorCard> createState() => _CallDoctorCardState();
}

class _CallDoctorCardState extends State<_CallDoctorCard> {
  bool _pulse = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _pulse = true);
    });
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => NotificationService.callEmergencyContact('+216XXXXXXXX'),
    child: Container(
      padding: const EdgeInsets.all(16),
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
        AnimatedContainer(
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOut,
          width: _pulse ? 48 : 40,
          height: _pulse ? 48 : 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.teal.withValues(alpha: _pulse ? 0.25 : 0.12),
                AppColors.primary.withValues(alpha: _pulse ? 0.20 : 0.08),
              ]),
            shape: BoxShape.circle),
          onEnd: () { if (mounted) setState(() => _pulse = !_pulse); },
          child: const Icon(Icons.call_rounded,
            color: AppColors.teal, size: 22)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Contacter le médecin',
              style: TextStyle(fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
            const Text('Dr. Kamel Trabelsi',
              style: TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.chevron_right_rounded,
            color: AppColors.teal, size: 18)),
      ]),
    ),
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

String _elapsedHuman(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
  if (diff.inHours < 24)   return 'Il y a ${diff.inHours}h';
  if (diff.inDays < 7)     return 'Il y a ${diff.inDays}j';
  return DateFormat('dd MMM', 'fr').format(dt);
}

// ── Carte localisation GPS ────────────────────────────────────
class _LocationCard extends ConsumerWidget {
  final String patientId;
  const _LocationCard({required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locAsync = ref.watch(familyLocationProvider(patientId));

    return locAsync.when(
      loading: () => const SizedBox(),
      error:   (_, __) => const SizedBox(),
      data: (loc) {
        final isActive = loc != null && loc.isActive;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isActive
              ? AppColors.danger.withValues(alpha: 0.08)
              : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? AppColors.danger : AppColors.cardBorder,
              width: isActive ? 1.5 : 0.8),
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: isActive
                    ? AppColors.danger.withValues(alpha: 0.15)
                    : AppColors.surfaceAlt,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isActive
                    ? Icons.location_on_rounded
                    : Icons.location_off_rounded,
                  color: isActive ? AppColors.danger : AppColors.textHint,
                  size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActive
                        ? 'Localisation active'
                        : 'Localisation inactive',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isActive
                          ? AppColors.danger
                          : AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      isActive
                        ? 'Mise à jour il y a ${DateTime.now().difference(loc!.updatedAt).inSeconds}s'
                        : 'S\'active en cas de crise ou SOS',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (isActive)
                TextButton(
                  onPressed: () => context.push(
                    '/family/location/${patientId}'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6)),
                  child: const Text('Voir',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        );
      },
    );
  }
}
