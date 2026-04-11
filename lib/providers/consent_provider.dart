import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _key(String uid) => 'epitrack_consent_uid_$uid';

class ConsentNotifier extends AsyncNotifier<bool> {
  // uid courant — initialisé par checkForUser()
  String _uid = '';

  @override
  Future<bool> build() async => false; // par défaut non accepté

  /// À appeler juste après l'authentification pour charger le bon état.
  Future<bool> checkForUser(String uid) async {
    _uid  = uid;
    final prefs   = await SharedPreferences.getInstance();
    final accepted = prefs.getBool(_key(uid)) ?? false;
    state = AsyncData(accepted);
    return accepted;
  }

  Future<void> accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(_uid), true);
    state = const AsyncData(true);
  }

  Future<void> revoke() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(_uid));
    state = const AsyncData(false);
  }
}

final consentProvider =
    AsyncNotifierProvider<ConsentNotifier, bool>(ConsentNotifier.new);
