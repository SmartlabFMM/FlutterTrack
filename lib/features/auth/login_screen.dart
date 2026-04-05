import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/epitrack_logo.dart';
import '../../providers/auth_provider.dart';
import 'role_router.dart';
import 'signup_screen.dart';

const _demoAccounts = [
  {
    'label': 'Patient',
    'email': 'patient@epitrack.com',
    'password': 'patient123',
    'icon': Icons.person_rounded,
    'color': AppColors.primaryLight,
  },
  {
    'label': 'Famille',
    'email': 'famille@epitrack.com',
    'password': 'famille123',
    'icon': Icons.family_restroom_rounded,
    'color': AppColors.tealLight,
  },
  {
    'label': 'Médecin',
    'email': 'docteur@epitrack.com',
    'password': 'docteur123',
    'icon': Icons.medical_services_rounded,
    'color': AppColors.primarySurface,
  },
];

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure       = true;
  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    WidgetsBinding.instance.addPostFrameCallback((_) => _animCtrl.forward());
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    await ref.read(authProvider.notifier)
        .login(_emailCtrl.text.trim(), _passwordCtrl.text.trim());
    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.status == AuthStatus.authenticated) {
      context.go(RoleRouter.redirectForRole(auth.user!.role));
    }
  }

  void _fillDemo(String email, String password) {
    setState(() {
      _emailCtrl.text    = email;
      _passwordCtrl.text = password;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth      = ref.watch(authProvider);
    final isLoading = auth.status == AuthStatus.loading;
    final size      = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // ── Hero gradient background ──────────────────────
            Container(
              height: size.height * 0.42,
              decoration: const BoxDecoration(
                gradient: AppColors.loginHeroGradient,
              ),
            ),

            // ── Contenu scrollable ────────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Section hero (sur fond sombre) ─────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 40, 28, 0),
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Logo custom animé
                              const EpiTrackLogo(size: 80, animate: true),
                              const SizedBox(height: 20),
                              const Text('EpiTrack',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                  fontFamily: 'Inter')),
                              const SizedBox(height: 6),
                              Text(AppStrings.appTagline,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.72),
                                  fontFamily: 'Inter')),
                              const SizedBox(height: 48),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Card flottante (formulaire) ─────────────
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                blurRadius: 40,
                                offset: const Offset(0, 16)),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 8)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Connexion',
                                style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  fontFamily: 'Inter')),
                              const SizedBox(height: 4),
                              const Text('Accédez à votre espace personnel',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                              const SizedBox(height: 24),

                              // Champ email
                              TextField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(
                                  fontFamily: 'Inter', fontSize: 15,
                                  color: AppColors.textPrimary),
                                decoration: InputDecoration(
                                  labelText: AppStrings.email,
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(10),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryPale,
                                      borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.email_outlined,
                                      color: AppColors.primary, size: 18)),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Champ mot de passe
                              TextField(
                                controller: _passwordCtrl,
                                obscureText: _obscure,
                                style: const TextStyle(
                                  fontFamily: 'Inter', fontSize: 15,
                                  color: AppColors.textPrimary),
                                decoration: InputDecoration(
                                  labelText: AppStrings.password,
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(10),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryPale,
                                      borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.lock_outline,
                                      color: AppColors.primary, size: 18)),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                      color: AppColors.textHint, size: 20),
                                    onPressed: () =>
                                      setState(() => _obscure = !_obscure)),
                                ),
                                onSubmitted: (_) => isLoading ? null : _login(),
                              ),

                              // Erreur
                              if (auth.errorMessage != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.dangerLight,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.danger.withValues(alpha: 0.25))),
                                  child: Row(children: [
                                    const Icon(Icons.error_outline,
                                      color: AppColors.danger, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(auth.errorMessage!,
                                      style: const TextStyle(
                                        color: AppColors.danger, fontSize: 13))),
                                  ]),
                                ),
                              ],

                              const SizedBox(height: 24),

                              // Bouton connexion avec gradient
                              GestureDetector(
                                onTap: isLoading ? null : _login,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: isLoading ? null : const LinearGradient(
                                      colors: [
                                        AppColors.primaryDark,
                                        AppColors.primary,
                                        AppColors.primaryLight,
                                      ]),
                                    color: isLoading ? AppColors.cardBorder : null,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: isLoading ? [] : [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.35),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6)),
                                    ],
                                  ),
                                  child: Center(
                                    child: isLoading
                                      ? const SizedBox(
                                          width: 22, height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white))
                                      : const Text(AppStrings.loginButton,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'Inter')),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Créer un compte ────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Center(
                        child: GestureDetector(
                          onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                              builder: (_) => const SignupScreen())),
                          child: RichText(text: const TextSpan(children: [
                            TextSpan(
                              text: 'Pas encore de compte ? ',
                              style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                            TextSpan(
                              text: 'Créer un compte',
                              style: TextStyle(
                                color: AppColors.primary, fontSize: 13,
                                fontWeight: FontWeight.w700)),
                          ])),
                        ),
                      ),
                    ),

                    // ── Comptes de démonstration ───────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                width: 24, height: 1,
                                color: AppColors.cardBorder),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text('Comptes de démonstration',
                                  style: TextStyle(
                                    fontSize: 12, color: AppColors.textHint,
                                    fontWeight: FontWeight.w500))),
                              Expanded(child: Container(
                                height: 1, color: AppColors.cardBorder)),
                            ]),
                            const SizedBox(height: 12),
                            Row(
                              children: _demoAccounts.map((account) {
                                final color = account['color'] as Color;
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: account == _demoAccounts.last ? 0 : 8),
                                    child: GestureDetector(
                                      onTap: () => _fillDemo(
                                        account['email'] as String,
                                        account['password'] as String),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: AppColors.cardBorder),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.04),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2)),
                                          ],
                                        ),
                                        child: Column(children: [
                                          Container(
                                            width: 36, height: 36,
                                            decoration: BoxDecoration(
                                              color: color.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(10)),
                                            child: Icon(
                                              account['icon'] as IconData,
                                              color: color, size: 18)),
                                          const SizedBox(height: 6),
                                          Text(account['label'] as String,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary)),
                                        ]),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Center(
                      child: Text('EpiTrack v1.0 — Prototype médical',
                        style: TextStyle(
                          fontSize: 11, color: AppColors.textHint))),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
