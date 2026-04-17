// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:mediq_final/main.dart';

void main() {
  testWidgets('MediQ app loads role selection screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('MediQ'), findsOneWidget);
    expect(find.text('Choisissez votre rôle'), findsOneWidget);
    expect(find.text('Patient'), findsOneWidget);
    expect(find.text('Administrateur'), findsOneWidget);
  });
}
