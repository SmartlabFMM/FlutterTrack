import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/user_model.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth  = ref.watch(authProvider);
    final stats = ref.watch(adminStatsProvider);
    final users = ref.watch(allUsersProvider);
    final firstName = auth.user?.name.split(' ').first ?? 'Admin';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            // ── Hero ─────────────────────────────────────────────
            SliverToBoxAdapter(child: _AdminHero(firstName: firstName)),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── Stats ──────────────────────────────────────
                  const SizedBox(height: 20),
                  const _SectionLabel('Statistiques globales'),
                  const SizedBox(height: 10),
                  stats.when(
                    data: (s) => GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.6,
                      children: [
                        _StatCard(label: 'Patients', value: '${s['patients']}',
                          icon: Icons.person_rounded,
                          color: AppColors.primary),
                        _StatCard(label: 'Médecins', value: '${s['doctors']}',
                          icon: Icons.medical_services_rounded,
                          color: AppColors.tealDark),
                        _StatCard(label: 'Familles', value: '${s['families']}',
                          icon: Icons.family_restroom_rounded,
                          color: const Color(0xFF7C3AED)),
                        _StatCard(label: 'Crises totales', value: '${s['seizures']}',
                          icon: Icons.bolt_rounded,
                          color: AppColors.seizureRed),
                      ],
                    ),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator())),
                    error: (_, __) => const SizedBox(),
                  ),

                  // ── Patients récents ────────────────────────────
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionLabel('Comptes récents'),
                      TextButton(
                        onPressed: () => context.go('/admin/accounts'),
                        child: const Text('Voir tout',
                          style: TextStyle(
                            fontSize: 12, color: AppColors.primary,
                            fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  users.when(
                    data: (list) {
                      final recent = list
                        ..sort((a, b) => a.name.compareTo(b.name));
                      return Column(
                        children: recent.take(5).map((u) =>
                          _UserListTile(user: u,
                            onTap: () => context.push(
                              '/admin/user/${u.uid}'))).toList(),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox(),
                  ),
                ]),
              ),
            ),
          ],
        ),

        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/admin/create'),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.person_add_rounded, color: Colors.white),
          label: const Text('Nouveau compte',
            style: TextStyle(color: Colors.white,
              fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

// ─── Hero ─────────────────────────────────────────────────────
class _AdminHero extends StatelessWidget {
  final String firstName;
  const _AdminHero({required this.firstName});

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)]),
      borderRadius: BorderRadius.only(
        bottomLeft:  Radius.circular(32),
        bottomRight: Radius.circular(32)),
    ),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25))),
            child: const Icon(Icons.admin_panel_settings_rounded,
              color: Colors.white, size: 26)),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Bonjour, $firstName',
              style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: Colors.white)),
            Text('Espace administrateur',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.72))),
          ]),
        ]),
      ),
    ),
  );
}

// ─── Stat Card ───────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String  label, value;
  final IconData icon;
  final Color   color;
  const _StatCard({required this.label, required this.value,
    required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10, offset: const Offset(0, 3)),
      ],
    ),
    child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 20)),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(
          fontSize: 11, color: AppColors.textSecondary)),
      ]),
    ]),
  );
}

// ─── User tile ───────────────────────────────────────────────
class _UserListTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  const _UserListTile({required this.user, required this.onTap});

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

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder)),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: _roleColor(user.role).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12)),
          child: Center(
            child: Text(
              user.name.isNotEmpty
                ? user.name.substring(0, 1).toUpperCase()
                : '?',
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800,
                color: _roleColor(user.role))))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.name,
              style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
            Text(user.email,
              style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ),
        Row(children: [
          if (user.disabled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(20)),
              child: const Text('Désactivé',
                style: TextStyle(fontSize: 10,
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600))),
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
      ]),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w700,
      color: AppColors.textSecondary, letterSpacing: 0.3));
}
