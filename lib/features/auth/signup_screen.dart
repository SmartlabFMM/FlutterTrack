import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/epitrack_logo.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/consent_provider.dart';


class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final UserRole _role      = UserRole.family;
  String?  _linkedPatientId;
  bool _obscure1            = true;
  bool _obscure2            = true;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.10), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    WidgetsBinding.instance.addPostFrameCallback((_) => _animCtrl.forward());
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    // Famille : patient obligatoire
    if (_role == UserRole.family && _linkedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Veuillez sélectionner le patient lié à votre compte.'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }
    await ref.read(authProvider.notifier).register(
      name:            _nameCtrl.text.trim(),
      email:           _emailCtrl.text.trim(),
      password:        _passCtrl.text.trim(),
      role:            _role,
      linkedPatientId: _linkedPatientId,
    );
    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.status == AuthStatus.authenticated && auth.isNewAccount) {
      // Nouveau compte → consentement obligatoire
      if (_role == UserRole.patient) {
        context.go('/patient/consent');
      } else {
        // Famille/médecin : pas de consentement patient, aller au dashboard
        // mais d'abord initialiser le consent check pour ne pas bloquer
        await ref.read(consentProvider.notifier).checkForUser(auth.user!.uid);
        context.go(_roleHome(_role));
      }
    } else if (auth.status == AuthStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.errorMessage ?? 'Erreur lors de l\'inscription'),
        backgroundColor: AppColors.danger,
      ));
    }
  }

  String _roleHome(UserRole r) => switch (r) {
    UserRole.patient => '/patient/dashboard',
    UserRole.family  => '/family/dashboard',
    UserRole.doctor  => '/doctor/patients',
    UserRole.admin   => '/admin/dashboard',
  };

  @override
  Widget build(BuildContext context) {
    final auth      = ref.watch(authProvider);
    final isLoading = auth.status == AuthStatus.loading;
    final size      = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Hero gradient
            Container(
              height: size.height * 0.35,
              decoration: const BoxDecoration(
                gradient: AppColors.loginHeroGradient),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  children: [
                    // ── Hero ───────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: Row(children: [
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Container(
                                width: 38, height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25))),
                                child: const Icon(Icons.arrow_back_rounded,
                                  color: Colors.white, size: 20)),
                            ),
                            const SizedBox(width: 14),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const EpiTrackLogoSmall(size: 26),
                              const SizedBox(height: 4),
                              const Text('Créer un compte',
                                style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                              Text('Rejoignez EpiTrack',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.7))),
                            ]),
                          ]),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Card formulaire ─────────────────────────
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                blurRadius: 40, offset: const Offset(0, 16)),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 20, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                // ── Sélecteur de rôle (famille uniquement) ─
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryPale,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2))),
                                  child: Row(children: [
                                    const Icon(Icons.family_restroom_rounded,
                                      color: AppColors.primary, size: 20),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Compte Famille',
                                            style: TextStyle(
                                              fontSize: 13, fontWeight: FontWeight.w700,
                                              color: AppColors.primary)),
                                          Text('Les comptes patients et médecins sont créés par l\'administrateur.',
                                            style: TextStyle(
                                              fontSize: 11, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                  ]),
                                ),
                                const SizedBox(height: 20),

                                // ── Patient lié (famille seulement) ─
                                if (_role == UserRole.family) ...[
                                  _PatientPicker(
                                    selectedId: _linkedPatientId,
                                    onSelected: (id) =>
                                      setState(() => _linkedPatientId = id),
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                // ── Nom complet ────────────────────
                                TextFormField(
                                  controller: _nameCtrl,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: _inputDecor(
                                    label: 'Nom complet',
                                    icon: Icons.badge_rounded),
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Le nom est requis' : null,
                                ),
                                const SizedBox(height: 14),

                                // ── Email ──────────────────────────
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: _inputDecor(
                                    label: 'Adresse email',
                                    icon: Icons.email_outlined),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty)
                                      return 'L\'email est requis';
                                    if (!v.contains('@'))
                                      return 'Email invalide';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                // ── Mot de passe ───────────────────
                                TextFormField(
                                  controller: _passCtrl,
                                  obscureText: _obscure1,
                                  decoration: _inputDecor(
                                    label: 'Mot de passe',
                                    icon: Icons.lock_outline_rounded,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscure1
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                        color: AppColors.textHint, size: 20),
                                      onPressed: () =>
                                        setState(() => _obscure1 = !_obscure1)),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.length < 6)
                                      return 'Minimum 6 caractères';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                // ── Confirmer mot de passe ─────────
                                TextFormField(
                                  controller: _confirmCtrl,
                                  obscureText: _obscure2,
                                  decoration: _inputDecor(
                                    label: 'Confirmer le mot de passe',
                                    icon: Icons.lock_rounded,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscure2
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                        color: AppColors.textHint, size: 20),
                                      onPressed: () =>
                                        setState(() => _obscure2 = !_obscure2)),
                                  ),
                                  validator: (v) => v != _passCtrl.text
                                    ? 'Les mots de passe ne correspondent pas'
                                    : null,
                                ),
                                const SizedBox(height: 24),

                                // ── Bouton créer ───────────────────
                                GestureDetector(
                                  onTap: isLoading ? null : _signup,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    height: 52,
                                    decoration: BoxDecoration(
                                      gradient: isLoading ? null
                                        : const LinearGradient(colors: [
                                            AppColors.primaryDark,
                                            AppColors.primary,
                                            AppColors.primaryLight]),
                                      color: isLoading
                                        ? AppColors.cardBorder : null,
                                      borderRadius: BorderRadius.circular(14)),
                                    child: Center(
                                      child: isLoading
                                        ? const SizedBox(
                                            width: 22, height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5))
                                        : const Text('Créer mon compte',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,)),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // ── Lien connexion ─────────────────
                                Center(
                                  child: GestureDetector(
                                    onTap: () => context.pop(),
                                    child: RichText(text: const TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Déjà un compte ? ',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13)),
                                        TextSpan(
                                          text: 'Se connecter',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700)),
                                      ],
                                    )),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecor({required String label, required IconData icon}) =>
    InputDecoration(
      labelText: label,
      prefixIcon: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.primaryPale,
          borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: AppColors.primary, size: 18)),
    );
}

// ─── Sélecteur de patient (famille) ──────────────────────────
class _PatientPicker extends StatelessWidget {
  final String?      selectedId;
  final ValueChanged<String> onSelected;
  const _PatientPicker({required this.selectedId, required this.onSelected});

  static final _patients = <Map<String, String>>[];

  @override
  Widget build(BuildContext context) {
    final selected = _patients.firstWhere(
      (p) => p['id'] == selectedId,
      orElse: () => {},
    );
    final hasSelection = selected.isNotEmpty;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Patient lié *',
          style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: AppColors.textSecondary)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.tealPale,
            borderRadius: BorderRadius.circular(6)),
          child: const Text('Obligatoire',
            style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: AppColors.teal))),
      ]),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: () => _showPicker(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: hasSelection
              ? AppColors.tealPale : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasSelection ? AppColors.teal : AppColors.cardBorder,
              width: hasSelection ? 1.8 : 1)),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: hasSelection
                  ? AppColors.teal.withValues(alpha: 0.15)
                  : AppColors.cardBorder,
                borderRadius: BorderRadius.circular(8)),
              child: Icon(
                hasSelection
                  ? Icons.person_rounded : Icons.person_search_rounded,
                size: 18,
                color: hasSelection ? AppColors.teal : AppColors.textHint)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasSelection
                  ? selected['name']!
                  : 'Sélectionner le patient…',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: hasSelection
                    ? FontWeight.w700 : FontWeight.w400,
                  color: hasSelection
                    ? AppColors.teal : AppColors.textHint))),
            Icon(Icons.keyboard_arrow_down_rounded,
              color: hasSelection ? AppColors.teal : AppColors.textHint,
              size: 20),
          ]),
        ),
      ),
    ]);
  }

  void _showPicker(BuildContext context) {
    final search = ValueNotifier('');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(children: [
            // Handle
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Choisir le patient',
              style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            // Barre de recherche
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                onChanged: (v) => search.value = v,
                decoration: InputDecoration(
                  hintText: 'Rechercher un patient…',
                  prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.primary, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceAlt,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary, width: 2)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Liste
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: search,
                builder: (_, q, __) {
                  final filtered = _patients.where((p) =>
                    p['name']!.toLowerCase().contains(q.toLowerCase())).toList();
                  return ListView.separated(
                    controller: ctrl,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final p          = filtered[i];
                      final isSelected = p['id'] == selectedId;
                      final initials   = p['name']!
                        .split(' ').take(2).map((w) => w[0]).join();
                      return GestureDetector(
                        onTap: () {
                          onSelected(p['id']!);
                          Navigator.pop(context);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                              ? AppColors.tealPale : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                ? AppColors.teal : AppColors.cardBorder,
                              width: isSelected ? 1.8 : 1)),
                          child: Row(children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  AppColors.teal.withValues(alpha: 0.25),
                                  AppColors.teal.withValues(alpha: 0.10)]),
                                borderRadius: BorderRadius.circular(12)),
                              child: Center(child: Text(initials,
                                style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w800,
                                  color: AppColors.teal)))),
                            const SizedBox(width: 12),
                            Expanded(child: Text(p['name']!,
                              style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600,
                                color: isSelected
                                  ? AppColors.teal : AppColors.textPrimary))),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded,
                                color: AppColors.teal, size: 20),
                          ]),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

