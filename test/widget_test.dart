import 'package:flutter_test/flutter_test.dart';
import 'package:swasthyasathi/main.dart';
import 'package:swasthyasathi/src/features/auth/view/welcome_view.dart';

void main() {
  testWidgets('App loads smoke test - shows WelcomeView', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SwasthyaSathiApp());

    // Verify that WelcomeView is present.
    expect(find.byType(WelcomeView), findsOneWidget);
  });
}
