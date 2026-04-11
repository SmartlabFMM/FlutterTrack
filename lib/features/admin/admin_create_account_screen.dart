import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';

class AdminCreateAccountScreen extends ConsumerStatefulWidget {
  const AdminCreateAccountScreen({super.key});
  @override
  ConsumerState<AdminCreateAccountScreen> createState() =>
      _AdminCreateAccountScreenState();
}

class _AdminCreateAccountScreenState
    extends ConsumerState<AdminCreateAccountScreen> {
  final _formKey   = GlobalKey<FormState>();
  UserRole _role   = UserRole.patient;
  bool _obscure    = true;
  bool _loading    = false;

  // Communs
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  // Patient uniquement
  final _ageCtrl     = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();

  // Médecin uniquement
  final _specCtrl  = TextEditingController();

  // Famille uniquement
  String? _linkedPatientId;

  @override
  void dispose() {
    for (final c in [_nameCtrl, _emailCtrl, _passCtrl,
      _ageCtrl, _phoneCtrl, _addressCtrl, _specCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _resetFields() {
    _ageCtrl.clear(); _phoneCtrl.clear(); _addressCtrl.clear();
    _specCtrl.clear(); _linkedPatientId = null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_role == UserRole.family && _linkedPatientId == null) {
      _snack('Veuillez sélectionner le patient lié.', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final extra = <String, dynamic>{};
      if (_role == UserRole.patient) {
        if (_ageCtrl.text.isNotEmpty)
          extra['age']     = int.tryParse(_ageCtrl.text.trim()) ?? 0;
        if (_phoneCtrl.text.isNotEmpty)
          extra['phone']   = _phoneCtrl.text.trim();
        if (_addressCtrl.text.isNotEmpty)
          extra['address'] = _addressCtrl.text.trim();
      }
      if (_role == UserRole.doctor) {
        if (_specCtrl.text.isNotEmpty)
          extra['specialite'] = _specCtrl.text.trim();
      }

      await createUserAsAdmin(
        name:            _nameCtrl.text.trim(),
        email:           _emailCtrl.text.trim(),
        password:        _passCtrl.text.trim(),
        role:            _role,
        linkedPatientId: _linkedPatientId,
        extraData:       extra,
      );

      if (mounted) {
        _snack('Compte créé avec succès !');
        context.pop();
      }
    } catch (e) {
      if (mounted) _snack('Erreur : $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.danger : AppColors.teal,
      behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(allUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nouveau compte'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop()),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── Sélecteur de rôle ────────────────────────────
            const _SectionTitle('Type de compte'),
            const SizedBox(height: 10),
            Row(children: [
              _RoleBtn(
                label: 'Patient',
                icon: Icons.person_rounded,
                color: AppColors.primary,
                selected: _role == UserRole.patient,
                onTap: () => setState(() {
                  _role = UserRole.patient; _resetFields(); })),
              const SizedBox(width: 8),
              _RoleBtn(
                label: 'Médecin',
                icon: Icons.medical_services_rounded,
                color: AppColors.tealDark,
                selected: _role == UserRole.doctor,
                onTap: () => setState(() {
                  _role = UserRole.doctor; _resetFields(); })),
              const SizedBox(width: 8),
              _RoleBtn(
                label: 'Famille',
                icon: Icons.family_restroom_rounded,
                color: const Color(0xFF7C3AED),
                selected: _role == UserRole.family,
                onTap: () => setState(() {
                  _role = UserRole.family; _resetFields(); })),
            ]),
            const SizedBox(height: 24),

            // ── Champs communs ───────────────────────────────
            const _SectionTitle('Informations du compte'),
            const SizedBox(height: 12),
            _Field('Nom complet', Icons.badge_rounded, _nameCtrl,
              required: true),
            _Field('Adresse email', Icons.email_rounded, _emailCtrl,
              required: true,
              keyboardType: TextInputType.emailAddress),
            _PassField(ctrl: _passCtrl, obscure: _obscure,
              onToggle: () => setState(() => _obscure = !_obscure)),

            // ── Champs Patient ───────────────────────────────
            if (_role == UserRole.patient) ...[
              const SizedBox(height: 8),
              const _SectionTitle('Informations personnelles'),
              const SizedBox(height: 12),
              _Field('Âge', Icons.cake_rounded, _ageCtrl,
                keyboardType: TextInputType.number),
              _Field('Téléphone', Icons.call_rounded, _phoneCtrl,
                keyboardType: TextInputType.phone),
              _Field('Adresse exacte', Icons.location_on_rounded,
                _addressCtrl, maxLines: 2),
            ],

            // ── Champs Médecin ───────────────────────────────
            if (_role == UserRole.doctor) ...[
              const SizedBox(height: 8),
              const _SectionTitle('Informations professionnelles'),
              const SizedBox(height: 12),
              _Field('Spécialité', Icons.work_rounded, _specCtrl),
            ],

            // ── Champs Famille ───────────────────────────────
            if (_role == UserRole.family) ...[
              const SizedBox(height: 8),
              const _SectionTitle('Patient lié'),
              const SizedBox(height: 12),
              users.when(
                data: (list) {
                  final patients = list
                    .where((u) => u.role == UserRole.patient)
                    .toList();
                  if (patients.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(12)),
                      child: const Text(
                        'Aucun patient enregistré. Créez d\'abord un compte patient.',
                        style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)));
                  }
                  return DropdownButtonFormField<String>(
                    value: _linkedPatientId,
                    decoration: InputDecoration(
                      labelText: 'Sélectionner le patient *',
                      prefixIcon: const Icon(
                        Icons.person_search_rounded, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: AppColors.surfaceAlt),
                    items: patients.map((p) => DropdownMenuItem(
                      value: p.uid,
                      child: Text(p.name))).toList(),
                    onChanged: (v) =>
                      setState(() => _linkedPatientId = v),
                    validator: (_) => _linkedPatientId == null
                      ? 'Sélectionnez un patient' : null,
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox(),
              ),
            ],

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
                child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                  : const Text('Créer le compte',
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets ─────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController ctrl;
  final bool required;
  final TextInputType? keyboardType;
  final int maxLines;
  const _Field(this.label, this.icon, this.ctrl, {
    this.required = false,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppColors.surfaceAlt),
      validator: required
        ? (v) => (v == null || v.trim().isEmpty) ? '$label requis' : null
        : null,
    ),
  );
}

class _PassField extends StatelessWidget {
  final TextEditingController ctrl;
  final bool obscure;
  final VoidCallback onToggle;
  const _PassField({required this.ctrl,
    required this.obscure, required this.onToggle});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: 'Mot de passe',
        prefixIcon: const Icon(Icons.lock_rounded, size: 18),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
              ? Icons.visibility_off_rounded
              : Icons.visibility_rounded,
            size: 18, color: AppColors.textHint),
          onPressed: onToggle),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppColors.surfaceAlt),
      validator: (v) => (v == null || v.trim().length < 6)
        ? 'Minimum 6 caractères' : null,
    ),
  );
}

class _RoleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _RoleBtn({required this.label, required this.icon,
    required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppColors.cardBorder)),
        child: Column(children: [
          Icon(icon, size: 22,
            color: selected ? Colors.white : color),
          const SizedBox(height: 5),
          Text(label,
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: selected ? Colors.white : color)),
        ]),
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w700,
      color: AppColors.textSecondary));
}
