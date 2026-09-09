import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:device_inspector/device_inspector.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getInfo integration test', (WidgetTester tester) async {
    final info = await DeviceInspector.getInfo();
    expect(info, isNotNull);
    final capabilities = await DeviceInspector.getCapabilities();
    expect(capabilities, isNotNull);
  });
}
