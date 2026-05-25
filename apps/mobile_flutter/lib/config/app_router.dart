import 'package:go_router/go_router.dart';
import '../screens/medicines_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/log_screen.dart';
import '../screens/main_app.dart';
import '../screens/reports_screen.dart';
import '../screens/router_pages.dart';
import '../screens/health_screen.dart';
import '../screens/onboarding_screen.dart';
import '../services/api_service.dart';

GoRouter createAppRouter() {
  final api = ApiService.instance;

  bool isAuthenticated() => api.activeUserId != null;

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final location = state.matchedLocation;
      final loggedIn = isAuthenticated();
      final goingToAuth = location == '/auth';

      if (!loggedIn && !goingToAuth) {
        return '/auth';
      }
      if (loggedIn && goingToAuth) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainApp(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/log',
                name: 'log',
                builder: (context, state) => const LogScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/health',
                name: 'health',
                builder: (context, state) => const HealthScreenTabbed(),
                routes: [
                  GoRoute(
                    path: 'vitals',
                    name: 'healthVitals',
                    builder: (context, state) => const HealthVitalsPage(),
                  ),
                  GoRoute(
                    path: 'activity',
                    name: 'healthActivity',
                    builder: (context, state) => const HealthActivityPage(),
                  ),
                  GoRoute(
                    path: 'sleep',
                    name: 'healthSleep',
                    builder: (context, state) => const HealthSleepPage(),
                  ),
                  GoRoute(
                    path: 'history',
                    name: 'healthHistory',
                    builder: (context, state) => const ReportsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/meds',
                name: 'meds',
                builder: (context, state) => const MedicinesScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    name: 'medsAdd',
                    builder: (context, state) => const MedicineAddPage(),
                  ),
                  GoRoute(
                    path: 'detail/:id',
                    name: 'medsDetail',
                    builder: (context, state) {
                      final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                      return MedicineDetailPage(medicineId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'profileEdit',
                    builder: (context, state) => const ProfileEditRoutePage(),
                  ),
                  GoRoute(
                    path: 'settings',
                    name: 'profileSettings',
                    builder: (context, state) => const ProfileSettingsPage(),
                  ),
                  GoRoute(
                    path: 'medical-history',
                    name: 'profileMedicalHistory',
                    builder: (context, state) => const ProfileMedicalHistoryPage(),
                  ),
                  GoRoute(
                    path: 'export',
                    name: 'profileExport',
                    builder: (context, state) => const ProfileExportPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/diary/:date',
        name: 'diaryDate',
        builder: (context, state) {
          final date = state.pathParameters['date'] ?? '';
          return DiaryEntryViewPage(date: date);
        },
      ),
    ],
  );
}



