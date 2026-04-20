import 'package:flutter_test/flutter_test.dart';
import 'package:chargego/src/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App starts and shows onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ChargeGoApp(),
      ),
    );

    expect(find.text('Welcome to ChargeGO'), findsOneWidget);
  });
}
