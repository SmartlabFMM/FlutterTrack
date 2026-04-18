import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/alert_provider.dart';
import '../../models/alert_model.dart';

class DoctorAlertsScreen extends ConsumerStatefulWidget {
  const DoctorAlertsScreen({super.key});
  @override
  ConsumerState<DoctorAlertsScreen> createState() => _DoctorAlertsScreenState();
}

class _DoctorAlertsScreenState extends ConsumerState<DoctorAlertsScreen> {
  int _filterIdx = 0; // 0=Tous, 1=Urgents, 2=Non lus
  static const _filters = ['Tous', 'Urgents', 'Non lus'];

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
    if (diff.inHours < 24)   return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1)    return 'Hier';
    return 'Il y a ${diff.inDays}j';
  }

  List<AlertModel> _applyFilter(List<AlertModel> all) {
    switch (_filterIdx) {
      case 1: return all.where((a) => a.isUrgent).toList();
      case 2: return all.where((a) => a.status == AlertStatus.unread).toList();
      default: return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final alerts = ref.watch(alertListProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: alerts.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryLight)),
          error: (e, _) => Center(child: Text('$e')),
          data: (list) {
            final filtered  = _applyFilter(list);
            final urgentCnt = list.where((a) => a.isUrgent).length;
            final unreadCnt = list.where(
              (a) => a.status == AlertStatus.unread).length;

            return CustomScrollView(
              slivers: [
                // ── Hero ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: _AlertsHero(
                    total: list.length,
                    urgent: urgentCnt,
                    unread: unreadCnt,
                  ),
                ),

                // ── Filtres ───────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: Row(children: _filters.asMap().entries.map((e) {
                      final selected = e.key == _filterIdx;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: e.key < _filters.length - 1 ? 8 : 0),
                          child: GestureDetector(
                            onTap: () =>
                              setState(() => _filterIdx = e.key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                vertical: 10),
                              decoration: BoxDecoration(
                                color: selected
                                  ? AppColors.primary : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                    ? AppColors.primary
                                    : AppColors.cardBorder),
                                boxShadow: selected ? [
                                  BoxShadow(
                                    color: AppColors.primary
                                      .withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3)),
                                ] : [],
                              ),
                              child: Text(e.value,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                    ? Colors.white
                                    : AppColors.textSecondary)),
                            ),
                          ),
                        ),
                      );
                    }).toList()),
                  ),
                ),

                // ── Compteur résultats ────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Text(
                      '${filtered.length} alerte${filtered.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12, color: AppColors.textHint,
                        fontWeight: FontWeight.w500)),
                  ),
                ),

                // ── Liste alertes ─────────────────────────────
                filtered.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64, height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.tealPale,
                                borderRadius: BorderRadius.circular(16)),
                              child: const Icon(
                                Icons.notifications_off_rounded,
                                color: AppColors.teal, size: 32)),
                            const SizedBox(height: 12),
                            const Text('Aucune alerte',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                            const SizedBox(height: 4),
                            const Text('Aucun résultat pour ce filtre',
                              style: TextStyle(
                                color: AppColors.textHint, fontSize: 12)),
                          ],
                        ),
                      ))
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      sliver: SliverList.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                        itemBuilder: (_, i) => _AlertCard(
                          alert: filtered[i],
                          relTime: _relativeTime(filtered[i].datetime),
                          onViewDossier: () => context.push(
                            '/doctor/patient/${filtered[i].patientId}'),
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Hero alertes ─────────────────────────────────────────────
class _AlertsHero extends StatelessWidget {
  final int total, urgent, unread;
  const _AlertsHero({
    required this.total, required this.urgent, required this.unread});

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: AppColors.heroGradientDoctor,
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
            const Text('Alertes critiques',
              style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800,
                color: Colors.white, fontFamily: 'Inter')),
            const SizedBox(height: 4),
            Text('Surveillance en temps réel',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.7))),
            const SizedBox(height: 22),
            Row(children: [
              _HeroCounter(
                value: total,
                label: 'Total',
                icon: Icons.notifications_rounded,
                color: Colors.lightBlueAccent),
              Container(
                width: 1, height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.white.withValues(alpha: 0.2)),
              _HeroCounter(
                value: urgent,
                label: 'Urgentes',
                icon: Icons.warning_rounded,
                color: Colors.redAccent.shade100),
              Container(
                width: 1, height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.white.withValues(alpha: 0.2)),
              _HeroCounter(
                value: unread,
                label: 'Non lues',
                icon: Icons.mark_email_unread_rounded,
                color: Colors.amberAccent),
            ]),
          ],
        ),
      ),
    ),
  );
}

class _HeroCounter extends StatelessWidget {
  final int value; final String label;
  final IconData icon; final Color color;
  const _HeroCounter({required this.value, required this.label,
    required this.icon, required this.color});

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
      Text('$value', style: const TextStyle(
        fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
      Text(label, style: TextStyle(
        fontSize: 10, color: Colors.white.withValues(alpha: 0.65),
        fontWeight: FontWeight.w500)),
    ]),
  ]);
}

// ─── Carte alerte ─────────────────────────────────────────────
class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  final String     relTime;
  final VoidCallback onViewDossier;
  const _AlertCard({required this.alert,
    required this.relTime, required this.onViewDossier});

  @override
  Widget build(BuildContext context) {
    final a         = alert;
    final iconColor = a.isUrgent ? AppColors.seizureRed : AppColors.warning;
    final initials  = a.patientName
      .split(' ').take(2).map((w) => w[0]).join();
    final isUnread  = a.status == AlertStatus.unread;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: a.isUrgent ? AppColors.dangerLight : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: a.isUrgent
            ? AppColors.seizureRed.withValues(alpha: 0.4)
            : AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: (a.isUrgent
              ? AppColors.seizureRed : Colors.black)
              .withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(children: [
            // Avatar
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.primary.withValues(alpha: 0.25),
                  AppColors.primary.withValues(alpha: 0.10)]),
                borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(initials,
                style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800,
                  color: AppColors.primary)))),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(a.patientName,
                      style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                    if (isUnread) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 7, height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary)),
                    ],
                  ]),
                  Row(children: [
                    Icon(Icons.access_time_rounded,
                      size: 10, color: AppColors.textHint),
                    const SizedBox(width: 3),
                    Text(
                      DateFormat('dd/MM · HH:mm').format(a.datetime),
                      style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(width: 6),
                    Text('· $relTime',
                      style: TextStyle(
                        fontSize: 11, color: iconColor,
                        fontWeight: FontWeight.w600)),
                  ]),
                ],
              ),
            ),
            // Badge URGENT / statut
            if (a.isUrgent)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.seizureRed,
                  borderRadius: BorderRadius.circular(20)),
                child: const Text('URGENT',
                  style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w800,
                    color: Colors.white)))
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20)),
                child: Text(
                  a.status == AlertStatus.unread ? 'Non lu'
                  : a.status == AlertStatus.read ? 'Lu'
                  : 'Traité',
                  style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: a.status == AlertStatus.unread
                      ? AppColors.warning : AppColors.textHint))),
          ]),

          // Score ML + durée
          if (a.mlScore != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              _BadgeChip(
                icon: Icons.analytics_rounded,
                label: 'Score ML : ${(a.mlScore! * 100).toStringAsFixed(0)}%',
                color: iconColor),
              if (a.durationSeconds != null) ...[
                const SizedBox(width: 8),
                _BadgeChip(
                  icon: Icons.timer_rounded,
                  label: '${a.durationSeconds}s',
                  color: AppColors.primary),
              ],
            ]),
          ],

          // Bouton
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onViewDossier,
              icon: const Icon(Icons.folder_open_rounded, size: 15),
              label: const Text('Voir le dossier'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 38),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(
                  fontFamily: 'Inter', fontSize: 13,
                  fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  const _BadgeChip({required this.icon,
    required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}
