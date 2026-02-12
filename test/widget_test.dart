import 'package:flutter_test/flutter_test.dart';

import 'package:furrow/app.dart';

void main() {
  testWidgets('FurrowApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FurrowApp());

    // Verify the app builds without errors.
    expect(find.byType(FurrowApp), findsOneWidget);
  });
}
