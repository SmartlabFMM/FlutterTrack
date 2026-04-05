import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/epitrack_logo.dart';
import '../../providers/consent_provider.dart';

class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _accepted = false;
  bool _loading  = false;
  final _scrollCtrl = ScrollController();
  bool _scrolledToEnd = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.atEdge &&
          _scrollCtrl.position.pixels > 0 &&
          !_scrolledToEnd) {
        setState(() => _scrolledToEnd = true);
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!_accepted) return;
    setState(() => _loading = true);
    await ref.read(consentProvider.notifier).accept();
    if (mounted) context.go('/patient/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // ── Hero ───────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradientPatient,
                borderRadius: BorderRadius.only(
                  bottomLeft:  Radius.circular(32),
                  bottomRight: Radius.circular(32)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                  child: Column(
                    children: [
                      const EpiTrackLogo(size: 72, animate: false),
                      const SizedBox(height: 16),
                      const Text('EpiTrack',
                        style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w900,
                          color: Colors.white, fontFamily: 'Inter',
                          letterSpacing: -0.5)),
                      const SizedBox(height: 6),
                      Text('Confidentialité & Consentement',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ),

            // ── Corps scrollable ────────────────────────────
            Expanded(
              child: Column(
                children: [
                  // Hint de lecture
                  if (!_scrolledToEnd)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.arrow_downward_rounded,
                            size: 13, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text('Faites défiler pour tout lire',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),

                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: const _ConsentBody(),
                    ),
                  ),

                  // ── Pied de page fixe ───────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, -4)),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Checkbox
                          GestureDetector(
                            onTap: () =>
                              setState(() => _accepted = !_accepted),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 22, height: 22,
                                  decoration: BoxDecoration(
                                    color: _accepted
                                      ? AppColors.primary : Colors.transparent,
                                    border: Border.all(
                                      color: _accepted
                                        ? AppColors.primary : AppColors.cardBorder,
                                      width: 2),
                                    borderRadius: BorderRadius.circular(6)),
                                  child: _accepted
                                    ? const Icon(Icons.check_rounded,
                                        size: 14, color: Colors.white)
                                    : null,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'J\'ai lu et j\'accepte la politique de confidentialité '
                                    'et les conditions d\'utilisation d\'EpiTrack.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Bouton
                          SizedBox(
                            width: double.infinity,
                            child: AnimatedOpacity(
                              opacity: _accepted ? 1.0 : 0.45,
                              duration: const Duration(milliseconds: 200),
                              child: GestureDetector(
                                onTap: _loading ? null : _confirm,
                                child: Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: _accepted
                                      ? const LinearGradient(colors: [
                                          AppColors.primaryDark,
                                          AppColors.primary,
                                          AppColors.primaryLight])
                                      : null,
                                    color: _accepted ? null : AppColors.cardBorder,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: _loading
                                      ? const SizedBox(
                                          width: 22, height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5))
                                      : const Text('Accepter et continuer',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            fontFamily: 'Inter')),
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
          ],
        ),
      ),
    );
  }
}

// ─── Corps du texte de consentement ───────────────────────────
class _ConsentBody extends StatelessWidget {
  const _ConsentBody();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: const [

      _Section(
        icon: Icons.health_and_safety_rounded,
        color: AppColors.primary,
        title: 'Collecte de données de santé',
        body:
          'EpiTrack collecte et traite vos données de santé (signaux EEG, '
          'fréquence cardiaque, historique des crises, données de mode de vie) '
          'dans le but exclusif de surveiller votre épilepsie et d\'améliorer '
          'votre prise en charge médicale.',
      ),

      _Section(
        icon: Icons.lock_rounded,
        color: AppColors.teal,
        title: 'Confidentialité & sécurité',
        body:
          'Vos données sont chiffrées et stockées de manière sécurisée. '
          'Elles ne sont accessibles qu\'à vous-même et aux professionnels de '
          'santé qui vous suivent. EpiTrack ne vend jamais vos données à des '
          'tiers et ne les utilise pas à des fins commerciales.',
      ),

      _Section(
        icon: Icons.share_rounded,
        color: Color(0xFF7C3AED),
        title: 'Partage avec votre médecin',
        body:
          'En utilisant EpiTrack, vous autorisez votre médecin traitant '
          'enregistré sur la plateforme à consulter vos données de santé, '
          'générer des rapports médicaux et recevoir des alertes en cas de '
          'crise détectée.',
      ),

      _Section(
        icon: Icons.notifications_active_rounded,
        color: AppColors.warning,
        title: 'Alertes automatiques',
        body:
          'L\'application peut envoyer des alertes automatiques à votre médecin '
          'et à vos contacts d\'urgence lors de la détection d\'une crise. '
          'Ce mécanisme peut être configuré dans les réglages.',
      ),

      _Section(
        icon: Icons.science_rounded,
        color: Color(0xFF0891B2),
        title: 'Analyse par intelligence artificielle',
        body:
          'EpiTrack utilise des modèles d\'IA pour analyser vos signaux '
          'biologiques et détecter les crises d\'épilepsie. Ces analyses sont '
          'indicatives et ne remplacent pas l\'avis d\'un professionnel de santé.',
      ),

      _Section(
        icon: Icons.tune_rounded,
        color: AppColors.textSecondary,
        title: 'Vos droits',
        body:
          'Conformément au RGPD, vous disposez d\'un droit d\'accès, de '
          'rectification, d\'effacement et de portabilité de vos données. '
          'Vous pouvez retirer votre consentement à tout moment depuis les '
          'réglages de l\'application. Le retrait n\'affecte pas la licéité '
          'des traitements antérieurs.',
      ),

      _Section(
        icon: Icons.child_care_rounded,
        color: Color(0xFFDB2777),
        title: 'Mineurs',
        body:
          'Si vous êtes âgé(e) de moins de 18 ans, l\'accord d\'un parent ou '
          'tuteur légal est requis. En acceptant ces termes, vous confirmez '
          'avoir l\'autorisation nécessaire.',
      ),

      Padding(
        padding: EdgeInsets.only(top: 8, bottom: 4),
        child: Text(
          'Dernière mise à jour : 1er avril 2026  ·  EpiTrack v1.0',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textHint),
          textAlign: TextAlign.center,
        ),
      ),
    ],
  );
}

class _Section extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   title;
  final String   body;
  const _Section({required this.icon, required this.color,
    required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: color)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color)),
                const SizedBox(height: 5),
                Text(body,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
