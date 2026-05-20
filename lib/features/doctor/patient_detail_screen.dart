import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/seizure_provider.dart';

class PatientDetailScreen extends ConsumerWidget {
  final String patientId;
  const PatientDetailScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientRaw = ref.watch(patientDataProvider(patientId)).valueOrNull ?? {};
    final name   = patientRaw['nom'] as String? ?? 'Patient #$patientId';
    final detail = patientRaw.isNotEmpty
        ? _mapFirestoreToDetail(patientRaw)
        : _defaultDetail('Patient #$patientId');

    // Observateur = ne peut pas modifier les données du patient
    final doctorUid  = ref.watch(authProvider).user?.uid ?? '';
    final doctorData = ref.watch(patientDataProvider(doctorUid)).valueOrNull ?? {};
    final isObserver = doctorData['doctorType'] == 'observateur';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            // ── Hero dossier ─────────────────────────────
            SliverToBoxAdapter(
              child: _PatientHero(
                name: name,
                detail: detail,
                patientId: patientId,
              ),
            ),

            // ── Corps ─────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── Infos médicales ──────────────────────
                  _MedicalInfoCard(
                    detail: detail,
                    onEdit: isObserver
                      ? null
                      : () => _showEditMedicalSheet(context, ref, detail, name),
                  ),
                  const SizedBox(height: 14),

                  // ── Compliance traitement ────────────────
                  _ComplianceCard(
                    compliance: (detail['compliance'] as num?)?.toDouble()),
                  const SizedBox(height: 14),

                  // ── Stats crises ─────────────────────────
                  _SeizureStatsCard(patientId: patientId),
                  const SizedBox(height: 14),

                  // ── Déclencheurs ─────────────────────────
                  _TriggersCard(
                    triggers: List<String>.from(
                      detail['triggers'] as List? ?? [])),
                  const SizedBox(height: 14),

                  // ── Notes cliniques ──────────────────────
                  _ClinicalNotesCard(
                    notes: List<Map<String, dynamic>>.from(
                      detail['notes'] as List? ?? []),
                    patientName: name,
                    patientId: patientId,
                    ref: ref,
                    context: context,
                    canEdit: !isObserver,
                  ),
                  const SizedBox(height: 20),

                  // ── Actions ──────────────────────────────
                  const _SectionLabel('Actions'),
                  const SizedBox(height: 10),

                  _DoctorActionTile(
                    icon: Icons.monitor_heart_rounded,
                    title: 'Données vitales 24h',
                    subtitle: 'FC · Accéléromètre · GSR en temps réel',
                    color: AppColors.teal,
                    onTap: () => context.push('/doctor/vitals/$patientId')),
                  _DoctorActionTile(
                    icon: Icons.location_on_rounded,
                    title: 'Localisation du patient',
                    subtitle: 'Position GPS en cas de crise',
                    color: AppColors.danger,
                    onTap: () => context.push('/doctor/location/$patientId')),
                  _DoctorActionTile(
                    icon: Icons.picture_as_pdf_rounded,
                    title: 'Générer rapport PDF',
                    subtitle: 'Export historique complet du patient',
                    color: AppColors.teal,
                    onTap: () => context.push('/doctor/report/$patientId')),
                  _DoctorActionTile(
                    icon: Icons.note_add_rounded,
                    title: 'Ajouter note clinique',
                    subtitle: 'Observations médicales & traitements',
                    color: AppColors.primaryDark,
                    onTap: isObserver
                      ? null
                      : () => _showNoteDialog(context, ref, name)),
                  // Infos personnelles : lecture seule
                  _DoctorActionTile(
                    icon: Icons.person_rounded,
                    title: 'Informations personnelles',
                    subtitle: 'Âge, téléphone, adresse',
                    color: AppColors.primary,
                    onTap: () => _showPersonalInfoSheet(context, detail)),
                  _DoctorActionTile(
                    icon: Icons.calendar_today_rounded,
                    title: 'Prochain rendez-vous',
                    subtitle: detail['nextRdv'] as String? ?? 'Aucun RDV planifié',
                    color: const Color(0xFF7C3AED),
                    onTap: isObserver
                      ? null
                      : () => _showRdvSheet(context, ref)),
                  _DoctorActionTile(
                    icon: Icons.call_rounded,
                    title: 'Appeler le patient',
                    subtitle: detail['phone'] as String? ?? '—',
                    color: AppColors.tealDark,
                    onTap: () async {
                      final phone = detail['phone'] as String? ?? '';
                      if (phone.isEmpty || phone == '—') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Aucun numéro renseigné'),
                            behavior: SnackBarBehavior.floating));
                        return;
                      }
                      final uri = Uri(scheme: 'tel',
                        path: phone.replaceAll(' ', ''));
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Impossible d\'appeler $phone'),
                              behavior: SnackBarBehavior.floating));
                        }
                      }
                    }),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────

  Map<String, dynamic> _mapFirestoreToDetail(Map<String, dynamic> data) => {
    'age':         data['age']         ?? 30,
    'gender':      data['gender']      ?? '—',
    'city':        data['city']        ?? '—',
    'diagnosis':   data['diagnosis']   ?? '',
    'since':       data['since']       ?? 'Suivi récent',
    'treatment':   data['treatment']   ?? '',
    'phone':       data['phone']       ?? '',
    'address':     data['address']     ?? '',
    'nextRdv':     data['nextRdv']     ?? '',
    'notes':       data['notes']       ?? [],
    'allergies':   data['allergies']   ?? '',
    'bloodGroup':  data['bloodGroup']  ?? '',
    'weight':      data['weight']      ?? '',
    'seizureType': data['seizureType'] ?? '',
    'triggers':    data['triggers']    ?? [],
    'compliance':  (data['compliance'] as num?)?.toDouble(),
  };

  Map<String, dynamic> _defaultDetail(String name) => {
    'age': 30, 'gender': 'N/A', 'city': '—',
    'diagnosis': '', 'since': 'Suivi récent',
    'treatment': '', 'phone': '', 'address': '', 'nextRdv': '',
    'notes': [], 'allergies': '', 'bloodGroup': '',
    'weight': '', 'seizureType': '', 'triggers': [],
    'compliance': null,
  };

  // ── Infos médicales éditables ────────────────────────────────
  void _showEditMedicalSheet(
      BuildContext context, WidgetRef ref,
      Map<String, dynamic> detail, String name) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditMedicalSheet(
        patientId: patientId,
        detail: detail,
        patientName: name,
        onSaved: () => ref.invalidate(patientDataProvider(patientId)),
      ),
    );
  }

  // ── Infos personnelles lecture seule ────────────────────────────
  void _showPersonalInfoSheet(
      BuildContext context, Map<String, dynamic> detail) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryPale,
                  borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.person_rounded,
                  color: AppColors.primary, size: 20)),
              const SizedBox(width: 12),
              const Text('Informations personnelles',
                style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
            ]),
            const SizedBox(height: 16),
            _infoRow(Icons.cake_rounded, 'Âge',
              detail['age']?.toString() ?? '—'),
            _infoRow(Icons.call_rounded, 'Téléphone',
              detail['phone'] as String? ?? '—'),
            _infoRow(Icons.location_on_rounded, 'Adresse',
              detail['address'] as String? ?? '—'),
            _infoRow(Icons.wc_rounded, 'Sexe',
              detail['gender'] as String? ?? '—'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 12),
      Text('$label : ',
        style: const TextStyle(
          fontSize: 13, color: AppColors.textSecondary,
          fontWeight: FontWeight.w500)),
      Expanded(child: Text(value,
        style: const TextStyle(
          fontSize: 13, color: AppColors.textPrimary,
          fontWeight: FontWeight.w600))),
    ]),
  );

  // ── Note clinique ─────────────────────────────────────────────
  void _showNoteDialog(BuildContext context, WidgetRef ref, String patientName) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPale,
                    borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.note_add_rounded,
                    color: AppColors.primary, size: 18)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Note clinique',
                    style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
                  Text(patientName,
                    style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
                ]),
              ]),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                maxLines: 4,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText:
                    'Observations, modifications de traitement, recommandations…',
                  alignLabelWithHint: true),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      side: const BorderSide(color: AppColors.cardBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                    child: const Text('Annuler',
                      style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final text = ctrl.text.trim();
                      if (text.isEmpty) return;
                      final dateLabel = DateFormat('dd MMM yyyy', 'fr').format(DateTime.now());
                      try {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(patientId)
                            .set({
                          'notes': FieldValue.arrayUnion([
                            {'date': dateLabel, 'text': text}
                          ])
                        }, SetOptions(merge: true));
                        ref.invalidate(patientDataProvider(patientId));
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Note clinique enregistrée'),
                              backgroundColor: AppColors.teal,
                              behavior: SnackBarBehavior.floating));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur : $e'),
                              backgroundColor: AppColors.danger,
                              behavior: SnackBarBehavior.floating));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                    child: const Text('Enregistrer'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
  // ── Planification rendez-vous ─────────────────────────────────
  void _showRdvSheet(BuildContext context, WidgetRef ref) {
    DateTime? pickedDate;
    final timeCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.event_rounded,
                      color: Color(0xFF7C3AED), size: 20)),
                  const SizedBox(width: 12),
                  const Text('Planifier un rendez-vous',
                    style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
                ]),
                const SizedBox(height: 20),

                // Sélecteur de date
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate:
                        DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate:
                        DateTime.now().add(const Duration(days: 365)),
                      locale: const Locale('fr'),
                    );
                    if (d != null) setS(() => pickedDate = d);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder)),
                    child: Row(children: [
                      const Icon(Icons.event_rounded,
                        color: Color(0xFF7C3AED), size: 18),
                      const SizedBox(width: 10),
                      Text(
                        pickedDate == null
                          ? 'Choisir une date'
                          : DateFormat('EEEE d MMMM yyyy', 'fr')
                              .format(pickedDate!),
                        style: TextStyle(
                          fontSize: 14,
                          color: pickedDate == null
                            ? AppColors.textHint : AppColors.textPrimary,
                          fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),

                // Heure
                TextField(
                  controller: timeCtrl,
                  keyboardType: TextInputType.datetime,
                  decoration: InputDecoration(
                    labelText: 'Heure (ex: 10:30)',
                    prefixIcon: const Icon(
                      Icons.access_time_rounded, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppColors.surfaceAlt),
                ),
                const SizedBox(height: 20),

                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        side: const BorderSide(color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                      child: const Text('Annuler',
                        style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (pickedDate == null ||
                            timeCtrl.text.trim().isEmpty) return;
                        final label =
                          '${DateFormat('EEEE d MMMM', 'fr').format(pickedDate!)}'
                          ' · ${timeCtrl.text.trim()}';
                        await FirebaseFirestore.instance
                          .collection('users')
                          .doc(patientId)
                          .set({'nextRdv': label},
                            SetOptions(merge: true));
                        ref.invalidate(patientDataProvider(patientId));
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Rendez-vous planifié'),
                              backgroundColor: Color(0xFF7C3AED),
                              behavior: SnackBarBehavior.floating));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        backgroundColor: const Color(0xFF7C3AED),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                      child: const Text('Confirmer',
                        style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Formulaire infos médicales ──────────────────────────────
class _EditMedicalSheet extends StatefulWidget {
  final String               patientId;
  final Map<String, dynamic> detail;
  final String               patientName;
  final VoidCallback         onSaved;
  const _EditMedicalSheet({
    required this.patientId, required this.detail,
    required this.patientName, required this.onSaved,
  });
  @override
  State<_EditMedicalSheet> createState() => _EditMedicalSheetState();
}

class _EditMedicalSheetState extends State<_EditMedicalSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _saving   = false;

  late final TextEditingController _treatment;
  late final TextEditingController _seizureType;
  late final TextEditingController _bloodGroup;
  late final TextEditingController _weight;
  late final TextEditingController _allergies;

  @override
  void initState() {
    super.initState();
    final d = widget.detail;
    _treatment   = TextEditingController(text: d['treatment']   as String? ?? '');
    _seizureType = TextEditingController(text: d['seizureType'] as String? ?? '');
    _bloodGroup  = TextEditingController(text: d['bloodGroup']  as String? ?? '');
    _weight      = TextEditingController(text: d['weight']      as String? ?? '');
    _allergies   = TextEditingController(text: d['allergies']   as String? ?? '');
  }

  @override
  void dispose() {
    for (final c in [_treatment, _seizureType, _bloodGroup, _weight, _allergies]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await FirebaseFirestore.instance
        .collection('users').doc(widget.patientId).update({
      'treatment':   _treatment.text.trim(),
      'seizureType': _seizureType.text.trim(),
      'bloodGroup':  _bloodGroup.text.trim(),
      'weight':      _weight.text.trim(),
      'allergies':   _allergies.text.trim(),
    });
    widget.onSaved();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Informations médicales mises à jour'),
        backgroundColor: AppColors.teal,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.70,
      maxChildSize: 0.90,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryPale,
                  borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.medical_information_rounded,
                  color: AppColors.primary, size: 20)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Informations médicales',
                  style: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
                Text(widget.patientName,
                  style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ]),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.cardBorder),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                children: [
                  _field('Traitement en cours', Icons.medication_rounded, _treatment,
                    hint: 'Ex: Valproate 500mg · 2×/j'),
                  _field('Type de crise', Icons.bolt_rounded, _seizureType,
                    hint: 'Ex: Tonico-clonique · Grand mal'),
                  _field('Groupe sanguin', Icons.bloodtype_rounded, _bloodGroup,
                    hint: 'Ex: A+'),
                  _field('Poids', Icons.monitor_weight_rounded, _weight,
                    hint: 'Ex: 74 kg'),
                  _field('Allergies', Icons.warning_amber_rounded, _allergies,
                    hint: 'Ex: Pénicilline'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                    child: _saving
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                      : const Text('Enregistrer',
                          style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      side: const BorderSide(color: AppColors.cardBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                    child: const Text('Annuler',
                      style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _field(
    String label, IconData icon, TextEditingController ctrl, {
    String hint = '', TextInputType keyboardType = TextInputType.text,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primaryPale,
            borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppColors.primary, size: 16)),
      ),
    ),
  );
}

// ─── Formulaire infos personnelles ───────────────────────────
class _EditPersonalSheet extends StatefulWidget {
  final String              patientId;
  final Map<String, dynamic> raw;
  final String              patientName;
  final VoidCallback        onSaved;
  const _EditPersonalSheet({
    required this.patientId, required this.raw,
    required this.patientName, required this.onSaved,
  });
  @override
  State<_EditPersonalSheet> createState() => _EditPersonalSheetState();
}

class _EditPersonalSheetState extends State<_EditPersonalSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _saving   = false;

  late final TextEditingController _nom;
  late final TextEditingController _prenom;
  late final TextEditingController _age;
  late final TextEditingController _phone;
  late final TextEditingController _city;
  late final TextEditingController _address;
  late final TextEditingController _gender;

  @override
  void initState() {
    super.initState();
    final d = widget.raw;
    // nom complet peut être stocké dans 'nom' ou séparé en 'prenom'+'nom'
    final fullName = d['nom'] as String? ?? '';
    final parts    = fullName.split(' ');
    _prenom  = TextEditingController(text: parts.isNotEmpty ? parts.first : '');
    _nom     = TextEditingController(
        text: parts.length > 1 ? parts.sublist(1).join(' ') : '');
    _age     = TextEditingController(
        text: d['age'] != null ? '${d['age']}' : '');
    _phone   = TextEditingController(text: d['phone']   as String? ?? '');
    _city    = TextEditingController(text: d['city']    as String? ?? '');
    _address = TextEditingController(text: d['address'] as String? ?? '');
    _gender  = TextEditingController(text: d['gender']  as String? ?? '');
  }

  @override
  void dispose() {
    for (final c in [_nom, _prenom, _age, _phone, _city, _address, _gender]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final fullName = '${_prenom.text.trim()} ${_nom.text.trim()}'.trim();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.patientId)
        .update({
      'nom':     fullName,
      'age':     int.tryParse(_age.text.trim()) ?? 0,
      'phone':   _phone.text.trim(),
      'city':    _city.text.trim(),
      'address': _address.text.trim(),
      'gender':  _gender.text.trim(),
    });
    widget.onSaved();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Informations personnelles mises à jour'),
        backgroundColor: AppColors.teal,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryPale,
                  borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.person_rounded,
                  color: AppColors.primary, size: 20)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Informations personnelles',
                  style: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
                Text(widget.patientName,
                  style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ]),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.cardBorder),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                children: [
                  Row(children: [
                    Expanded(child: _field('Prénom',
                      Icons.badge_rounded, _prenom,
                      hint: 'Ahmed', required: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _field('Nom',
                      Icons.badge_rounded, _nom,
                      hint: 'Ben Ali', required: true)),
                  ]),
                  Row(children: [
                    Expanded(child: _field('Âge',
                      Icons.cake_rounded, _age,
                      hint: '28',
                      keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: _field('Genre',
                      Icons.wc_rounded, _gender,
                      hint: 'Homme / Femme')),
                  ]),
                  _field('Téléphone',
                    Icons.call_rounded, _phone,
                    hint: '+216 71 XXX XXX',
                    keyboardType: TextInputType.phone),
                  _field('Ville',
                    Icons.location_city_rounded, _city,
                    hint: 'Tunis'),
                  _field('Adresse',
                    Icons.home_rounded, _address,
                    hint: 'Rue, quartier…'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                    child: _saving
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                      : const Text('Enregistrer',
                          style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      side: const BorderSide(color: AppColors.cardBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                    child: const Text('Annuler',
                      style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _field(
    String label, IconData icon, TextEditingController ctrl, {
    String hint = '',
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: required
        ? (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null
        : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primaryPale,
            borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppColors.primary, size: 16)),
      ),
    ),
  );
}

// ─── Hero dossier patient ─────────────────────────────────────
class _PatientHero extends StatelessWidget {
  final String name, patientId;
  final Map<String, dynamic> detail;
  const _PatientHero({
    required this.name, required this.detail, required this.patientId});

  @override
  Widget build(BuildContext context) {
    final initials = name.split(' ').take(2).map((w) => w[0]).join();
    final age      = detail['age'] as int? ?? 0;
    final gender   = detail['gender'] as String? ?? '';
    final city     = detail['city'] as String? ?? '';
    final diag     = detail['diagnosis'] as String? ?? '';
    final since    = detail['since'] as String? ?? '';

    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradientDoctor,
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(32),
          bottomRight: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          // Back button + titre
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2))),
                  child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20)),
              ),
              const SizedBox(width: 12),
              const Text('Dossier patient',
                style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: Colors.white)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20)),
                child: Text('#$patientId',
                  style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: Colors.white)),
              ),
            ]),
          ),

          // Profil
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Row(children: [
              // Avatar grand
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                  ],
                ),
                child: Center(child: Text(initials,
                  style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800,
                    color: Colors.white)))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800,
                      color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('$age ans · $gender · $city',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8))),
                    const SizedBox(height: 8),
                    Text(diag, style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.72),
                      fontStyle: FontStyle.italic)),
                    const SizedBox(height: 8),
                    // Badge "Sous surveillance"
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        Text(since, style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: Colors.white)),
                      ])),
                  ],
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Informations médicales ───────────────────────────────────
class _MedicalInfoCard extends StatelessWidget {
  final Map<String, dynamic> detail;
  final VoidCallback?         onEdit;
  const _MedicalInfoCard({required this.detail, this.onEdit});

  @override
  Widget build(BuildContext context) => _SectionCard(
    title: 'Informations médicales',
    icon: Icons.medical_information_rounded,
    iconColor: AppColors.primary,
    action: onEdit == null ? null : GestureDetector(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primaryPale,
          borderRadius: BorderRadius.circular(20)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.edit_rounded, size: 12, color: AppColors.primary),
          SizedBox(width: 4),
          Text('Modifier', style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: AppColors.primary)),
        ]),
      ),
    ),
    child: Column(children: [
      _InfoRow(icon: Icons.medication_rounded,
        label: 'Traitement',
        value: detail['treatment'] as String? ?? '—',
        color: AppColors.primary),
      const _Divider(),
      _InfoRow(icon: Icons.coronavirus_rounded,
        label: 'Type de crise',
        value: detail['seizureType'] as String? ?? '—',
        color: AppColors.warning),
      const _Divider(),
      _InfoRow(icon: Icons.bloodtype_rounded,
        label: 'Groupe sanguin',
        value: detail['bloodGroup'] as String? ?? '—',
        color: AppColors.seizureRed),
      const _Divider(),
      _InfoRow(icon: Icons.monitor_weight_rounded,
        label: 'Poids',
        value: detail['weight'] as String? ?? '—',
        color: AppColors.teal),
      const _Divider(),
      _InfoRow(icon: Icons.warning_amber_rounded,
        label: 'Allergies',
        value: detail['allergies'] as String? ?? '—',
        color: AppColors.warning),
    ]),
  );
}

// ─── Compliance traitement ────────────────────────────────────
class _ComplianceCard extends StatelessWidget {
  final double? compliance;
  const _ComplianceCard({required this.compliance});

  @override
  Widget build(BuildContext context) {
    if (compliance == null) {
      return _SectionCard(
        title: 'Observance thérapeutique',
        icon: Icons.task_alt_rounded,
        iconColor: AppColors.textHint,
        child: const Text('Aucune donnée — le patient n\'a pas encore utilisé l\'app',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      );
    }
    final pct   = (compliance! * 100).round();
    final color = pct >= 90 ? AppColors.teal
                : pct >= 70 ? AppColors.warning
                : AppColors.seizureRed;
    final label = pct >= 90 ? 'Excellente' : pct >= 70 ? 'Correcte' : 'Insuffisante';

    return _SectionCard(
      title: 'Observance thérapeutique',
      icon: Icons.task_alt_rounded,
      iconColor: color,
      child: Column(children: [
        Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$pct%', style: TextStyle(
                  fontSize: 32, fontWeight: FontWeight.w800, color: color)),
                Text(label, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.8))),
              ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('Prises de médicament',
              style: TextStyle(fontSize: 11,
                color: AppColors.textSecondary)),
            const Text('30 derniers jours',
              style: TextStyle(fontSize: 10, color: AppColors.textHint)),
          ]),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: compliance!,
            minHeight: 10,
            backgroundColor: AppColors.cardBorder,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ]),
    );
  }
}

// ─── Stats crises ─────────────────────────────────────────────
class _SeizureStatsCard extends ConsumerWidget {
  final String patientId;
  const _SeizureStatsCard({required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(seizureListProvider(patientId));
    return async.when(
      loading: () => Container(
        height: 90,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(16))),
      error: (_, __) => const SizedBox(),
      data: (list) {
        final now = DateTime.now();
        final thisMonth = list.where((s) =>
          s.datetime.month == now.month &&
          s.datetime.year  == now.year).toList();
        final avgScore = list.isEmpty ? 0.0
          : list.map((s) => s.mlScore)
              .reduce((a, b) => a + b) / list.length;

        return _SectionCard(
          title: 'Statistiques des crises',
          icon: Icons.analytics_rounded,
          iconColor: AppColors.seizureRed,
          child: Row(children: [
            _StatBox(value: '${thisMonth.length}',
              label: 'Ce mois', color: AppColors.seizureRed,
              icon: Icons.calendar_month_rounded),
            _StatDivider(),
            _StatBox(value: '${list.length}',
              label: 'Total', color: AppColors.primary,
              icon: Icons.summarize_rounded),
            _StatDivider(),
            _StatBox(
              value: list.isEmpty
                ? '—'
                : '${(avgScore * 100).toStringAsFixed(0)}%',
              label: 'Score de risque', color: AppColors.warning,
              icon: Icons.psychology_rounded),
          ]),
        );
      },
    );
  }
}

// ─── Déclencheurs ─────────────────────────────────────────────
class _TriggersCard extends StatelessWidget {
  final List<String> triggers;
  const _TriggersCard({required this.triggers});

  @override
  Widget build(BuildContext context) => _SectionCard(
    title: 'Déclencheurs identifiés',
    icon: Icons.bolt_rounded,
    iconColor: AppColors.warning,
    child: triggers.isEmpty
      ? const Text('Aucun déclencheur identifié',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary))
      : Wrap(
          spacing: 8, runSpacing: 8,
          children: triggers.map((t) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF7ED), Color(0xFFFEF3C7)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.4))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.bolt_rounded,
                size: 13, color: AppColors.warning),
              const SizedBox(width: 5),
              Text(t, style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: Color(0xFF92400E))),
            ]),
          )).toList(),
        ),
  );
}

// ─── Notes cliniques ──────────────────────────────────────────
class _ClinicalNotesCard extends StatelessWidget {
  final List<Map<String, dynamic>> notes;
  final String patientName;
  final String patientId;
  final WidgetRef ref;
  final BuildContext context;
  final bool canEdit;
  const _ClinicalNotesCard({
    required this.notes, required this.patientName,
    required this.patientId, required this.ref,
    required this.context, this.canEdit = true});

  Future<void> _deleteNote(Map<String, dynamic> note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer la note ?'),
        content: Text('"${note['text']}"',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirm != true) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(patientId)
        .set({'notes': FieldValue.arrayRemove([note])},
             SetOptions(merge: true));
    ref.invalidate(patientDataProvider(patientId));
  }

  @override
  Widget build(BuildContext _) => _SectionCard(
    title: 'Notes cliniques',
    icon: Icons.notes_rounded,
    iconColor: AppColors.primaryDark,
    child: notes.isEmpty
      ? const Text('Aucune note pour ce patient',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary))
      : Column(children: notes.asMap().entries.map((e) {
          final n = e.value;
          final isLast = e.key == notes.length - 1;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline
              Column(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPale,
                    borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.edit_note_rounded,
                    size: 14, color: AppColors.primary)),
                if (!isLast) Container(
                  width: 1, height: 30,
                  color: AppColors.cardBorder,
                  margin: const EdgeInsets.symmetric(vertical: 4)),
              ]),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n['date'] as String? ?? '',
                        style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                      const SizedBox(height: 3),
                      Text(n['text'] as String? ?? '',
                        style: const TextStyle(
                          fontSize: 13, color: AppColors.textPrimary,
                          height: 1.4)),
                    ],
                  ),
                ),
              ),
              // Bouton supprimer (observateur = masqué)
              if (canEdit)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: AppColors.danger),
                  tooltip: 'Supprimer',
                  onPressed: () => _deleteNote(n),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          );
        }).toList()),
  );
}

// ─── Composants réutilisables ─────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w700,
      color: AppColors.textSecondary, letterSpacing: 0.3));
}

class _SectionCard extends StatelessWidget {
  final String   title;
  final IconData icon;
  final Color    iconColor;
  final Widget   child;
  final Widget?  action;
  const _SectionCard({required this.title, required this.icon,
    required this.iconColor, required this.child, this.action});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 14, offset: const Offset(0, 4)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 15, color: iconColor)),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary)),
          if (action != null) ...[
            const Spacer(),
            action!,
          ],
        ]),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label, value;
  final Color    color;
  const _InfoRow({required this.icon, required this.label,
    required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(7)),
        child: Icon(icon, size: 14, color: color)),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(
        fontSize: 12, color: AppColors.textSecondary,
        fontWeight: FontWeight.w500)),
      const Spacer(),
      Text(value, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary)),
    ]),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Divider(
    height: 1, thickness: 0.6, color: AppColors.cardBorder);
}

class _StatBox extends StatelessWidget {
  final String value, label;
  final Color  color;
  final IconData icon;
  const _StatBox({required this.value, required this.label,
    required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, size: 16, color: color)),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(
        fontSize: 10, color: AppColors.textSecondary),
        textAlign: TextAlign.center),
    ]),
  );
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 48, color: AppColors.cardBorder);
}

class _DoctorActionTile extends StatelessWidget {
  final IconData icon;
  final String   title, subtitle;
  final Color    color;
  final VoidCallback? onTap;
  const _DoctorActionTile({required this.icon, required this.title,
    required this.subtitle, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: onTap == null ? AppColors.surfaceAlt : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.18),
                color.withValues(alpha: 0.08)]),
            borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
              Text(subtitle, style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.chevron_right_rounded, color: color, size: 16)),
      ]),
    ),
  );
}

