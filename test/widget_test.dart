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
