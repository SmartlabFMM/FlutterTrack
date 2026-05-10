import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Vert d'eau doux (principal) ───────────────────────────────
  static const Color primary        = Color(0xFF5EC5B8); // teal pastel doux
  static const Color primaryLight   = Color(0xFF8DD9D1); // teal très clair
  static const Color primaryDark    = Color(0xFF3DADA0); // teal moyen
  static const Color primaryPale    = Color(0xFFF0FBFA); // teal quasi-blanc
  static const Color primarySurface = Color(0xFFDDF5F3); // teal pastel

  // ── Teal secondaire ───────────────────────────────────────────
  static const Color teal           = Color(0xFF5EC5B8);
  static const Color tealLight      = Color(0xFF8DD9D1);
  static const Color tealDark       = Color(0xFF3DADA0);
  static const Color tealPale       = Color(0xFFF0FBFA);

  // ── Fond & surfaces ───────────────────────────────────────────
  static const Color background     = Color(0xFFF2FAFA);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceAlt     = Color(0xFFF7FDFC);
  static const Color cardBorder     = Color(0xFFDDF0EE);

  // ── Dégradé fond global ───────────────────────────────────────
  static const Gradient appBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFDDF5F3), // vert d'eau doux (haut)
      Color(0xFFF7FDFC), // blanc nacré (bas)
    ],
  );

  // ── Texte ─────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFF2D4A48);
  static const Color textSecondary  = Color(0xFF5A7A78);
  static const Color textHint       = Color(0xFFAAC8C6);

  // ── Statuts sémantiques ───────────────────────────────────────
  static const Color success        = Color(0xFF5EC5B8);
  static const Color successLight   = Color(0xFFF0FBFA);
  static const Color warning        = Color(0xFFE8A838);
  static const Color warningLight   = Color(0xFFFFFAF0);
  static const Color danger         = Color(0xFFE05C5C);
  static const Color dangerLight    = Color(0xFFFFF0F0);
  static const Color info           = Color(0xFF5EC5B8);
  static const Color infoLight      = Color(0xFFF0FBFA);

  // ── Rôles utilisateurs ────────────────────────────────────────
  static const Color patientColor   = Color(0xFF5EC5B8);
  static const Color familyColor    = Color(0xFF3DADA0);
  static const Color doctorColor    = Color(0xFF2E9088);

  // ── Crise / urgence ───────────────────────────────────────────
  static const Color seizureRed     = Color(0xFFE05C5C);
  static const Color seizureRedDark = Color(0xFFC94040);
  static const Color sosButton      = Color(0xFFE05C5C);

  // ── Graphiques capteurs ───────────────────────────────────────
  static const Color accelColor     = Color(0xFF5EC5B8);
  static const Color heartColor     = Color(0xFFE05C5C);
  static const Color gsrColor       = Color(0xFF3DADA0);
  static const Color spo2Color      = Color(0xFF3B82F6);

  // ── Dégradés prédéfinis ───────────────────────────────────────
  static const Gradient heroGradientPatient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E9088), Color(0xFF3DADA0), Color(0xFF5EC5B8)],
  );

  static const Gradient heroGradientFamily = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3DADA0), Color(0xFF5EC5B8), Color(0xFF8DD9D1)],
  );

  static const Gradient heroGradientDoctor = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E9088), Color(0xFF3DADA0), Color(0xFF5EC5B8)],
  );

  static const Gradient loginHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E9088), Color(0xFF3DADA0), Color(0xFF5EC5B8)],
  );
}
