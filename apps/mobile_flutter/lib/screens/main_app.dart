import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    );
  }
}
