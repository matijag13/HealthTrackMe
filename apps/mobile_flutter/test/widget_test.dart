import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthtrackme/main.dart';

void main() {
  testWidgets('Preverjanje zagona aplikacije in delovanja BottomNavigationBar',
      (WidgetTester tester) async {
    await tester.pumpWidget(const HealthTrackMeApp());
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsOneWidget);

    expect(find.text('Domov'), findsWidgets);
    expect(find.text('Dnevnik'), findsOneWidget);
    expect(find.text('Zdravila'), findsWidgets);
    expect(find.text('Poročila'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    await tester.tap(find.text('Zdravila').last);
    await tester.pumpAndSettle();

    expect(find.text('Zdravila Screen - Coming Soon'), findsOneWidget);
  });
}
