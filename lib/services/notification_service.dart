import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_colors.dart';
import '../main.dart';

/// Service de notifications — Firebase Push désactivé pour le prototype.
/// Pour activer Firebase : décommenter les imports firebase_messaging
/// et appeler NotificationService.initFirebase() dans main().
class NotificationService {
  // ── Notification locale (crise détectée par le BLE) ─────
  static Future<void> showSeizureAlert({
    required String patientName,
    String? body,
  }) async {
    await localNotifications.show(
      DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
      '⚠️ Crise détectée — $patientName',
      body ?? 'Alerte envoyée aux contacts d\'urgence',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'seizure_channel', 'Alertes crises',
          importance: Importance.max,
          priority: Priority.max,
          color: AppColors.seizureRed,
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true, presentBadge: true, presentSound: true),
      ),
    );
  }

  // ── Notification locale générale ────────────────────────
  static Future<void> showInfo({
    required String title,
    required String body,
  }) async {
    await localNotifications.show(
      DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
      title, body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'general_channel', 'Général',
          importance: Importance.high,
          priority: Priority.high,
          color: AppColors.primary,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true, presentBadge: true, presentSound: true),
      ),
    );
  }

  // ── SMS famille ─────────────────────────────────────────
  static Future<void> sendSmsFamilyAlert({
    required String phone,
    required String patientName,
    required String datetime,
  }) async {
    final msg = Uri.encodeComponent(
      '⚠️ EpiTrack — Crise détectée pour $patientName le $datetime. '
      'Veuillez vérifier son état immédiatement.');
    final uri = Uri.parse('sms:$phone?body=$msg');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // ── Appel d'urgence ─────────────────────────────────────
  static Future<void> callEmergencyContact(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}
