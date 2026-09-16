import 'package:flutter_test/flutter_test.dart';
import 'package:swasthyasathi/main.dart';
import 'package:swasthyasathi/src/features/patient_dashboard/view/patient_dashboard_view.dart';

void main() {
  testWidgets('Patient dashboard loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SwasthyaSathiApp());

    // Verify that PatientDashboardView is present.
    expect(find.byType(PatientDashboardView), findsOneWidget);
  });
}
