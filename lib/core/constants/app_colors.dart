import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Bleu doux (principal) ──────────────────────────────────
  static const Color primary        = Color(0xFF4A90D9); // bleu ciel doux
  static const Color primaryLight   = Color(0xFF74B0E8); // bleu clair
  static const Color primaryDark    = Color(0xFF2E78C7); // bleu moyen
  static const Color primaryPale    = Color(0xFFF0F7FF); // bleu très pâle
  static const Color primarySurface = Color(0xFFDEEDFB); // bleu pastel

  // ── Teal doux (succès / stable) ────────────────────────────
  static const Color teal           = Color(0xFF3AADA4); // teal doux
  static const Color tealLight      = Color(0xFF63C7BF); // teal clair
  static const Color tealDark       = Color(0xFF2A9A91); // teal moyen
  static const Color tealPale       = Color(0xFFF0FAFA); // teal très pâle

  // ── Fond & surfaces ─────────────────────────────────────────
  static const Color background     = Color(0xFFF5F8FF); // blanc bleuté très doux
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceAlt     = Color(0xFFF9FBFF); // blanc légèrement bleuté
  static const Color cardBorder     = Color(0xFFE8EEF6); // gris-bleu très léger

  // ── Texte ────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFF2D3748); // gris foncé doux
  static const Color textSecondary  = Color(0xFF5A6A7E); // gris-bleu moyen
  static const Color textHint       = Color(0xFFAAB8CC); // gris-bleu clair

  // ── Statuts sémantiques ──────────────────────────────────────
  static const Color success        = Color(0xFF3AADA4);
  static const Color successLight   = Color(0xFFF0FAFA);
  static const Color warning        = Color(0xFFE8A838); // ambre doux
  static const Color warningLight   = Color(0xFFFFFAF0); // ambre très pâle
  static const Color danger         = Color(0xFFE05C5C); // rouge doux
  static const Color dangerLight    = Color(0xFFFFF0F0); // rouge très pâle
  static const Color info           = Color(0xFF4A90D9);
  static const Color infoLight      = Color(0xFFF0F7FF);

  // ── Rôles utilisateurs ───────────────────────────────────────
  static const Color patientColor   = Color(0xFF4A90D9);
  static const Color familyColor    = Color(0xFF3AADA4);
  static const Color doctorColor    = Color(0xFF2E78C7);

  // ── Crise / urgence ──────────────────────────────────────────
  static const Color seizureRed     = Color(0xFFE05C5C); // rouge doux
  static const Color seizureRedDark = Color(0xFFC94040); // rouge moyen
  static const Color sosButton      = Color(0xFFE05C5C);

  // ── Graphiques capteurs ──────────────────────────────────────
  static const Color accelColor     = Color(0xFF4A90D9);
  static const Color heartColor     = Color(0xFFE05C5C);
  static const Color gsrColor       = Color(0xFF3AADA4);

  // ── Dégradés prédéfinis ──────────────────────────────────────
  static const Gradient heroGradientPatient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E78C7), Color(0xFF4A90D9), Color(0xFF74B0E8)],
  );

  static const Gradient heroGradientFamily = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A9A91), Color(0xFF3AADA4), Color(0xFF63C7BF)],
  );

  static const Gradient heroGradientDoctor = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E78C7), Color(0xFF4A90D9), Color(0xFF74B0E8)],
  );

  static const Gradient loginHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E78C7), Color(0xFF4A90D9), Color(0xFF74B0E8)],
  );
}
