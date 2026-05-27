import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'dashboard_screen.dart';
import 'medicines_screen.dart';
import 'profile_screen.dart';

class MainApp extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainApp({
    super.key,
    required this.navigationShell,
  });

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: (index) {
          // Force branch to the branch's initial location so switching tabs
          // reliably navigates to the expected screen (avoids showing the
          // previous branch view in some edge cases).
          try {
            widget.navigationShell.goBranch(index, initialLocation: true);
          } catch (_) {
            // Fallback if goBranch signature differs in the environment
            widget.navigationShell.goBranch(index);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Log',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Health',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication),
            label: 'Medicines',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}