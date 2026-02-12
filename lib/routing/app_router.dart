import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'page_transitions.dart';

import '../features/garden/presentation/screens/garden_screen.dart';
import '../features/journal/presentation/screens/journal_screen.dart';
import '../features/alerts/presentation/screens/alerts_screen.dart';
import '../features/seasons/presentation/screens/seasons_screen.dart';
import '../features/add_plant/presentation/screens/add_plant_screen.dart';
import '../features/add_plant/presentation/screens/edit_plant_screen.dart';
import '../features/garden/presentation/screens/plant_detail_screen.dart';
import '../features/journal/presentation/screens/add_journal_entry_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/analytics/presentation/screens/analytics_screen.dart';
import '../features/seasons/presentation/screens/season_detail_screen.dart';
import '../features/paywall/presentation/screens/paywall_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';

/// Navigator keys for each tab branch
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _gardenNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'garden');
final _journalNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'journal');
final _alertsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'alerts');
final _seasonsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'seasons');

/// GoRouter configuration with StatefulShellRoute for bottom navigation
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/garden',
  routes: [
    // Main tabbed shell
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return _ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        // Tab 1: Garden
        StatefulShellBranch(
          navigatorKey: _gardenNavigatorKey,
          routes: [
            GoRoute(
              path: '/garden',
              builder: (context, state) => const GardenScreen(),
            ),
          ],
        ),

        // Tab 2: Journal
        StatefulShellBranch(
          navigatorKey: _journalNavigatorKey,
          routes: [
            GoRoute(
              path: '/journal',
              builder: (context, state) => const JournalScreen(),
            ),
          ],
        ),

        // Tab 3: Alerts
        StatefulShellBranch(
          navigatorKey: _alertsNavigatorKey,
          routes: [
            GoRoute(
              path: '/alerts',
              builder: (context, state) => const AlertsScreen(),
            ),
          ],
        ),

        // Tab 4: Seasons
        StatefulShellBranch(
          navigatorKey: _seasonsNavigatorKey,
          routes: [
            GoRoute(
              path: '/seasons',
              builder: (context, state) => const SeasonsScreen(),
            ),
          ],
        ),
      ],
    ),

    // Full-screen routes (outside bottom nav)
    GoRoute(
      path: '/add-plant',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppTransitions.modal(
        key: state.pageKey,
        child: const AddPlantScreen(),
      ),
    ),
    GoRoute(
      path: '/plant/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppTransitions.detail(
        key: state.pageKey,
        child: PlantDetailScreen(
          plantId: state.pathParameters['id']!,
        ),
      ),
    ),
    GoRoute(
      path: '/edit-plant/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppTransitions.modal(
        key: state.pageKey,
        child: EditPlantScreen(
          plantId: state.pathParameters['id']!,
        ),
      ),
    ),
    GoRoute(
      path: '/add-journal',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final plantId = state.uri.queryParameters['plantId'];
        return AppTransitions.modal(
          key: state.pageKey,
          child: AddJournalEntryScreen(preselectedPlantId: plantId),
        );
      },
    ),
    GoRoute(
      path: '/analytics',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppTransitions.utility(
        key: state.pageKey,
        child: const AnalyticsScreen(),
      ),
    ),
    GoRoute(
      path: '/season/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppTransitions.detail(
        key: state.pageKey,
        child: SeasonDetailScreen(
          seasonId: state.pathParameters['id']!,
        ),
      ),
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppTransitions.utility(
        key: state.pageKey,
        child: const SettingsScreen(),
      ),
    ),
    GoRoute(
      path: '/paywall',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final feature = state.uri.queryParameters['feature'];
        return AppTransitions.utility(
          key: state.pageKey,
          child: PaywallScreen(feature: feature),
        );
      },
    ),
    GoRoute(
      path: '/onboarding',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppTransitions.fadeThrough(
        key: state.pageKey,
        child: const OnboardingScreen(),
      ),
    ),
    GoRoute(
      path: '/login',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppTransitions.fadeThrough(
        key: state.pageKey,
        child: const LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/register',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => AppTransitions.fadeThrough(
        key: state.pageKey,
        child: const RegisterScreen(),
      ),
    ),
  ],
);

/// Internal scaffold widget with Material 3 NavigationBar + FAB
class _ScaffoldWithNavBar extends StatelessWidget {
  const _ScaffoldWithNavBar({
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-plant'),
        tooltip: 'Add Plant',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.yard_outlined),
            selectedIcon: Icon(Icons.yard),
            label: 'Garden',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: 'Journal',
          ),
          NavigationDestination(
            icon: Icon(Icons.ac_unit_outlined),
            selectedIcon: Icon(Icons.ac_unit),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Seasons',
          ),
        ],
      ),
    );
  }
}
