import 'package:flutter_test/flutter_test.dart';
import 'package:vertice/main.dart';

void main() {
  testWidgets('VerticeApp splash smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VerticeApp());
    expect(find.text('N E X T   T R I P'), findsOneWidget);
    expect(find.text('SYS-BOOT // v1.4.0 (beta)'), findsOneWidget);
  });
}
