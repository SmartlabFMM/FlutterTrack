import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Fond décoratif médical avec icônes flottantes en filigrane
class MedicalBackground extends StatelessWidget {
  final Widget child;
  final bool dense; // true = plus d'icônes (pour grandes pages)

  const MedicalBackground({
    super.key,
    required this.child,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Dégradé de fond
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.appBackground),
          ),
        ),

        // Icônes décoratives en filigrane (RepaintBoundary = jamais repeint)
        Positioned.fill(
          child: RepaintBoundary(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _MedicalPatternPainter(dense: dense),
              ),
            ),
          ),
        ),

        // Contenu
        child,
      ],
    );
  }
}

class _MedicalPatternPainter extends CustomPainter {
  final bool dense;
  _MedicalPatternPainter({required this.dense});

  @override
  void paint(Canvas canvas, Size size) {
    final color = AppColors.primary.withOpacity(0.18);

    final icons = <_FloatingIcon>[
      // Ligne haute
      _FloatingIcon(Icons.favorite_rounded,          0.08, 0.06, 60),
      _FloatingIcon(Icons.medication_rounded,        0.55, 0.03, 55),
      _FloatingIcon(Icons.monitor_heart_rounded,     0.88, 0.08, 65),

      // Milieu haut
      _FloatingIcon(Icons.healing_rounded,           0.22, 0.18, 50),
      _FloatingIcon(Icons.local_hospital_rounded,    0.72, 0.15, 58),

      // Milieu
      _FloatingIcon(Icons.biotech_rounded,           0.05, 0.38, 68),
      _FloatingIcon(Icons.vaccines_rounded,          0.40, 0.32, 52),
      _FloatingIcon(Icons.medical_services_rounded,  0.85, 0.40, 60),

      // Milieu bas
      _FloatingIcon(Icons.science_rounded,           0.18, 0.55, 54),
      _FloatingIcon(Icons.psychology_rounded,        0.65, 0.58, 58),

      // Bas
      _FloatingIcon(Icons.health_and_safety_rounded, 0.08, 0.75, 62),
      _FloatingIcon(Icons.monitor_rounded,           0.45, 0.72, 50),
      _FloatingIcon(Icons.bloodtype_rounded,         0.85, 0.70, 56),

      // Très bas
      _FloatingIcon(Icons.elderly_rounded,           0.25, 0.88, 52),
      _FloatingIcon(Icons.personal_injury_rounded,   0.68, 0.85, 58),
      _FloatingIcon(Icons.accessibility_new_rounded, 0.90, 0.92, 64),
    ];

    final extraIcons = dense ? <_FloatingIcon>[
      _FloatingIcon(Icons.coronavirus_rounded,          0.35, 0.10, 48),
      _FloatingIcon(Icons.wheelchair_pickup_rounded,    0.50, 0.50, 50),
      _FloatingIcon(Icons.thermostat_rounded,           0.15, 0.65, 46),
      _FloatingIcon(Icons.water_drop_rounded,           0.78, 0.28, 48),
    ] : <_FloatingIcon>[];

    for (final item in [...icons, ...extraIcons]) {
      _drawIcon(canvas, size, item, color);
    }
  }

  void _drawIcon(Canvas canvas, Size size,
      _FloatingIcon item, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(item.icon.codePoint),
        style: TextStyle(
          fontSize: item.size,
          fontFamily: item.icon.fontFamily,
          package: item.icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(
      size.width  * item.dx - item.size / 2,
      size.height * item.dy - item.size / 2,
    ));
  }

  @override
  bool shouldRepaint(_MedicalPatternPainter old) => false;
}

class _FloatingIcon {
  final IconData icon;
  final double dx, dy, size;
  const _FloatingIcon(this.icon, this.dx, this.dy, this.size);
}
