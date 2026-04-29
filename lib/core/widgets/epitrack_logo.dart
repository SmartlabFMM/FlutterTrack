import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Logo EpiTrack — shield hexagonal + onde EEG (statique)
class EpiTrackLogo extends StatelessWidget {
  final double size;
  const EpiTrackLogo({super.key, this.size = 72, bool animate = false});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(
      painter: _LogoPainter(pulse: 1.0, glowAlpha: 0.6),
    ),
  );
}

class _LogoPainter extends CustomPainter {
  final double pulse;
  final double glowAlpha;
  const _LogoPainter({required this.pulse, required this.glowAlpha});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;

    // ── 1. Halo externe animé ─────────────────────────────
    final haloPaint = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: glowAlpha * 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(Offset(cx, cy), r * pulse, haloPaint);

    // ── 2. Fond shield (hexagone arrondi) ──────────────────
    final shieldPath = _buildShield(cx, cy, r * 0.88);

    // Gradient fond
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF3DADA0),
          Color(0xFF5EC5B8),
          Color(0xFF8DD9D1),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(cx, cy), radius: r));
    canvas.drawPath(shieldPath, bgPaint);

    // Bordure shield
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.025;
    canvas.drawPath(shieldPath, borderPaint);

    // ── 3. Reflet glossy en haut ───────────────────────────
    final glossPath = Path()
      ..moveTo(cx - r * 0.55, cy - r * 0.55)
      ..quadraticBezierTo(cx, cy - r * 0.82, cx + r * 0.55, cy - r * 0.55)
      ..quadraticBezierTo(cx, cy - r * 0.12, cx - r * 0.55, cy - r * 0.55)
      ..close();
    final glossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.save();
    canvas.clipPath(shieldPath);
    canvas.drawPath(glossPath, glossPaint);
    canvas.restore();

    // ── 4. Onde EEG avec pic épileptique ───────────────────
    canvas.save();
    canvas.clipPath(shieldPath);
    _drawEegWave(canvas, size, cx, cy);
    canvas.restore();

    // ── 5. Points lumineux (nœuds) ────────────────────────
    _drawNodes(canvas, size, cx, cy);
  }

  // ── Path du shield (hexagone arrondi type médical) ────────
  Path _buildShield(double cx, double cy, double r) {
    final path = Path();
    const sides = 6;
    const startAngle = -math.pi / 2; // pointe vers le haut
    final pts = List.generate(sides, (i) {
      final a = startAngle + i * 2 * math.pi / sides;
      return Offset(cx + r * math.cos(a), cy + r * math.sin(a));
    });
    // Tracer avec coins arrondis
    const cornerR = 0.18;
    for (int i = 0; i < sides; i++) {
      final p0 = pts[(i - 1 + sides) % sides];
      final p1 = pts[i];
      final p2 = pts[(i + 1) % sides];
      final d01 = (p1 - p0).distance;
      final d12 = (p2 - p1).distance;
      final t = cornerR;
      final a = p0 + (p1 - p0) * (1 - t * r / d01);
      final b = p1 + (p2 - p1) * (t * r / d12);
      if (i == 0) {
        path.moveTo(a.dx, a.dy);
      } else {
        path.lineTo(a.dx, a.dy);
      }
      path.quadraticBezierTo(p1.dx, p1.dy, b.dx, b.dy);
    }
    path.close();
    return path;
  }

  // ── Onde EEG ──────────────────────────────────────────────
  void _drawEegWave(Canvas canvas, Size size, double cx, double cy) {
    final w = size.width;
    final h = size.height;
    final midY = cy + h * 0.05; // légèrement sous le centre

    // Points de l'onde EEG caractéristique (spike épileptique)
    // x en fraction de width, y en fraction de height depuis midY
    final pts = [
      Offset(w * 0.08,  midY),
      Offset(w * 0.22,  midY),
      Offset(w * 0.30,  midY + h * 0.04),
      Offset(w * 0.36,  midY - h * 0.04),
      Offset(w * 0.40,  midY - h * 0.22), // montée du pic
      Offset(w * 0.44,  midY + h * 0.28), // descente violente
      Offset(w * 0.49,  midY - h * 0.10), // rebond
      Offset(w * 0.54,  midY + h * 0.06),
      Offset(w * 0.60,  midY),
      Offset(w * 0.75,  midY),
      Offset(w * 0.92,  midY),
    ];

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final prev = pts[i - 1];
      final curr = pts[i];
      // Courbe de Bézier lissée sauf autour du spike (i==4,5,6)
      if (i >= 4 && i <= 6) {
        path.lineTo(curr.dx, curr.dy); // lignes droites pour le spike
      } else {
        final cpX = (prev.dx + curr.dx) / 2;
        path.quadraticBezierTo(cpX, prev.dy, curr.dx, curr.dy);
      }
    }

    // Ombre de l'onde
    final shadowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.045
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, shadowPaint);

    // Gradient de l'onde
    final wavePaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF93C5FD), // blue-300
          Color(0xFFFFFFFF), // blanc au pic
          Color(0xFF67E8F9), // cyan-300
        ],
        stops: [0.0, 0.44, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.038
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, wavePaint);

    // Point chaud au pic (étoile lumineuse)
    final peakX = w * 0.40;
    final peakY = midY - h * 0.22;
    final peakGlow = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(peakX, peakY), size.width * 0.045, peakGlow);
    canvas.drawCircle(
      Offset(peakX, peakY),
      size.width * 0.025,
      Paint()..color = Colors.white);
  }

  // ── Petits nœuds décoratifs ───────────────────────────────
  void _drawNodes(Canvas canvas, Size size, double cx, double cy) {
    final positions = [
      Offset(size.width * 0.22, cy + size.height * 0.05),
      Offset(size.width * 0.60, cy + size.height * 0.05),
    ];
    for (final pos in positions) {
      canvas.drawCircle(
        pos,
        size.width * 0.028,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
      canvas.drawCircle(
        pos,
        size.width * 0.016,
        Paint()..color = Colors.white.withValues(alpha: 0.8));
    }
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
    old.pulse != pulse || old.glowAlpha != glowAlpha;
}

/// Version petite pour AppBar (sans animation)
class EpiTrackLogoSmall extends StatelessWidget {
  final double size;
  const EpiTrackLogoSmall({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) => EpiTrackLogo(
    size: size,
    animate: false,
  );
}
