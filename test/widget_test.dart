import 'package:flutter_test/flutter_test.dart';

import 'package:edfah_pay/main.dart';

void main() {
  testWidgets('Checkout screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const EdfaPayApp());

    expect(find.text('Order'), findsOneWidget);
    expect(find.text('Payer'), findsOneWidget);
    expect(find.text('Pay now'), findsOneWidget);
  });
}