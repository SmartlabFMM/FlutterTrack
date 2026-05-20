import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contact_provider.dart';
import '../../services/notification_service.dart';

class EmergencyContactsScreen extends ConsumerWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user       = ref.watch(authProvider).user!;
    final patientId  = user.linkedPatientId ?? user.uid;
    final contacts   = ref.watch(_familyContactsProvider(patientId));
    final doctorSnap = ref.watch(_doctorContactProvider(patientId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts d\'urgence'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/family/dashboard'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddContact(context, patientId),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ajouter',
          style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25))),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded,
                color: AppColors.primary, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text(
                'Ces contacts seront notifiés automatiquement lors de chaque crise détectée.',
                style: TextStyle(fontSize: 12,
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w500))),
            ]),
          ),

          Expanded(
            child: contacts.when(
              loading: () => const Center(
                child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
              data: (list) {
                // Contact médecin (non supprimable)
                final doctor = doctorSnap.valueOrNull;

                final allItems = <Widget>[];

                // Médecin en premier (fixe)
                if (doctor != null) {
                  allItems.add(_ContactCard(
                    name:      doctor['nom']   as String? ?? 'Médecin',
                    phone:     doctor['phone'] as String? ?? '—',
                    role:      'Médecin',
                    deletable: false,
                  ));
                }

                // Contacts ajoutés par la famille
                for (final c in list) {
                  allItems.add(_ContactCard(
                    name:      c.name,
                    phone:     c.phone,
                    role:      c.role,
                    deletable: true,
                    onDelete:  () => _confirmDelete(context, patientId, c),
                  ));
                }

                if (allItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.contacts_outlined,
                          size: 56, color: AppColors.textHint),
                        const SizedBox(height: 12),
                        const Text('Aucun contact ajouté',
                          style: TextStyle(
                            fontSize: 15, color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: allItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => allItems[i],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, String patientId, Contact c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce contact ?'),
        content: Text('${c.name} sera retiré des contacts d\'urgence.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger),
            child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok == true) {
      try { await removeContact(patientId, c); } catch (_) {}
    }
  }

  void _showAddContact(BuildContext context, String patientId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddContactSheet(patientId: patientId),
    );
  }
}

// ── Provider contacts famille (stockés sur le doc patient) ─────
final _familyContactsProvider =
    StreamProvider.family.autoDispose<List<Contact>, String>((ref, patientId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(patientId)
      .snapshots()
      .map((snap) {
    final raw = snap.data()?['contacts'];
    if (raw is! List) return [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(Contact.fromMap)
        .toList();
  });
});

// ── Provider médecin lié au patient ───────────────────────────
final _doctorContactProvider =
    StreamProvider.family.autoDispose<Map<String, dynamic>?, String>(
        (ref, patientId) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'doctor')
      .limit(1)
      .snapshots()
      .map((snap) => snap.docs.isEmpty ? null : snap.docs.first.data());
});

// ── Carte contact ─────────────────────────────────────────────
class _ContactCard extends StatelessWidget {
  final String    name, phone, role;
  final bool      deletable;
  final VoidCallback? onDelete;

  const _ContactCard({
    required this.name,
    required this.phone,
    required this.role,
    required this.deletable,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDoctor = role == 'Médecin';
    final color    = isDoctor ? AppColors.primaryDark : AppColors.teal;
    final bgColor  = isDoctor
        ? AppColors.primarySurface
        : AppColors.tealPale.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.65)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3)),
              ],
            ),
            child: Center(child: Text(
              name.isNotEmpty ? name.substring(0, 1) : '?',
              style: const TextStyle(fontSize: 22,
                fontWeight: FontWeight.w800, color: Colors.white)))),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                style: const TextStyle(fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(phone,
                style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
            ])),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20)),
                child: Text(role,
                  style: TextStyle(fontSize: 11,
                    color: color, fontWeight: FontWeight.w700))),
              if (deletable && onDelete != null) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(20)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.delete_outline_rounded,
                        size: 11, color: AppColors.danger),
                      SizedBox(width: 3),
                      Text('Supprimer',
                        style: TextStyle(
                          fontSize: 10, color: AppColors.danger,
                          fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ],
            ],
          ),
        ]),
        const SizedBox(height: 14),
        Divider(height: 1, thickness: 0.6,
          color: color.withValues(alpha: 0.2)),
        const SizedBox(height: 12),
        _CallButton(phone: phone),
      ]),
    );
  }
}

class _CallButton extends StatefulWidget {
  final String phone;
  const _CallButton({required this.phone});
  @override
  State<_CallButton> createState() => _CallButtonState();
}

class _CallButtonState extends State<_CallButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _pressed = true),
    onTapUp: (_) {
      setState(() => _pressed = false);
      NotificationService.callEmergencyContact(widget.phone);
    },
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: _pressed
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.primaryPale,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _pressed
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.4))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.call_rounded, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        const Text('Appeler',
          style: TextStyle(fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primary)),
      ]),
    ),
  );
}

// ── Sheet d'ajout de contact ──────────────────────────────────
class _AddContactSheet extends StatefulWidget {
  final String patientId;
  const _AddContactSheet({required this.patientId});
  @override
  State<_AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends State<_AddContactSheet> {
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _role     = 'Famille';
  bool   _saving   = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await addContact(widget.patientId, Contact(
        name:  _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        role:  _role,
      ));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom),
    child: Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
          decoration: BoxDecoration(
            color: AppColors.cardBorder,
            borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        const Text('Nouveau contact d\'urgence',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Nom complet',
            prefixIcon: Icon(Icons.person_rounded))),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Numéro de téléphone',
            prefixIcon: Icon(Icons.call_rounded))),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _role,
          decoration: const InputDecoration(
            labelText: 'Relation',
            prefixIcon: Icon(Icons.group_rounded)),
          items: ['Famille', 'Médecin']
              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
              .toList(),
          onChanged: (v) => setState(() => _role = v ?? _role),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
            child: _saving
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
              : const Text('Enregistrer',
                  style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    ),
  );
}
