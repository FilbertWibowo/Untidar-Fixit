import 'package:flutter_test/flutter_test.dart';
import 'package:laportidar_frontend/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LaporTidarApp());
    expect(find.byType(LaporTidarApp), findsOneWidget);
  });
}
