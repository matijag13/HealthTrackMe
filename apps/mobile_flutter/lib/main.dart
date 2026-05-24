import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/auth_screen.dart';
import 'config/theme.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.instance.init();
  runApp(const HealthTrackMeApp());
}
class HealthTrackMeApp extends StatelessWidget {
  const HealthTrackMeApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthTrackMe',
      theme: AppTheme.lightTheme,
      home: const AuthScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
