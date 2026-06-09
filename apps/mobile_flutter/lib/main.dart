import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'services/api_service.dart';
import 'services/background_sync_service.dart';
import 'services/notification_service.dart';
import 'services/sleep_tracking_service.dart';
import 'config/locale_provider.dart';
import 'config/theme.dart';
import 'config/app_router.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.instance.init();
  await NotificationService.instance.initialize();
  await BackgroundSyncService.init();
  await BackgroundSyncService.schedulePeriodicSync();
  // Set up the port the sleep-detector foreground service uses to hand a
  // detected session back to the app for upload.
  SleepTrackingService.instance.initMain();

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
  final localeProvider = LocaleProvider();
  await localeProvider.loadLocale();
  final router = createAppRouter();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: localeProvider),
      ],
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

class _HealthTrackMeAppState extends State<HealthTrackMeApp> {
  // Foreground resume-sync is handled in-process by MainApp (which also refreshes
  // any open screen via SyncEvents). We deliberately do NOT also fire a
  // WorkManager one-off on resume here: the two ran in separate isolates with no
  // shared lock, racing on `health_last_sync_ms` and creating duplicate rows.
  // Background coverage comes from the 15-minute periodic WorkManager task.

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, _) {
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
          locale: localeProvider.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: widget.router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
