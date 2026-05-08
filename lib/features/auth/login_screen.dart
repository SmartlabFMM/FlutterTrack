import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/epitrack_logo.dart';
import '../../providers/auth_provider.dart';
import 'role_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure       = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _clearError() {
    if (ref.read(authProvider).errorMessage != null) {
      ref.read(authProvider.notifier).clearError();
    }
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

  Future<void> _forgotPassword() async {
    final emailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    final confirmed = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mot de passe oublié ?'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
            'Entrez votre adresse email. Vous recevrez un lien pour réinitialiser votre mot de passe.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Adresse email',
              prefixIcon: Icon(Icons.email_outlined)),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(emailCtrl.text.trim()),
            child: const Text('Envoyer',
              style: TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );

    if (confirmed == null || confirmed.isEmpty || !mounted) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: confirmed);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lien envoyé à $confirmed — vérifiez votre boîte mail.'),
          backgroundColor: AppColors.teal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = e.code == 'user-not-found'
          ? 'Aucun compte associé à cet email.'
          : 'Erreur lors de l\'envoi. Vérifiez l\'adresse.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

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

                    // ── Section hero ──────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 40, 28, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const EpiTrackLogo(size: 80),
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

                    // ── Card formulaire ───────────────────────
                    Container(
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
                            onChanged: (_) => _clearError(),
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
                            onChanged: (_) => _clearError(),
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

                          // Lien mot de passe oublié
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _forgotPassword,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 4)),
                              child: const Text('Mot de passe oublié ?',
                                style: TextStyle(
                                  fontSize: 13, color: AppColors.primary,
                                  fontWeight: FontWeight.w600)),
                            ),
                          ),

                          // Message d'erreur
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

                          // Bouton connexion
                          GestureDetector(
                            onTap: isLoading ? null : _login,
                            child: Container(
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
