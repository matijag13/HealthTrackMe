import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppColors {
  static const Color primary = Color(0xFF0A84FF);
  static const Color blue = primary;
  static const Color teal = Color(0xFF32D74B);
  static const Color success = Color(0xFF32D74B);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color danger = Color(0xFFFF453A);
  static const Color info = Color(0xFF0A84FF);
  static const Color navy = Color(0xFF0B1F33);
  static const Color heartRate = Color(0xFFFF6B6B);
  static const Color sleep = Color(0xFF6C63FF);
  static const Color steps = Color(0xFF00C896);
  static const Color weight = Color(0xFFFF9500);
  static const Color calories = Color(0xFFFF3B30);
  static const Color softBlue = Color(0xFFEAF4FB);
  static const Color muted = Color(0xFF64748B);

  static const Color lightBackground = Color(0xFFF2F4F8);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color background = lightBackground;
  static const Color card = lightCard;

  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkCard = Color(0xFF161B22);
  static const Color darkSurface = Color(0xFF1C2128);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFD7DDE6);
  static const Color amber = Color(0xFFFFB020);
  static const Color green = Color(0xFF22C55E);
  static const Color orange = Color(0xFFF97316);
}

class AppTheme {
  static ThemeData get light {
    final base = FlexColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.teal,
      surface: AppColors.lightSurface,
      background: AppColors.lightBackground,
      appBarStyle: FlexAppBarStyle.primary,
      subThemesData: const FlexSubThemesData(
        defaultRadius: 16,
        cardRadius: 16,
        dialogRadius: 16,
        inputDecoratorRadius: 16,
        elevatedButtonRadius: 12,
        outlinedButtonRadius: 12,
        textButtonRadius: 12,
        chipRadius: 8,
      ),
    ).toTheme;

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);
    final displayTheme = GoogleFonts.soraTextTheme(textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.lightBackground,
      textTheme: textTheme.copyWith(
        displayLarge: displayTheme.displayLarge,
        displayMedium: displayTheme.displayMedium,
        displaySmall: displayTheme.displaySmall,
        headlineLarge: displayTheme.headlineLarge,
        headlineMedium: displayTheme.headlineMedium,
        headlineSmall: displayTheme.headlineSmall,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: GoogleFonts.sora(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: AppColors.lightCard,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: AppColors.border),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        elevation: 0,
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }

  static ThemeData get dark {
    final base = FlexColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.teal,
      surface: AppColors.darkSurface,
      background: AppColors.darkBackground,
      appBarStyle: FlexAppBarStyle.background,
      subThemesData: const FlexSubThemesData(
        defaultRadius: 16,
        cardRadius: 16,
        dialogRadius: 16,
        inputDecoratorRadius: 16,
        elevatedButtonRadius: 12,
        outlinedButtonRadius: 12,
        textButtonRadius: 12,
        chipRadius: 8,
      ),
    ).toTheme;

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);
    final displayTheme = GoogleFonts.soraTextTheme(textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: textTheme.copyWith(
        displayLarge: displayTheme.displayLarge,
        displayMedium: displayTheme.displayMedium,
        displaySmall: displayTheme.displaySmall,
        headlineLarge: displayTheme.headlineLarge,
        headlineMedium: displayTheme.headlineMedium,
        headlineSmall: displayTheme.headlineSmall,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: AppColors.darkCard,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: GoogleFonts.sora(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: AppColors.darkCard,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2A313C), width: 1),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: Color(0xFF2A313C)),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2A313C)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2A313C)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkCard,
        indicatorColor: AppColors.primary.withValues(alpha: 0.20),
        elevation: 0,
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}

class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoaded = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLoaded => _isLoaded;

  Future<void> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_themeModeKey);
    _themeMode = savedMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) {
      return;
    }
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    await setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> useLightTheme() => setThemeMode(ThemeMode.light);

  Future<void> useDarkTheme() => setThemeMode(ThemeMode.dark);
}

