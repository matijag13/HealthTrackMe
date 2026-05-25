import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:healthtrackme/config/app_router.dart';
import 'package:healthtrackme/config/theme.dart';
import 'package:healthtrackme/main.dart';
import 'package:healthtrackme/screens/auth_screen.dart';

void main() {
  testWidgets('Preverjanje zagona aplikacije z routerjem',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: HealthTrackMeApp(router: createAppRouter()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuthScreen), findsOneWidget);
  });
}
