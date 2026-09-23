import 'package:edfapay_pg_plugin/edfapay_pg_sdk.dart';

/// Thin wrapper around the static [EdfaPgSdk] facade so the UI layer
/// stays free of direct static SDK calls (testable, DI-friendly).
class EdfaPayPaymentService {
  Future<void> initialize({
    required String apiKey,
    required String baseUrl,
    bool enableLogs = true,
  }) async {
    await EdfaPgSdk.setEnableLogs(enableLogs);
    await EdfaPgSdk.initialize(apiKey: apiKey, baseUrl: baseUrl);
  }

  CardPay cardPay() => EdfaPgSdk.cardPay();

  Future<void> startCheckout(CardPay cardPay) => cardPay.start();

  /// Executes an Apple Pay charge (iOS only; returns a failure map on Android).
  Future<Map<String, dynamic>> applePay(ApplePayRequest request) =>
      EdfaPgSdk.applePay(request);
}