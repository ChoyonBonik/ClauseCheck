import 'package:flutter_test/flutter_test.dart';
import 'package:ai_contract_guard/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const AiContractGuardApp());
    expect(find.text('AI Contract Guard'), findsOneWidget);
  });
}
