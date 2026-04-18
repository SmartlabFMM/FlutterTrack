import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True = onboarding déjà vu, False = à afficher.
/// Initialisé depuis main() via overrideWith.
final onboardingDoneProvider = Provider<bool>((ref) => false);
