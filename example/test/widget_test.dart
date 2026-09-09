import 'package:flutter_test/flutter_test.dart';
import 'package:device_inspector_example/main.dart';

void main() {
  testWidgets('Verify Device Inspector Example App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const DeviceInspectorExampleApp());
    expect(find.text('Device Inspector'), findsOneWidget);
  });
}
