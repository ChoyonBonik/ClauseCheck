import 'package:flutter_test/flutter_test.dart';
import 'package:clause_check/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ClauseCheckApp());
    expect(find.text('ClauseCheck'), findsOneWidget);
  });
}
