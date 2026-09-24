import 'package:flutter_test/flutter_test.dart';

import 'package:edfah_pay/main.dart';
import 'package:edfah_pay/services/apple_pay_service.dart';

void main() {
  testWidgets('Checkout screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const EdfaPayApp());

    expect(find.text('Order'), findsOneWidget);
    expect(find.text('Payer'), findsOneWidget);
    expect(find.text('Pay now'), findsOneWidget);
  });

  test('Apple Pay uses a configured merchant identifier', () {
    expect(ApplePayService.merchantIdentifier, isNotEmpty);
    expect(
      ApplePayService.merchantIdentifier,
      isNot('REPLACE_WITH_YOUR_APPLE_MERCHANT_ID'),
    );
  });
}
