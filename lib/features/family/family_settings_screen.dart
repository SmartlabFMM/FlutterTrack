import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/epitrack_logo.dart';
import '../../models/reminder_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reminder_provider.dart';

class FamilySettingsScreen extends ConsumerWidget {
  const FamilySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [

            // ── Hero ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradientFamily,
                  borderRadius: BorderRadius.only(
                    bottomLeft:  Radius.circular(32),
                    bottomRight: Radius.circular(32)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25))),
                            child: Center(child: Text(
                              user.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800,
                                color: Colors.white)))),
                          const SizedBox(width: 12),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              const EpiTrackLogoSmall(size: 26),
                              const SizedBox(width: 6),
                              Text('EpiTrack',
                                style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.8))),
                            ]),
                            Text(user.name,
                              style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800,
                                color: Colors.white)),
                          ]),
                        ]),
                        const SizedBox(height: 8),
                        Text('Compte famille',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.65))),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Corps ──────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // Infos compte
                  _SettingsCard(children: [
                    _InfoRow(icon: Icons.person_rounded,
                      label: 'Nom', value: user.name),
                    const Divider(height: 1),
                    _InfoRow(icon: Icons.badge_rounded,
                      label: 'Rôle', value: 'Famille / Proche aidant'),
                  ]),
                  const SizedBox(height: 20),

                  // Rappels traitement
                  const Text('Rappels traitement',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  _FamilyRemindersCard(),
                  const SizedBox(height: 24),

                  // Déconnexion
                  OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context, ref),
                    icon: const Icon(Icons.logout_rounded,
                      color: AppColors.danger),
                    label: const Text('Se déconnecter',
                      style: TextStyle(color: AppColors.danger)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      side: const BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Déconnecter',
              style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
  }
}

// ── Rappels famille ───────────────────────────────────────────
class _FamilyRemindersCard extends ConsumerWidget {
  const _FamilyRemindersCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(reminderProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(children: [
        reminders.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2)),
          error: (_, __) => const SizedBox(),
          data: (list) => list.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  const Icon(Icons.alarm_off_rounded,
                    color: AppColors.textHint, size: 20),
                  const SizedBox(width: 10),
                  const Text('Aucun rappel configuré',
                    style: TextStyle(
                      color: AppColors.textHint, fontSize: 13)),
                ]))
            : Column(
                children: list.asMap().entries.map((e) {
                  final r    = e.value;
                  final last = e.key == list.length - 1;
                  return Column(children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: r.isActive
                            ? AppColors.primarySurface : AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.alarm_rounded,
                          size: 20,
                          color: r.isActive
                            ? AppColors.primary : AppColors.textHint)),
                      title: Text(r.label,
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: r.isActive
                            ? AppColors.textPrimary : AppColors.textHint)),
                      subtitle: Text(r.timeLabel,
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: r.isActive
                            ? AppColors.primary : AppColors.textHint)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Switch(
                          value: r.isActive,
                          onChanged: (_) =>
                            ref.read(reminderProvider.notifier).toggle(r.id)),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.danger, size: 20),
                          onPressed: () =>
                            ref.read(reminderProvider.notifier).remove(r.id)),
                      ]),
                    ),
                    if (!last) const Divider(height: 1, indent: 16),
                  ]);
                }).toList(),
              ),
        ),
        const Divider(height: 1),
        ListTile(
          onTap: () => _addReminder(context, ref),
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.add_alarm_rounded,
              color: AppColors.primary, size: 20)),
          title: const Text('Ajouter un rappel',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600, fontSize: 14)),
        ),
      ]),
    );
  }

  Future<void> _addReminder(BuildContext context, WidgetRef ref) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Choisir l\'heure du rappel',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
        child: child!),
    );
    if (time == null || !context.mounted) return;

    final ctrl    = TextEditingController(text: 'Médicament matin');
    final presets = ['Médicament matin', 'Médicament midi',
                     'Médicament soir',  'Médicament nuit'];
    final label   = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nom du rappel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(spacing: 8, runSpacing: 6,
              children: presets.map((p) => ActionChip(
                label: Text(p, style: const TextStyle(fontSize: 12)),
                onPressed: () { ctrl.text = p; },
              )).toList()),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Nom personnalisé',
                prefixIcon: Icon(Icons.edit_rounded))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              ctrl.text.trim().isEmpty ? 'Médicament' : ctrl.text.trim()),
            child: const Text('Confirmer')),
        ],
      ),
    );
    if (label == null) return;

    final id = '${time.hour}_${time.minute}_${DateTime.now().millisecondsSinceEpoch}';
    await ref.read(reminderProvider.notifier).add(
      ReminderModel(
        id: id, hour: time.hour, minute: time.minute, label: label));
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12, offset: const Offset(0, 3)),
      ],
    ),
    child: Column(children: children),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 12),
      Text(label,
        style: const TextStyle(
          fontSize: 13, color: AppColors.textSecondary,
          fontWeight: FontWeight.w500)),
      const Spacer(),
      Text(value,
        style: const TextStyle(
          fontSize: 13, color: AppColors.textPrimary,
          fontWeight: FontWeight.w600)),
    ]),
  );
}
