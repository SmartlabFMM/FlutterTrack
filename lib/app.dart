import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/role_router.dart';
import 'features/patient/consent_screen.dart';
import 'features/patient/dashboard_screen.dart';
import 'features/patient/live_signals_screens.dart';
import 'features/patient/history_screen.dart';
import 'features/patient/settings_screen.dart';
import 'features/patient/habits_screen.dart';
import 'features/family/family_dashboard_screen.dart';
import 'features/family/family_alerts_screen.dart';
import 'features/family/family_signals_screen.dart';
import 'features/family/emergency_contacts_screen.dart';
import 'features/family/family_settings_screen.dart';
import 'features/family/family_habits_screen.dart';
import 'features/doctor/patients_list_screen.dart';
import 'features/doctor/patient_detail_screen.dart';
import 'features/doctor/vitals_screen.dart';
import 'features/doctor/doctor_alerts_screen.dart';
import 'features/doctor/report_screen.dart';
import 'features/doctor/doctor_settings_screen.dart';
import 'features/doctor/doctor_location_screen.dart';
import 'features/admin/admin_dashboard_screen.dart';
import 'features/admin/admin_accounts_screen.dart';
import 'features/admin/admin_create_account_screen.dart';
import 'features/admin/admin_user_detail_screen.dart';
import 'core/widgets/reminder_overlay.dart';
import 'core/widgets/medical_background.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/family/family_location_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/vitals_sync_provider.dart';

// ── Router notifier ──────────────────────────────────────────
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    // Rebuild router redirect whenever auth state changes
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final loc = state.matchedLocation;

    // ── Onboarding — laisser passer sans vérification auth ──────
    if (loc == '/onboarding') return null;

    // ── Auth ──────────────────────────────────────────────────
    final auth       = _ref.read(authProvider);
    final isLoading  = auth.status == AuthStatus.initial ||
                       auth.status == AuthStatus.loading;
    final isLoggedIn = auth.status == AuthStatus.authenticated;
    final isLogin    = loc == '/login';

    if (isLoading) return null;
    if (!isLoggedIn && !isLogin) return '/login';
    if (isLoggedIn && isLogin) {
      return RoleRouter.redirectForRole(auth.user!.role);
    }
    return null;
  }
}

// ── Router provider (created once, never recreated) ───────────
final _routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),

      // ── Patient ─────────────────────────────────────
      ShellRoute(
        builder: (_, __, child) => _PatientShell(child: child),
        routes: [
          GoRoute(path: '/patient/dashboard',
            builder: (_, __) => const PatientDashboardScreen()),
          GoRoute(path: '/patient/signals',
            builder: (_, __) => const LiveSignalsScreen()),
          GoRoute(path: '/patient/history',
            builder: (_, __) => const HistoryScreen()),
          GoRoute(path: '/patient/settings',
            builder: (_, __) => const PatientSettingsScreen()),
        ],
      ),

      // ── Routes famille hors shell ────────────────────────
      GoRoute(path: '/family/habits',
        builder: (_, __) => const FamilyHabitsScreen()),
      GoRoute(path: '/family/signals',
        builder: (_, __) => const FamilySignalsScreen()),
      GoRoute(
        path: '/family/location/:patientId',
        builder: (_, state) => FamilyLocationScreen(
          patientId: state.pathParameters['patientId']!)),

      // ── Routes patient hors shell (pas de bottom nav) ────
      GoRoute(path: '/patient/consent',
        builder: (_, __) => const ConsentScreen()),
      GoRoute(path: '/patient/habits',
        builder: (_, __) => const HabitsScreen()),

      // ── Famille ─────────────────────────────────────
      ShellRoute(
        builder: (_, __, child) => _FamilyShell(child: child),
        routes: [
          GoRoute(path: '/family/dashboard',
            builder: (_, __) => const FamilyDashboardScreen()),
          GoRoute(path: '/family/alerts',
            builder: (_, __) => const FamilyAlertsScreen()),
          GoRoute(path: '/family/contacts',
            builder: (_, __) => const EmergencyContactsScreen()),
          GoRoute(path: '/family/settings',
            builder: (_, __) => const FamilySettingsScreen()),
        ],
      ),

      // ── Médecin ─────────────────────────────────────
      ShellRoute(
        builder: (_, __, child) => _DoctorShell(child: child),
        routes: [
          GoRoute(path: '/doctor/patients',
            builder: (_, __) => const PatientsListScreen()),
          GoRoute(path: '/doctor/alerts',
            builder: (_, __) => const DoctorAlertsScreen()),
          GoRoute(path: '/doctor/settings',
            builder: (_, __) => const DoctorSettingsScreen()),
        ],
      ),

      // ── Routes médecin hors shell (pas de bottom nav) ──
      GoRoute(path: '/doctor/patient/:id',
        builder: (_, state) => PatientDetailScreen(
          patientId: state.pathParameters['id']!)),
      GoRoute(path: '/doctor/vitals/:id',
        builder: (_, state) => VitalsScreen(
          patientId: state.pathParameters['id']!)),
      GoRoute(path: '/doctor/report/:id',
        builder: (_, state) => ReportScreen(
          patientId: state.pathParameters['id']!)),
      GoRoute(path: '/doctor/location/:id',
        builder: (_, state) => DoctorLocationScreen(
          patientId: state.pathParameters['id']!)),

      // ── Admin ────────────────────────────────────────
      ShellRoute(
        builder: (_, __, child) => _AdminShell(child: child),
        routes: [
          GoRoute(path: '/admin/dashboard',
            builder: (_, __) => const AdminDashboardScreen()),
          GoRoute(path: '/admin/accounts',
            builder: (_, __) => const AdminAccountsScreen()),
        ],
      ),
      // ── Routes admin hors shell ──────────────────────
      GoRoute(path: '/admin/create',
        builder: (_, __) => const AdminCreateAccountScreen()),
      GoRoute(path: '/admin/user/:id',
        builder: (_, state) => AdminUserDetailScreen(
          userId: state.pathParameters['id']!)),
    ],
  );
});

// ── App ───────────────────────────────────────────────────────
class EpiTrackApp extends ConsumerWidget {
  const EpiTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    // Démarrer le scheduler de rappels dès le lancement
    ref.watch(reminderProvider);
    ref.watch(vitalsSyncProvider); // sync BLE → Firestore (global, pas dans le dashboard)

    return MaterialApp.router(
      title: 'EpiTrack',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: router,
      builder: (context, child) => ReminderListener(
        child: MedicalBackground(
          dense: true,
          child: child ?? const SizedBox())),
      locale: const Locale('fr'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr'), Locale('en')],
    );
  }

  ThemeData _buildTheme() => ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      primaryContainer: AppColors.primarySurface,
      secondary: AppColors.teal,
      secondaryContainer: AppColors.tealPale,
      surface: AppColors.surface,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      outline: AppColors.cardBorder,
    ),
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: const BorderSide(color: AppColors.cardBorder),
        textStyle: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cardBorder)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cardBorder)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      labelStyle: const TextStyle(
        color: AppColors.textSecondary),
      hintStyle: const TextStyle(
        color: AppColors.textHint),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primarySurface,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11, color: AppColors.primary);
        }
        return const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11, color: AppColors.textHint);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primary, size: 22);
        }
        return const IconThemeData(color: AppColors.textHint, size: 22);
      }),
      elevation: 0,
      height: 64,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.cardBorder, thickness: 0.8),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceAlt,
      labelStyle: const TextStyle(fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      elevation: 8,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected) ? AppColors.primary : Colors.grey),
      trackColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected)
          ? AppColors.primaryLight.withValues(alpha: 0.4)
          : Colors.grey.shade300),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 28,
        fontWeight: FontWeight.w800, color: AppColors.textPrimary),
      headlineMedium: TextStyle(fontSize: 22,
        fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      titleLarge: TextStyle(fontSize: 18,
        fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      titleMedium: TextStyle(fontSize: 16,
        fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleSmall: TextStyle(fontSize: 14,
        fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      bodyLarge: TextStyle(fontSize: 15,
        color: AppColors.textPrimary),
      bodyMedium: TextStyle(fontSize: 14,
        color: AppColors.textPrimary),
      bodySmall: TextStyle(fontSize: 12,
        color: AppColors.textSecondary),
      labelSmall: TextStyle(fontSize: 11,
        color: AppColors.textHint),
    ),
  );
}

// ── Shell Patient ────────────────────────────────────────────
class _PatientShell extends StatelessWidget {
  final Widget child;
  const _PatientShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = ['/patient/dashboard', '/patient/signals',
                 '/patient/history',   '/patient/settings']
      .indexOf(location).clamp(0, 3);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -4)),
          ],
        ),
        child: NavigationBar(
          selectedIndex: idx,
          onDestinationSelected: (i) => context.go([
            '/patient/dashboard', '/patient/signals',
            '/patient/history',   '/patient/settings'][i]),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Accueil'),
            NavigationDestination(
              icon: Icon(Icons.show_chart_outlined),
              selectedIcon: Icon(Icons.show_chart_rounded),
              label: 'Signaux'),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history_rounded),
              label: 'Historique'),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Réglages'),
          ],
        ),
      ),
    );
  }
}

// ── Shell Famille ────────────────────────────────────────────
class _FamilyShell extends StatelessWidget {
  final Widget child;
  const _FamilyShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = ['/family/dashboard', '/family/alerts',
                 '/family/contacts',  '/family/settings']
      .indexOf(location).clamp(0, 3);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -4)),
          ],
        ),
        child: NavigationBar(
          selectedIndex: idx,
          onDestinationSelected: (i) => context.go([
            '/family/dashboard', '/family/alerts',
            '/family/contacts',  '/family/settings'][i]),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Accueil'),
            NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications_rounded),
              label: 'Alertes'),
            NavigationDestination(
              icon: Icon(Icons.contacts_outlined),
              selectedIcon: Icon(Icons.contacts_rounded),
              label: 'Contacts'),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Réglages'),
          ],
        ),
      ),
    );
  }
}

// ── Shell Médecin ────────────────────────────────────────────
class _DoctorShell extends StatelessWidget {
  final Widget child;
  const _DoctorShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = ['/doctor/patients', '/doctor/alerts', '/doctor/settings']
      .indexOf(location).clamp(0, 2);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -4)),
          ],
        ),
        child: NavigationBar(
          selectedIndex: idx,
          onDestinationSelected: (i) => context.go([
            '/doctor/patients', '/doctor/alerts', '/doctor/settings'][i]),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.people_outline_rounded),
              selectedIcon: Icon(Icons.people_rounded),
              label: 'Patients'),
            NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications_rounded),
              label: 'Alertes'),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Réglages'),
          ],
        ),
      ),
    );
  }
}

// ── Shell Admin ──────────────────────────────────────────────
class _AdminShell extends StatelessWidget {
  final Widget child;
  const _AdminShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = ['/admin/dashboard', '/admin/accounts']
      .indexOf(location).clamp(0, 1);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -4)),
          ],
        ),
        child: NavigationBar(
          selectedIndex: idx,
          onDestinationSelected: (i) => context.go([
            '/admin/dashboard', '/admin/accounts'][i]),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Tableau de bord'),
            NavigationDestination(
              icon: Icon(Icons.manage_accounts_outlined),
              selectedIcon: Icon(Icons.manage_accounts_rounded),
              label: 'Comptes'),
          ],
        ),
      ),
    );
  }
}
