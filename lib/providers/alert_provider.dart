import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alert_model.dart';
import 'auth_provider.dart';

final alertListProvider = FutureProvider<List<AlertModel>>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];
  final odoo = ref.read(odooServiceProvider);
  return odoo.fetchAlerts(userId: user.uid, role: user.role);
});

final unreadAlertCountProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(alertListProvider).whenData(
    (alerts) => alerts.where((a) => a.status == AlertStatus.unread).length,
  );
});