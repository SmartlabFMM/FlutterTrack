import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/epitrack_logo.dart';

// ── Données des pages ─────────────────────────────────────────
class _OnboardingPage {
  final IconData  icon;
  final Color     iconColor;
  final Gradient  gradient;
  final String    title;
  final String    subtitle;

  const _OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.gradient,
    required this.title,
    required this.subtitle,
  });
}

const _pages = [
  _OnboardingPage(
    icon:      Icons.monitor_heart_rounded,
    iconColor: AppColors.primary,
    gradient:  AppColors.heroGradientPatient,
    title:     'Surveillance cardiaque\nen temps réel',
    subtitle:
      'EpiTrack surveille votre fréquence cardiaque et vos mouvements '
      'en temps réel grâce à un bracelet connecté, 24h/24.',
  ),
  _OnboardingPage(
    icon:      Icons.notifications_active_rounded,
    iconColor: AppColors.primary,
    gradient:  AppColors.heroGradientPatient,
    title:     'Détection automatique\ndes crises',
    subtitle:
      'L\'application détecte les crises d\'épilepsie en temps réel '
      'et envoie immédiatement des alertes à votre médecin et à vos proches.',
  ),
  _OnboardingPage(
    icon:      Icons.people_rounded,
    iconColor: AppColors.tealDark,
    gradient:  LinearGradient(
      begin: Alignment.topLeft,
      end:   Alignment.bottomRight,
      colors: [Color(0xFF2E9088), Color(0xFF3DADA0), Color(0xFF5EC5B8)],
    ),
    title:     'Suivi médical\npartagé',
    subtitle:
      'Votre médecin et votre famille consultent vos rapports, '
      'suivent votre état de santé et restent connectés à votre bien-être.',
  ),
];

// ── Écran principal ───────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (mounted) context.go('/login');
  }

  void _next() {
    if (_current < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_current];
    final isLast = _current == _pages.length - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [

            // ── Hero ─────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: page.gradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft:  Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                  child: Column(
                    children: [
                      // Ligne du haut: logo + skip
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const EpiTrackLogoSmall(size: 32),
                          if (!isLast)
                            TextButton(
                              onPressed: _finish,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white.withValues(alpha: 0.8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              ),
                              child: const Text('Passer',
                                style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 36),

                      // Icône centrale dans cercle
                      Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2),
                        ),
                        child: Icon(
                          page.icon,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),

            // ── Corps scrollable (PageView) ────────────────────
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _current = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _PageBody(page: _pages[i]),
              ),
            ),

            // ── Pied de page fixe ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    // Points indicateurs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        final active = i == _current;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width:  active ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active
                              ? AppColors.primary
                              : AppColors.cardBorder,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),

                    // Bouton Suivant / Commencer
                    GestureDetector(
                      onTap: _next,
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: page.gradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 6)),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLast ? 'Commencer' : 'Suivant',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'Inter'),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isLast
                                ? Icons.check_circle_rounded
                                : Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20),
                          ],
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
}

// ── Corps de chaque page ──────────────────────────────────────
class _PageBody extends StatelessWidget {
  final _OnboardingPage page;
  const _PageBody({super.key, required this.page});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 32, 28, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          page.title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
            height: 1.25,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          page.subtitle,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.6,
            fontFamily: 'Inter',
          ),
        ),
      ],
    ),
  );
}
