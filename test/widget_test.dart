import 'package:flutter_test/flutter_test.dart';
import 'package:campus_intelligence/main.dart';

void main() {
  testWidgets('Campus Intelligence app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CampusIntelligenceApp());

    // Verify that our main title renders.
    expect(find.text('Campus Intelligence'), findsWidgets);
  });
}