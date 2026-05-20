import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/epitrack_logo.dart';
import '../../providers/auth_provider.dart';

// ── Provider patients ─────────────────────────────────────────
final patientsListProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, doctorUid) async {
  // Vérifie si ce médecin est un médecin de famille (lié à un seul patient)
  final doctorDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(doctorUid)
      .get();

  final linkedPatientId =
      doctorDoc.data()?['linkedPatientId'] as String?;

  if (linkedPatientId != null) {
    // Médecin de famille : affiche uniquement le patient lié
    final patientDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(linkedPatientId)
        .get();
    if (!patientDoc.exists) return [];
    final data = patientDoc.data()!;
    return [
      {
        'id':          patientDoc.id,
        'name':        data['nom']          ?? 'Inconnu',
        'age':         data['age']          ?? 0,
        'status':      data['status']       ?? 'offline',
        'lastSeizure': data['lastSeizure']  ?? '—',
        'monthCount':  data['monthCount']   ?? 0,
      }
    ];
  }

  // Médecin général : affiche tous les patients
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'patient')
      .get();

  return snapshot.docs.map((doc) {
    final data = doc.data();
    return {
      'id':          doc.id,
      'name':        data['nom']          ?? 'Inconnu',
      'age':         data['age']          ?? 0,
      'status':      data['status']       ?? 'offline',
      'lastSeizure': data['lastSeizure']  ?? '—',
      'monthCount':  data['monthCount']   ?? 0,
    };
  }).toList();
});

class PatientsListScreen extends ConsumerStatefulWidget {
  const PatientsListScreen({super.key});
  @override
  ConsumerState<PatientsListScreen> createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends ConsumerState<PatientsListScreen> {
  final _searchCtrl = TextEditingController();
  String  _query        = '';
  String? _statusFilter; // null = tous, 'seizure' | 'stable' | 'offline'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> all) {
    var list = all;
    if (_statusFilter != null) {
      list = list.where((p) => p['status'] == _statusFilter).toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((p) =>
        (p['name'] as String).toLowerCase().contains(q)).toList();
    }
    return list;
  }

  void _toggleFilter(String status) {
    setState(() => _statusFilter = _statusFilter == status ? null : status);
  }

  @override
  Widget build(BuildContext context) {
    final user     = ref.watch(authProvider).user!;
    final patients = ref.watch(patientsListProvider(user.uid));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: patients.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryLight)),
          error: (e, _) => Center(
            child: Text('Erreur : $e',
              style: const TextStyle(color: AppColors.danger))),
          data: (all) {
            final list = _filtered(all);
            return CustomScrollView(
              slivers: [

                // ── Hero section ───────────────────────────
                SliverToBoxAdapter(
                  child: _DoctorHeroBanner(
                    doctorName: user.name,
                    initial: user.name.substring(0, 1).toUpperCase(),
                    patientCount: all.length,
                    seizureCount: all.where(
                      (p) => p['status'] == 'seizure').length,
                    stableCount: all.where(
                      (p) => p['status'] == 'stable').length,
                    onRefresh: () => ref.invalidate(patientsListProvider(user.uid)),
                  ),
                ),

                // ── Barre de recherche ─────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un patient…',
                        prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.primary, size: 20),
                        suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                color: AppColors.textHint, size: 18),
                              onPressed: () => setState(() {
                                _searchCtrl.clear();
                                _query = '';
                              }))
                          : null,
                        fillColor: AppColors.surface,
                        contentPadding:
                          const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.cardBorder)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.cardBorder)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.primary, width: 2)),
                      ),
                    ),
                  ),
                ),

                // ── Résumé statuts ─────────────────────────
                SliverToBoxAdapter(
                  child: _StatusSummaryRow(
                    patients:      all,
                    activeFilter:  _statusFilter,
                    onFilterTap:   _toggleFilter,
                  ),
                ),

                // ── Liste patients ─────────────────────────
                list.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded,
                              size: 48, color: AppColors.textHint),
                            SizedBox(height: 10),
                            Text('Aucun patient trouvé',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ))
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                        itemBuilder: (_, i) => _PatientRowCard(
                          patient: list[i],
                          onTap: () => context.push(
                            '/doctor/patient/${list[i]['id']}'),
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

// ─── Hero banner médecin ──────────────────────────────────────
class _DoctorHeroBanner extends StatelessWidget {
  final String   doctorName, initial;
  final int      patientCount, seizureCount, stableCount;
  final VoidCallback onRefresh;
  const _DoctorHeroBanner({
    required this.doctorName, required this.initial,
    required this.patientCount, required this.seizureCount,
    required this.stableCount, required this.onRefresh,
  });

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
            // Top row
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
                Row(children: [
                  const EpiTrackLogoSmall(size: 28),
                  const SizedBox(width: 6),
                  Text('EpiTrack',
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),)),
                ]),
                Text('Dr. $doctorName',
                  style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800,
                    color: Colors.white)),
              ]),
              const Spacer(),
              GestureDetector(
                onTap: onRefresh,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.refresh_rounded,
                    color: Colors.white, size: 20)),
              ),
            ]),

            const SizedBox(height: 22),

            // Stats rapides
            Row(children: [
              _HeroStat(
                value: '$patientCount',
                label: 'Patients',
                icon: Icons.people_rounded,
                color: Colors.lightBlueAccent),
              Container(
                width: 1, height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                color: Colors.white.withValues(alpha: 0.2)),
              _HeroStat(
                value: '$seizureCount',
                label: seizureCount > 0 ? 'En alerte' : 'Alertes actives',
                icon: Icons.warning_rounded,
                color: seizureCount > 0
                  ? Colors.redAccent.shade100 : Colors.greenAccent),
              Container(
                width: 1, height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                color: Colors.white.withValues(alpha: 0.2)),
              _HeroStat(
                value: '$stableCount',
                label: 'Stables',
                icon: Icons.check_circle_rounded,
                color: Colors.greenAccent),
            ]),
          ],
        ),
      ),
    ),
  );
}

class _HeroStat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _HeroStat({required this.value, required this.label,
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
      Text(value, style: const TextStyle(
        fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
      Text(label, style: TextStyle(
        fontSize: 10, color: Colors.white.withValues(alpha: 0.65),
        fontWeight: FontWeight.w500)),
    ]),
  ]);
}

// ─── Résumé statuts (chips filtrables) ───────────────────────
class _StatusSummaryRow extends StatelessWidget {
  final List<Map<String, dynamic>> patients;
  final String?                    activeFilter;
  final ValueChanged<String>       onFilterTap;
  const _StatusSummaryRow({
    required this.patients,
    required this.activeFilter,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final seizureCount = patients.where((p) => p['status'] == 'seizure').length;
    final stableCount  = patients.where((p) => p['status'] == 'stable').length;
    final offlineCount = patients.where((p) => p['status'] == 'offline').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(children: [
        _StatusChip(
          count:      seizureCount,
          label:      'Alerte',
          status:     'seizure',
          color:      AppColors.seizureRed,
          icon:       Icons.warning_rounded,
          isSelected: activeFilter == 'seizure',
          onTap:      () => onFilterTap('seizure'),
        ),
        const SizedBox(width: 8),
        _StatusChip(
          count:      stableCount,
          label:      'Stable',
          status:     'stable',
          color:      AppColors.teal,
          icon:       Icons.check_circle_rounded,
          isSelected: activeFilter == 'stable',
          onTap:      () => onFilterTap('stable'),
        ),
        const SizedBox(width: 8),
        _StatusChip(
          count:      offlineCount,
          label:      'Bracelet hors ligne',
          status:     'offline',
          color:      AppColors.textHint,
          icon:       Icons.wifi_off_rounded,
          isSelected: activeFilter == 'offline',
          onTap:      () => onFilterTap('offline'),
        ),
      ]),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final int        count;
  final String     label, status;
  final Color      color;
  final IconData   icon;
  final bool       isSelected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.count,
    required this.label,
    required this.status,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.25),
            width: isSelected ? 1.5 : 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isSelected ? 0.14 : 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isSelected ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(7)),
            child: Icon(icon, color: color, size: 14)),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$count',
              style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800, color: color)),
            Text(label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? color : color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600)),
          ]),
        ]),
      ),
    ),
  );
}

// ─── Carte patient ────────────────────────────────────────────
class _PatientRowCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onTap;
  const _PatientRowCard({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = patient['status'] as String;
    final statusColor = status == 'seizure' ? AppColors.seizureRed
                      : status == 'stable'  ? AppColors.teal
                      : AppColors.textHint;
    final statusLabel = status == 'seizure' ? 'Alerte crise'
                      : status == 'stable'  ? 'Stable'
                      : 'Bracelet hors ligne';
    final isAlert = status == 'seizure';
    final initials = (patient['name'] as String)
      .split(' ').take(2).map((w) => w[0]).join();
    final lastSeizureLabel = patient['lastSeizure'] as String? ?? '—';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isAlert
            ? AppColors.dangerLight : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAlert
              ? AppColors.seizureRed.withValues(alpha: 0.4)
              : AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: (isAlert ? AppColors.seizureRed : Colors.black)
                .withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 4)),
          ],
        ),
        child: Row(children: [
          // Avatar
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  statusColor.withValues(alpha: 0.22),
                  statusColor.withValues(alpha: 0.10)]),
              borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(initials,
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800,
                color: statusColor)))),
          const SizedBox(width: 12),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patient['name'] as String,
                  style: const TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
                Text('${patient['age']} ans',
                  style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.access_time_rounded,
                    size: 11, color: AppColors.textHint),
                  const SizedBox(width: 3),
                  Text(lastSeizureLabel,
                    style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint)),
                ]),
              ],
            ),
          ),

          // Badge + compteur
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20)),
              child: Text(statusLabel,
                style: TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w700, color: statusColor))),
            const SizedBox(height: 4),
            Text('${patient['monthCount']} ce mois',
              style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
          ]),

          const SizedBox(width: 8),
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.chevron_right_rounded,
              color: statusColor, size: 16)),
        ]),
      ),
    );
  }
}
