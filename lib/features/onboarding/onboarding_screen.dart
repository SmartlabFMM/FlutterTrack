import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/epitrack_logo.dart';

// ── Modèles ───────────────────────────────────────────────────
class _Feature {
  final IconData icon;
  final String   title;
  final String   description;
  const _Feature({required this.icon, required this.title,
      required this.description});
}

class _OnboardingPage {
  final IconData       icon;
  final String         title;
  final String?        subtitle;
  final List<_Feature> features;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    this.subtitle,
    this.features = const [],
  });
}

// ── Données des 3 pages ───────────────────────────────────────
const _pages = [
  _OnboardingPage(
    icon:  Icons.monitor_heart_rounded,
    title: 'Surveillance cardiaque\net des mouvements',
    subtitle:
        'Bracelet connecté 24h/24 — fréquence cardiaque, mouvements '
        'et conductance cutanée.',
  ),
  _OnboardingPage(
    icon:  Icons.shield_rounded,
    title: 'Détection &\nPrévention',
    features: [
      _Feature(
        icon:        Icons.notifications_active_rounded,
        title:       'Détection automatique des crises',
        description: 'Alertes instantanées envoyées à votre médecin et vos proches.',
      ),
      _Feature(
        icon:        Icons.eco_rounded,
        title:       'Prévention des crises',
        description:
            'Analyse du sommeil, stress et hydratation pour anticiper les risques.',
      ),
    ],
  ),
  _OnboardingPage(
    icon:  Icons.people_rounded,
    title: 'Suivi médical\npartagé',
    subtitle: 'Médecin et famille connectés à votre santé en temps réel.',
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

  void _finish() {
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
    final isLast = _current == _pages.length - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [

            // ── Hero (gradient fixe) ──────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradientPatient,
                borderRadius: BorderRadius.only(
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
                      // Logo + Passer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const EpiTrackLogoSmall(size: 32),
                          if (!isLast)
                            TextButton(
                              onPressed: _finish,
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    Colors.white.withValues(alpha: 0.8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                              ),
                              child: const Text('Passer',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 36),

                      // Icône centrale animée via PageView (index sync)
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
                          _pages[_current].icon,
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

            // ── Corps (PageView) ──────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _current = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _PageBody(page: _pages[i]),
              ),
            ),

            // ── Pied de page ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    // Indicateurs de progression
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        final active = i == _current;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
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
                          gradient: AppColors.heroGradientPatient,
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
                                color: Colors.white),
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
  const _PageBody({required this.page});

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
            height: 1.25,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 20),

        if (page.subtitle != null)
          Text(
            page.subtitle!,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),

        if (page.features.isNotEmpty)
          ...page.features.map((f) => _FeatureTile(feature: f)),
      ],
    ),
  );
}

// ── Bloc feature (page 2) ─────────────────────────────────────
class _FeatureTile extends StatelessWidget {
  final _Feature feature;
  const _FeatureTile({required this.feature});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(feature.icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(feature.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
              const SizedBox(height: 3),
              Text(feature.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5)),
            ],
          ),
        ),
      ],
    ),
  );
}
