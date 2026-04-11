import 'package:flutter_test/flutter_test.dart';
import 'package:proyectofinal_dados/main.dart';

void main() {
  testWidgets('App renders splash title', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pump(const Duration(seconds: 4));

    expect(find.text('Dado Triple'), findsOneWidget);
  });
}
