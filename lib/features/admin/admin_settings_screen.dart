import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/epitrack_logo.dart';
import '../../providers/auth_provider.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [

            // ── Hero ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1E3A8A),
                      Color(0xFF2563EB),
                      Color(0xFF3B82F6),
                    ],
                  ),
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
                              user.name.isNotEmpty
                                ? user.name.substring(0, 1).toUpperCase()
                                : 'A',
                              style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800,
                                color: Colors.white)))),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                            ],
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Text('Compte administrateur',
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
                    _InfoRow(
                      icon: Icons.person_rounded,
                      label: 'Nom',
                      value: user.name),
                    const Divider(height: 1, color: AppColors.cardBorder),
                    _InfoRow(
                      icon: Icons.email_rounded,
                      label: 'Email',
                      value: user.email),
                    const Divider(height: 1, color: AppColors.cardBorder),
                    _InfoRow(
                      icon: Icons.admin_panel_settings_rounded,
                      label: 'Rôle',
                      value: 'Administrateur'),
                  ]),
                  const SizedBox(height: 32),

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
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await ref.read(authProvider.notifier).logout();
            },
            child: const Text('Déconnecter',
              style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
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
  final String   label, value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

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
      Flexible(child: Text(value,
        textAlign: TextAlign.end,
        style: const TextStyle(
          fontSize: 13, color: AppColors.textPrimary,
          fontWeight: FontWeight.w600))),
    ]),
  );
}
