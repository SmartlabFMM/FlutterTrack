import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';

class AdminAccountsScreen extends ConsumerStatefulWidget {
  const AdminAccountsScreen({super.key});
  @override
  ConsumerState<AdminAccountsScreen> createState() =>
      _AdminAccountsScreenState();
}

class _AdminAccountsScreenState
    extends ConsumerState<AdminAccountsScreen> {
  String _filter = 'tous';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(allUsersProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Gestion des comptes'),
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(children: [
              // Barre de recherche
              TextField(
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Rechercher un compte…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10)),
              ),
              const SizedBox(height: 10),
              // Filtre par rôle
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  for (final f in ['tous', 'patient', 'doctor', 'family', 'admin'])
                    _FilterChip(
                      label: _filterLabel(f),
                      selected: _filter == f,
                      onTap: () => setState(() => _filter = f)),
                ]),
              ),
            ]),
          ),
        ),
      ),
      body: users.when(
        data: (list) {
          final filtered = list.where((u) {
            final matchRole = _filter == 'tous' || u.role.name == _filter;
            final matchSearch = _search.isEmpty ||
              u.name.toLowerCase().contains(_search) ||
              u.email.toLowerCase().contains(_search);
            return matchRole && matchSearch;
          }).toList()
            ..sort((a, b) => a.name.compareTo(b.name));

          if (filtered.isEmpty) {
            return const Center(
              child: Text('Aucun compte trouvé',
                style: TextStyle(color: AppColors.textHint)));
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _AccountTile(
              user: filtered[i],
              onTap: () => context.push('/admin/user/${filtered[i].uid}'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/create'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Nouveau compte',
          style: TextStyle(color: Colors.white,
            fontWeight: FontWeight.w700)),
      ),
    );
  }

  String _filterLabel(String f) => switch (f) {
    'tous'    => 'Tous',
    'patient' => 'Patients',
    'doctor'  => 'Médecins',
    'family'  => 'Familles',
    'admin'   => 'Admins',
    _         => f,
  };
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool   selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label,
    required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.cardBorder)),
      child: Text(label,
        style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: selected ? Colors.white : AppColors.textSecondary)),
    ),
  );
}

class _AccountTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  const _AccountTile({required this.user, required this.onTap});

  Color _roleColor(UserRole r) => switch (r) {
    UserRole.patient => AppColors.primary,
    UserRole.doctor  => AppColors.tealDark,
    UserRole.family  => const Color(0xFF7C3AED),
    UserRole.admin   => const Color(0xFFD97706),
  };

  String _roleLabel(UserRole r) => switch (r) {
    UserRole.patient => 'Patient',
    UserRole.doctor  => 'Médecin',
    UserRole.family  => 'Famille',
    UserRole.admin   => 'Admin',
  };

  IconData _roleIcon(UserRole r) => switch (r) {
    UserRole.patient => Icons.person_rounded,
    UserRole.doctor  => Icons.medical_services_rounded,
    UserRole.family  => Icons.family_restroom_rounded,
    UserRole.admin   => Icons.admin_panel_settings_rounded,
  };

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: user.disabled
          ? AppColors.surfaceAlt
          : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: user.disabled
            ? AppColors.danger.withValues(alpha: 0.2)
            : AppColors.cardBorder)),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: _roleColor(user.role).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12)),
          child: Icon(_roleIcon(user.role),
            color: _roleColor(user.role), size: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(user.name,
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: user.disabled
                    ? AppColors.textHint
                    : AppColors.textPrimary)),
              if (user.disabled) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(6)),
                  child: const Text('désactivé',
                    style: TextStyle(fontSize: 9,
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700))),
              ],
            ]),
            Text(user.email,
              style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _roleColor(user.role).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20)),
          child: Text(_roleLabel(user.role),
            style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: _roleColor(user.role)))),
        const SizedBox(width: 6),
        const Icon(Icons.chevron_right_rounded,
          size: 18, color: AppColors.textHint),
      ]),
    ),
  );
}
