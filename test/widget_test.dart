// A widget test: it builds your app in memory and checks what is on screen.
// Run them all with: flutter test
//
// You are not required to write more of these, but a project with a few real
// tests reads very differently from one with none.

import 'package:flutter_test/flutter_test.dart';

import 'package:asan/main.dart';

void main() {
  testWidgets('bottom navigation switches between screens', (tester) async {
    await tester.pumpWidget(const Asan());

    expect(find.text('Pantry'), findsOneWidget);
    await tester.tap(find.text('Pantry'));
    await tester.pump();
    expect(find.text('Your pantry items'), findsOneWidget);

    await tester.tap(find.text('Recipes'));
    await tester.pump();

    expect(find.text('Your recipes'), findsOneWidget);

    await tester.tap(find.text('Meals'));
    await tester.pump();

    expect(find.text('Your meal plan'), findsOneWidget);

    await tester.tap(find.text('Groceries'));
    await tester.pump();

    expect(find.text('Your grocery list'), findsOneWidget);
  });
}
