import 'package:flutter/material.dart';

/// Shell widget that wraps tabbed screens with a Material 3 NavigationBar
/// and a floating action button for adding plants
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  final Widget navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to add plant screen via GoRouter
          // context.push('/add-plant');
        },
        tooltip: 'Add Plant',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex(context),
        onDestinationSelected: (index) => _onTap(context, index),
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

  int _currentIndex(BuildContext context) {
    // TODO: Derive from GoRouter state
    // For now, return 0 (Garden tab)
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    // TODO: Navigate to the correct branch via GoRouter
    // switch (index) {
    //   case 0: context.go('/garden');
    //   case 1: context.go('/journal');
    //   case 2: context.go('/alerts');
    //   case 3: context.go('/seasons');
    // }
  }
}
