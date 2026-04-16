import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:couple_period_app/app.dart';

void main() {
  testWidgets('shows setup error when bootstrap fails', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CouplePeriodApp(bootstrapError: 'bootstrap failed'),
      ),
    );

    expect(find.text('Firebase setup is incomplete.'), findsOneWidget);
  });
}
