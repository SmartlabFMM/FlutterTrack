import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ble_provider.dart';
import '../../providers/consent_provider.dart';
import '../../models/reminder_model.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/settings_provider.dart';

class PatientSettingsScreen extends ConsumerWidget {
  const PatientSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user     = ref.watch(authProvider).user!;
    final ble      = ref.watch(bleProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Profil ──────────────────────────────────────
          _SectionHeader(label: 'Mon profil'),
          _ProfileCard(name: user.name, email: user.email),
          const SizedBox(height: 20),

          // ── Bracelet ────────────────────────────────────
          _SectionHeader(label: 'Bracelet EpiTrack'),
          _BraceletCard(ble: ble, ref: ref),
          const SizedBox(height: 20),

          // ── Contacts urgence ─────────────────────────────
          _SectionHeader(label: 'Contacts d\'urgence'),
          _ContactTile(name: 'Maman',             phone: '+216 XX XXX XXX', role: 'Famille'),
          _ContactTile(name: 'Dr. Kamel Trabelsi', phone: '+216 XX XXX XXX', role: 'Médecin'),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryPale,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary, width: 0.8)),
              child: const Icon(Icons.add, color: AppColors.primary, size: 20)),
            title: const Text('Ajouter un contact',
              style: TextStyle(color: AppColors.primary,
                fontWeight: FontWeight.w600)),
            onTap: () {},
          ),
          const SizedBox(height: 20),

          // ── Notifications ────────────────────────────────
          _SectionHeader(label: 'Notifications'),
          _NotificationsCard(
            settings: settings,
            onVibration: (v) =>
              ref.read(settingsProvider.notifier).setVibration(v),
            onSound: (v) =>
              ref.read(settingsProvider.notifier).setSound(v),
            onAutoSms: (v) =>
              ref.read(settingsProvider.notifier).setAutoSms(v),
          ),
          const SizedBox(height: 20),

          // ── Rappels traitement ───────────────────────────
          _SectionHeader(label: 'Rappels traitement'),
          const _RemindersCard(),
          const SizedBox(height: 28),

          // ── Consentement & confidentialité ───────────────
          OutlinedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Retirer le consentement'),
                  content: const Text(
                    'Si vous retirez votre consentement, vous serez '
                    'redirigé vers l\'écran de consentement et ne pourrez '
                    'plus utiliser l\'application sans l\'accepter à nouveau.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Retirer',
                        style: TextStyle(color: AppColors.danger))),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(consentProvider.notifier).revoke();
                if (context.mounted) context.go('/patient/consent');
              }
            },
            icon: const Icon(Icons.privacy_tip_rounded,
              color: AppColors.primary),
            label: const Text('Confidentialité & consentement',
              style: TextStyle(color: AppColors.primary)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),

          // ── Déconnexion ──────────────────────────────────
          OutlinedButton.icon(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon:  const Icon(Icons.logout_rounded, color: AppColors.danger),
            label: const Text(AppStrings.logout,
              style: TextStyle(color: AppColors.danger)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              side: const BorderSide(color: AppColors.danger),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text('EpiTrack v1.0.0 — Prototype',
              style: TextStyle(fontSize: 12, color: AppColors.textHint))),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(label, style: const TextStyle(fontSize: 13,
      fontWeight: FontWeight.w700, color: AppColors.textSecondary,
      letterSpacing: 0.5)),
  );
}

class _ProfileCard extends StatelessWidget {
  final String name, email;
  const _ProfileCard({required this.name, required this.email});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primarySurface, AppColors.surface]),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.10),
          blurRadius: 16,
          offset: const Offset(0, 5)),
      ],
    ),
    child: Row(children: [
      // Avatar avec dégradé couleur
      Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.30),
              blurRadius: 10,
              offset: const Offset(0, 4)),
          ],
        ),
        child: Center(child: Text(
          name.substring(0, 1).toUpperCase(),
          style: const TextStyle(fontSize: 24,
            fontWeight: FontWeight.w800, color: Colors.white)))),
      const SizedBox(width: 16),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontSize: 16,
            fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(email, style: const TextStyle(
            fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20)),
            child: const Text('Patient',
              style: TextStyle(fontSize: 11,
                color: AppColors.primary, fontWeight: FontWeight.w700))),
        ])),
    ]),
  );
}

class _NotificationsCard extends StatelessWidget {
  final dynamic settings;
  final ValueChanged<bool> onVibration;
  final ValueChanged<bool> onSound;
  final ValueChanged<bool> onAutoSms;

  const _NotificationsCard({
    required this.settings,
    required this.onVibration,
    required this.onSound,
    required this.onAutoSms,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4)),
      ],
    ),
    child: Column(children: [
      _SwitchRow(
        icon: Icons.vibration_rounded,
        iconColor: AppColors.primary,
        label: 'Vibration lors d\'une crise',
        value: settings.vibrationEnabled,
        onChanged: onVibration,
        isFirst: true,
        isLast: false,
      ),
      Divider(height: 1, thickness: 0.6,
        color: AppColors.cardBorder,
        indent: 60, endIndent: 16),
      _SwitchRow(
        icon: Icons.volume_up_rounded,
        iconColor: AppColors.teal,
        label: 'Son d\'alerte',
        value: settings.soundEnabled,
        onChanged: onSound,
        isFirst: false,
        isLast: false,
      ),
      Divider(height: 1, thickness: 0.6,
        color: AppColors.cardBorder,
        indent: 60, endIndent: 16),
      _SwitchRow(
        icon: Icons.sms_outlined,
        iconColor: AppColors.primaryDark,
        label: 'SMS automatique famille',
        value: settings.autoSmsEnabled,
        onChanged: onAutoSms,
        isFirst: false,
        isLast: true,
      ),
    ]),
  );
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isFirst, isLast;

  const _SwitchRow({
    required this.icon, required this.iconColor,
    required this.label, required this.value,
    required this.onChanged, required this.isFirst, required this.isLast,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(16, isFirst ? 4 : 0, 16, isLast ? 4 : 0),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, color: iconColor, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Text(label,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary,
          fontWeight: FontWeight.w500))),
      Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    ]),
  );
}

class _BraceletCard extends StatelessWidget {
  final BleState  ble;
  final WidgetRef ref;
  const _BraceletCard({required this.ble, required this.ref});
  @override
  Widget build(BuildContext context) {
    final connected = ble.status == BleStatus.connected;
    final color = connected ? AppColors.teal : AppColors.textHint;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.watch_rounded, color: color, size: 22)),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ESP32 — EpiTrack',
            style: TextStyle(fontSize: 14,
              fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text(connected
            ? 'Connecté · Batterie ${ble.batteryLevel}%'
            : 'Déconnecté',
            style: TextStyle(fontSize: 12,
              color: connected ? AppColors.teal : AppColors.textSecondary)),
        ]),
        const Spacer(),
        if (!connected)
          TextButton(
            onPressed: () => ref.read(bleProvider.notifier).connect(),
            child: const Text('Connecter')),
      ]),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final String name, phone, role;
  const _ContactTile({required this.name,
    required this.phone, required this.role});
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    leading: CircleAvatar(
      backgroundColor: AppColors.tealPale,
      child: Text(name.substring(0, 1),
        style: const TextStyle(
          color: AppColors.tealDark, fontWeight: FontWeight.w700))),
    title: Text(name),
    subtitle: Text(phone),
    trailing: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryPale,
        borderRadius: BorderRadius.circular(20)),
      child: Text(role, style: const TextStyle(
        fontSize: 11, color: AppColors.primary,
        fontWeight: FontWeight.w600))),
  );
}

// ── Rappels traitement ────────────────────────────────────────
class _RemindersCard extends ConsumerWidget {
  const _RemindersCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(reminderProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
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
                    Icon(Icons.alarm_off_rounded,
                      color: AppColors.textHint, size: 20),
                    const SizedBox(width: 10),
                    const Text('Aucun rappel configuré',
                      style: TextStyle(
                        color: AppColors.textHint, fontSize: 13)),
                  ]))
              : Column(
                  children: list.asMap().entries.map((e) {
                    final r   = e.value;
                    final last = e.key == list.length - 1;
                    return Column(children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: r.isActive
                              ? AppColors.primarySurface
                              : AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.alarm_rounded,
                            size: 20,
                            color: r.isActive
                              ? AppColors.primary : AppColors.textHint)),
                        title: Text(r.label,
                          style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: r.isActive
                              ? AppColors.textPrimary
                              : AppColors.textHint)),
                        subtitle: Text(r.timeLabel,
                          style: TextStyle(
                            fontSize: 13,
                            color: r.isActive
                              ? AppColors.primary : AppColors.textHint,
                            fontWeight: FontWeight.w600)),
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
          // Bouton ajouter
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
        ],
      ),
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

    final label = await _pickLabel(context);
    if (label == null) return;

    final id = '${time.hour}_${time.minute}_${DateTime.now().millisecondsSinceEpoch}';
    await ref.read(reminderProvider.notifier).add(
      ReminderModel(
        id: id, hour: time.hour, minute: time.minute, label: label));
  }

  Future<String?> _pickLabel(BuildContext context) {
    final ctrl = TextEditingController(text: 'Médicament matin');
    final presets = ['Médicament matin', 'Médicament midi',
                     'Médicament soir',  'Médicament nuit'];
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nom du rappel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8, runSpacing: 6,
              children: presets.map((p) => ActionChip(
                label: Text(p, style: const TextStyle(fontSize: 12)),
                onPressed: () { ctrl.text = p; },
              )).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Nom personnalisé',
                prefixIcon: Icon(Icons.edit_rounded)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
          TextButton(
            onPressed: () =>
              Navigator.pop(context, ctrl.text.trim().isEmpty
                ? 'Médicament' : ctrl.text.trim()),
            child: const Text('Confirmer')),
        ],
      ),
    );
  }
}
