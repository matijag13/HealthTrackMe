import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'services/api_service.dart';
import 'services/background_sync_service.dart';
import 'services/notification_service.dart';
import 'config/theme.dart';
import 'config/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.instance.init();
  await NotificationService.instance.initialize();
  await BackgroundSyncService.init();
  await BackgroundSyncService.schedulePeriodicSync();

  // Configure system UI overlay style (status bar)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // Set preferred device orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final themeProvider = ThemeProvider();
  await themeProvider.loadThemeMode();
  final router = createAppRouter();

  runApp(
    ChangeNotifierProvider.value(
      value: themeProvider,
      child: HealthTrackMeApp(router: router),
    ),
  );
}

class HealthTrackMeApp extends StatefulWidget {
  final GoRouter router;

  const HealthTrackMeApp({required this.router, super.key});

  @override
  State<HealthTrackMeApp> createState() => _HealthTrackMeAppState();
}

class _HealthTrackMeAppState extends State<HealthTrackMeApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Fire a quick background sync whenever the app comes back to the foreground
  /// so data feels up-to-date without the user pressing Sync.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      BackgroundSyncService.syncNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        // Update system UI overlay based on theme
        final isDark = themeProvider.themeMode == ThemeMode.dark;
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
          ),
        );

        return MaterialApp.router(
          title: 'HealthTrackMe',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeProvider.themeMode,
          routerConfig: widget.router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
