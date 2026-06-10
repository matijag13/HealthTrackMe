import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:healthtrackme/config/app_router.dart';
import 'package:healthtrackme/config/locale_provider.dart';
import 'package:healthtrackme/config/theme.dart';
import 'package:healthtrackme/config/locale_provider.dart';
import 'package:healthtrackme/main.dart';
import 'package:healthtrackme/screens/auth_screen.dart';

void main() {
  testWidgets('Preverjanje zagona aplikacije z routerjem',
      (WidgetTester tester) async {
    // The app build uses Consumer2<ThemeProvider, LocaleProvider>, so both
    // providers must be in the tree (matches main.dart's MultiProvider).
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ],
        child: HealthTrackMeApp(router: createAppRouter()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuthScreen), findsOneWidget);
  });
}
