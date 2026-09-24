import 'package:flutter_test/flutter_test.dart';
import 'package:vertice/main.dart';

void main() {
  testWidgets('VerticeApp splash smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VerticeApp());
    expect(find.text('G E O T U R I S M O'), findsOneWidget);
    expect(find.text('SYS-BOOT // V1.0'), findsOneWidget);
  });
}
