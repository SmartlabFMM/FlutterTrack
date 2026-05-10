import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TfliteUpdateService {
  static const _storagePath  = 'models/prevention_model.tflite';
  static const _localFile    = 'prevention_model.tflite';
  static const _prefKey      = 'tflite_last_update';

  /// Appelé au démarrage (fire-and-forget). Ne bloque pas le lancement.
  static Future<void> checkAndUpdate() async {
    try {
      final ref = FirebaseStorage.instance.ref(_storagePath);

      // ── 1. Métadonnées distantes ─────────────────────────────
      final meta          = await ref.getMetadata();
      final remoteUpdated = meta.updated;
      if (remoteUpdated == null) return;

      // ── 2. Comparaison avec la version locale ────────────────
      final prefs         = await SharedPreferences.getInstance();
      final lastUpdateRaw = prefs.getString(_prefKey);
      if (lastUpdateRaw != null) {
        final lastUpdate = DateTime.parse(lastUpdateRaw);
        if (!remoteUpdated.isAfter(lastUpdate)) return;
      }

      // ── 3. Téléchargement et sauvegarde locale ───────────────
      final dir   = await getApplicationDocumentsDirectory();
      final local = File('${dir.path}/$_localFile');
      await ref.writeToFile(local);

      // ── 4. Mise à jour de la date locale ─────────────────────
      await prefs.setString(_prefKey, remoteUpdated.toIso8601String());
    } catch (_) {
      // Échec silencieux — l'app continue avec le modèle existant.
    }
  }

  /// Retourne le chemin local du modèle, ou null s'il n'existe pas encore.
  static Future<String?> localModelPath() async {
    final dir   = await getApplicationDocumentsDirectory();
    final local = File('${dir.path}/$_localFile');
    return local.existsSync() ? local.path : null;
  }
}
