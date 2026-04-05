import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../services/notification_service.dart';

class EmergencyContactsScreen extends ConsumerWidget {
  const EmergencyContactsScreen({super.key});

  static const _contacts = [
    {'name': 'Maman', 'phone': '+216 XX XXX XXX',
     'role': 'Famille', 'autoSms': true, 'autoCall': false},
    {'name': 'Dr. Kamel Trabelsi', 'phone': '+216 XX XXX XXX',
     'role': 'Médecin', 'autoSms': true, 'autoCall': false},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contacts d\'urgence')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddContact(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ajouter',
          style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 3)),
              ],
            ),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded,
                color: AppColors.primary, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ces contacts seront notifiés automatiquement par SMS lors de chaque crise détectée.',
                  style: TextStyle(fontSize: 12,
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w500))),
            ]),
          ),

          // Liste
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _contacts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _ContactCard(
                contact: _contacts[i],
                onCall: () => NotificationService.callEmergencyContact(
                  _contacts[i]['phone'] as String),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddContact(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _AddContactSheet(),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final Map contact;
  final VoidCallback onCall;
  const _ContactCard({required this.contact, required this.onCall});

  @override
  Widget build(BuildContext context) {
    final isDoctor = contact['role'] == 'Médecin';
    final color    = isDoctor ? AppColors.primaryDark : AppColors.teal;
    final bgColor  = isDoctor
      ? AppColors.primarySurface : AppColors.tealPale.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: [
        Row(children: [
          // Avatar plus grand avec dégradé
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.65)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3)),
              ],
            ),
            child: Center(child: Text(
              (contact['name'] as String).substring(0, 1),
              style: const TextStyle(fontSize: 22,
                fontWeight: FontWeight.w800, color: Colors.white)))),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(contact['name'] as String,
                style: const TextStyle(fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(contact['phone'] as String,
                style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
            ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20)),
            child: Text(contact['role'] as String,
              style: TextStyle(fontSize: 11,
                color: color, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 14),
        Divider(height: 1, thickness: 0.6,
          color: color.withValues(alpha: 0.2)),
        const SizedBox(height: 12),
        Row(children: [
          // Bouton Appeler avec icône
          Expanded(
            child: _CallButton(onCall: onCall),
          ),
          const SizedBox(width: 8),
          // SMS automatique toggle
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: contact['autoSms'] == true
                  ? AppColors.tealPale : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.sms_rounded, size: 16,
                  color: contact['autoSms'] == true
                    ? AppColors.teal : AppColors.textHint),
                const SizedBox(width: 6),
                Text('SMS auto',
                  style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: contact['autoSms'] == true
                      ? AppColors.tealDark : AppColors.textHint)),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }
}

// Bouton Appeler avec légère animation de couleur
class _CallButton extends StatefulWidget {
  final VoidCallback onCall;
  const _CallButton({required this.onCall});
  @override
  State<_CallButton> createState() => _CallButtonState();
}

class _CallButtonState extends State<_CallButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _pressed = true),
    onTapUp: (_) {
      setState(() => _pressed = false);
      widget.onCall();
    },
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: _pressed
          ? AppColors.primary.withValues(alpha: 0.15)
          : AppColors.primaryPale,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _pressed ? AppColors.primary : AppColors.primary.withValues(alpha: 0.4))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.call_rounded, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        const Text('Appeler',
          style: TextStyle(fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primary)),
      ]),
    ),
  );
}

class _AddContactSheet extends StatelessWidget {
  const _AddContactSheet();
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: 20, right: 20, top: 24,
      bottom: MediaQuery.of(context).viewInsets.bottom + 24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 40, height: 4,
        decoration: BoxDecoration(
          color: AppColors.cardBorder,
          borderRadius: BorderRadius.circular(2))),
      const SizedBox(height: 16),
      const Text('Nouveau contact',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      const SizedBox(height: 20),
      const TextField(decoration: InputDecoration(
        labelText: 'Nom complet',
        prefixIcon: Icon(Icons.person_outline))),
      const SizedBox(height: 12),
      const TextField(
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          labelText: 'Numéro de téléphone',
          prefixIcon: Icon(Icons.phone_outlined))),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48)),
        child: const Text('Enregistrer le contact')),
    ]),
  );
}
