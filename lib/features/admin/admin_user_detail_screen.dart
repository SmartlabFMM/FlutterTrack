import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';

// Provider pour lire les données complètes d'un utilisateur en temps réel
final _userDataProvider =
  StreamProvider.family<Map<String, dynamic>?, String>((ref, uid) {
    return FirebaseFirestore.instance
      .collection('users').doc(uid).snapshots()
      .map((s) => s.exists ? s.data() : null);
  });

class AdminUserDetailScreen extends ConsumerStatefulWidget {
  final String userId;
  const AdminUserDetailScreen({super.key, required this.userId});
  @override
  ConsumerState<AdminUserDetailScreen> createState() =>
      _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState
    extends ConsumerState<AdminUserDetailScreen> {
  bool _loading = false;

  Color _roleColor(UserRole r) => switch (r) {
    UserRole.patient => AppColors.primary,
    UserRole.doctor  => AppColors.tealDark,
    UserRole.family  => const Color(0xFF7C3AED),
    UserRole.admin   => const Color(0xFFD97706),
  };

  String _roleLabel(UserRole r) => switch (r) {
    UserRole.patient => 'Patient',
    UserRole.doctor  => 'Médecin',
    UserRole.family  => 'Famille',
    UserRole.admin   => 'Admin',
  };

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.danger : AppColors.teal,
      behavior: SnackBarBehavior.floating));
  }

  Future<void> _toggleDisable(UserModel user) async {
    final newState = !user.disabled;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(newState ? 'Désactiver le compte ?' : 'Réactiver le compte ?'),
        content: Text(newState
          ? 'Le compte de ${user.name} sera désactivé. Il ne pourra plus se connecter.'
          : 'Le compte de ${user.name} sera réactivé.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: newState ? AppColors.danger : AppColors.teal),
            child: Text(newState ? 'Désactiver' : 'Réactiver')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _loading = true);
    try {
      await setUserDisabled(widget.userId, newState);
      _snack(newState ? 'Compte désactivé' : 'Compte réactivé');
    } catch (e) {
      _snack('Erreur : $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer le compte ?'),
        content: Text(
          'Le dossier de ${user.name} sera supprimé définitivement de l\'application.\n\n'
          'Note : le compte Firebase Auth reste actif.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger),
            child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _loading = true);
    try {
      await deleteUserAccount(widget.userId);
      if (mounted) {
        _snack('Compte supprimé');
        context.pop();
      }
    } catch (e) {
      if (mounted) _snack('Erreur : $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeRole(UserModel user, List<UserModel> allUsers) async {
    UserRole? newRole = user.role;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Changer le rôle'),
        content: StatefulBuilder(
          builder: (ctx, setS) => Column(
            mainAxisSize: MainAxisSize.min,
            children: UserRole.values.map((r) => RadioListTile<UserRole>(
              title: Text(_roleLabel(r)),
              value: r,
              groupValue: newRole,
              onChanged: (v) => setS(() => newRole = v),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (newRole != null && newRole != user.role) {
                await updateUserRole(widget.userId, newRole!);
                _snack('Rôle mis à jour');
              }
            },
            child: const Text('Confirmer')),
        ],
      ),
    );
  }

  Future<void> _linkToPatient(List<UserModel> allUsers) async {
    final patients = allUsers.where(
      (u) => u.role == UserRole.patient).toList();
    if (patients.isEmpty) {
      _snack('Aucun patient disponible', error: true);
      return;
    }
    String? selected;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Lier au patient'),
        content: StatefulBuilder(
          builder: (ctx, setS) => Column(
            mainAxisSize: MainAxisSize.min,
            children: patients.map((p) => RadioListTile<String>(
              title: Text(p.name),
              subtitle: Text(p.email,
                style: const TextStyle(fontSize: 11)),
              value: p.uid,
              groupValue: selected,
              onChanged: (v) => setS(() => selected = v),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (selected != null) {
                await linkFamilyToPatient(widget.userId, selected!);
                _snack('Lien famille–patient mis à jour');
              }
            },
            child: const Text('Confirmer')),
        ],
      ),
    );
  }

  // ── Appel téléphonique ───────────────────────────────────────
  Future<void> _callPatient(String phone) async {
    if (phone.isEmpty) {
      _snack('Aucun numéro renseigné pour ce patient', error: true);
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _snack('Impossible d\'appeler $phone', error: true);
    }
  }

  // ── Planification RDV ────────────────────────────────────────
  Future<void> _showRdvSheet(String currentRdv) async {
    DateTime? pickedDate;
    final timeCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24))),
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
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.calendar_today_rounded,
                      color: Color(0xFF7C3AED), size: 18)),
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
                      context: context,
                      initialDate: DateTime.now()
                        .add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now()
                        .add(const Duration(days: 365)),
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
                            ? AppColors.textHint
                            : AppColors.textPrimary,
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
                        side: const BorderSide(
                          color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                      child: const Text('Annuler',
                        style: TextStyle(
                          color: AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (pickedDate == null ||
                            timeCtrl.text.trim().isEmpty) {
                          return;
                        }
                        final label =
                          '${DateFormat('EEEE d MMMM', 'fr').format(pickedDate!)}'
                          ' · ${timeCtrl.text.trim()}';
                        await FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.userId)
                          .set({'nextRdv': label},
                            SetOptions(merge: true));
                        if (ctx.mounted) Navigator.pop(ctx);
                        _snack('Rendez-vous planifié');
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

  Future<void> _editInfo(UserModel user) async {
    final nameCtrl    = TextEditingController(text: user.name);
    final phoneCtrl   = TextEditingController();
    final ageCtrl     = TextEditingController();
    final addressCtrl = TextEditingController();
    final specCtrl    = TextEditingController();

    // Charger les données existantes
    final doc = await FirebaseFirestore.instance
      .collection('users').doc(widget.userId).get();
    final data = doc.data() ?? {};
    phoneCtrl.text   = data['phone']?.toString() ?? '';
    ageCtrl.text     = data['age']?.toString() ?? '';
    addressCtrl.text = data['address']?.toString() ?? '';
    specCtrl.text    = data['specialite']?.toString() ?? '';

    if (!mounted) return;
    await showModalBottomSheet(
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                const Text('Modifier les informations',
                  style: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),

                // Commun à tous
                _editField('Nom complet', nameCtrl),

                // Patient : âge, téléphone, adresse
                if (user.role == UserRole.patient) ...[
                  _editField('Âge', ageCtrl,
                    keyboardType: TextInputType.number),
                  _editField('Téléphone', phoneCtrl,
                    keyboardType: TextInputType.phone),
                  _editField('Adresse exacte', addressCtrl,
                    maxLines: 2),
                ],

                // Médecin : spécialité
                if (user.role == UserRole.doctor)
                  _editField('Spécialité', specCtrl),

                // Famille : téléphone, adresse
                if (user.role == UserRole.family) ...[
                  _editField('Téléphone', phoneCtrl,
                    keyboardType: TextInputType.phone),
                  _editField('Adresse exacte', addressCtrl,
                    maxLines: 2),
                ],

                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final toSave = <String, dynamic>{
                        'nom': nameCtrl.text.trim(),
                      };
                      if (user.role == UserRole.patient) {
                        toSave['age']     =
                          int.tryParse(ageCtrl.text.trim()) ?? 0;
                        toSave['phone']   = phoneCtrl.text.trim();
                        toSave['address'] = addressCtrl.text.trim();
                      }
                      if (user.role == UserRole.doctor) {
                        toSave['specialite'] = specCtrl.text.trim();
                      }
                      if (user.role == UserRole.family) {
                        toSave['phone']   = phoneCtrl.text.trim();
                        toSave['address'] = addressCtrl.text.trim();
                      }
                      await FirebaseFirestore.instance
                        .collection('users').doc(widget.userId)
                        .set(toSave, SetOptions(merge: true));
                      if (context.mounted) Navigator.pop(context);
                      _snack('Informations mises à jour');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                    child: const Text('Enregistrer',
                      style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _editField(String label, TextEditingController ctrl, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppColors.surfaceAlt),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final users    = ref.watch(allUsersProvider);
    final dataSnap = ref.watch(_userDataProvider(widget.userId));
    final data     = dataSnap.value;

    return users.when(
      data: (allUsers) {
        final user = allUsers.where(
          (u) => u.uid == widget.userId).firstOrNull;

        if (user == null) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop())),
            body: const Center(
              child: Text('Compte introuvable')));
        }

        final color = _roleColor(user.role);

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(user.name),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop()),
          ),
          body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [

                  // ── Profil card ─────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder)),
                    child: Row(children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18)),
                        child: Center(
                          child: Text(
                            user.name.isNotEmpty
                              ? user.name.substring(0, 1).toUpperCase()
                              : '?',
                            style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800,
                              color: color)))),
                      const SizedBox(width: 16),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name,
                            style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                          Text(user.email,
                            style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20)),
                              child: Text(_roleLabel(user.role),
                                style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700,
                                  color: color))),
                            if (user.disabled) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.dangerLight,
                                  borderRadius: BorderRadius.circular(20)),
                                child: const Text('Désactivé',
                                  style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700,
                                    color: AppColors.danger))),
                            ],
                          ]),
                        ],
                      )),
                    ]),
                  ),

                  const SizedBox(height: 20),
                  const _SectionLabel('Gestion du compte'),
                  const SizedBox(height: 10),

                  // ── Actions ─────────────────────────────────
                  _ActionTile(
                    icon: Icons.edit_rounded,
                    color: AppColors.primary,
                    title: 'Modifier les informations',
                    subtitle: switch (user.role) {
                      UserRole.patient => 'Nom, âge, téléphone, adresse',
                      UserRole.doctor  => 'Nom, spécialité',
                      UserRole.family  => 'Nom, téléphone, adresse',
                      UserRole.admin   => 'Nom',
                    },
                    onTap: () => _editInfo(user)),

                  if (user.role == UserRole.patient) ...[
                    _ActionTile(
                      icon: Icons.calendar_today_rounded,
                      color: const Color(0xFF7C3AED),
                      title: 'Planifier un rendez-vous',
                      subtitle: data?['nextRdv'] as String? ?? 'Aucun RDV planifié',
                      onTap: () => _showRdvSheet(
                        data?['nextRdv'] as String? ?? '')),
                    _ActionTile(
                      icon: Icons.call_rounded,
                      color: AppColors.tealDark,
                      title: 'Appeler le patient',
                      subtitle: data?['phone'] as String? ?? 'Aucun numéro',
                      onTap: () => _callPatient(
                        data?['phone'] as String? ?? '')),
                  ],

                  _ActionTile(
                    icon: Icons.manage_accounts_rounded,
                    color: const Color(0xFFD97706),
                    title: 'Changer le rôle',
                    subtitle: 'Rôle actuel : ${_roleLabel(user.role)}',
                    onTap: () => _changeRole(user, allUsers)),


                  if (user.role == UserRole.family)
                    _ActionTile(
                      icon: Icons.link_rounded,
                      color: const Color(0xFF7C3AED),
                      title: 'Lier au patient',
                      subtitle: 'Associer ce membre famille à un patient',
                      onTap: () => _linkToPatient(allUsers)),

                  const SizedBox(height: 8),
                  const _SectionLabel('Zone dangereuse'),
                  const SizedBox(height: 10),

                  _ActionTile(
                    icon: user.disabled
                      ? Icons.check_circle_outline_rounded
                      : Icons.block_rounded,
                    color: user.disabled ? AppColors.teal : AppColors.warning,
                    title: user.disabled
                      ? 'Réactiver le compte'
                      : 'Désactiver le compte',
                    subtitle: user.disabled
                      ? 'Le compte sera accessible à nouveau'
                      : 'L\'utilisateur ne pourra plus se connecter',
                    onTap: () => _toggleDisable(user)),

                  _ActionTile(
                    icon: Icons.delete_forever_rounded,
                    color: AppColors.danger,
                    title: 'Supprimer le compte',
                    subtitle: 'Suppression définitive du dossier',
                    onTap: () => _delete(user)),
                ],
              ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop())),
        body: const Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop())),
        body: Center(child: Text('Erreur : $e'))),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   title, subtitle;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.color,
    required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder)),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: color == AppColors.danger
                  ? AppColors.danger
                  : AppColors.textPrimary)),
            Text(subtitle,
              style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
          ],
        )),
        Icon(Icons.chevron_right_rounded,
          size: 18, color: AppColors.textHint),
      ]),
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
