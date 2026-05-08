import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/alert_provider.dart';

class FamilyAlertsScreen extends ConsumerWidget {
  const FamilyAlertsScreen({super.key});

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    return 'Il y a ${diff.inDays}j';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertes reçues'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/family/dashboard'))),
      body: alerts.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => list.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.tealPale,
                      borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.notifications_off_rounded,
                      color: AppColors.teal, size: 32)),
                  const SizedBox(height: 12),
                  const Text('Aucune alerte pour le moment',
                    style: TextStyle(color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500)),
                ],
              ))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final a = list[i];
                final iconColor = a.isUrgent
                  ? AppColors.seizureRed : AppColors.warning;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: a.isUrgent
                      ? AppColors.dangerLight : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: a.isUrgent
                        ? AppColors.seizureRed.withValues(alpha: 0.4)
                        : AppColors.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: (a.isUrgent
                          ? AppColors.seizureRed : Colors.black)
                          .withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icône dans container coloré
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.warning_amber_rounded,
                          color: iconColor, size: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Text('Crise — ${a.patientName}',
                                  style: const TextStyle(fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary))),
                              if (a.isUrgent)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.seizureRed,
                                    borderRadius: BorderRadius.circular(20)),
                                  child: const Text('URGENT',
                                    style: TextStyle(fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white))),
                            ]),
                            const SizedBox(height: 4),
                            Row(children: [
                              Icon(Icons.access_time_rounded,
                                size: 12, color: AppColors.textHint),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('dd MMM à HH:mm', 'fr')
                                  .format(a.datetime),
                                style: const TextStyle(fontSize: 12,
                                  color: AppColors.textSecondary)),
                              const SizedBox(width: 8),
                              Text('·  ${_relativeTime(a.datetime)}',
                                style: TextStyle(fontSize: 12,
                                  color: iconColor,
                                  fontWeight: FontWeight.w600)),
                            ]),
                            if (a.mlScore != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Score de risque : ${(a.mlScore! * 100).toStringAsFixed(0)}%'
                                '${a.durationSeconds != null ? "  ·  ${a.durationSeconds}s" : ""}',
                                style: TextStyle(fontSize: 12,
                                  color: iconColor,
                                  fontWeight: FontWeight.w600)),
                            ],
                          ],
                        ),
                      ),
                    ]),
                );
              },
            ),
      ),
    );
  }
}
