import 'dart:io' show Platform;

import 'package:edfapay_pg_plugin/edfapay_pg_sdk.dart';
import 'package:flutter/services.dart';

import '../config/edfapay_config.dart';
import 'edfapay_payment_service.dart';

/// Presents the native Apple Pay sheet (via a platform channel on iOS) and
/// then charges the resulting payment token with the EdfaPay SDK.
class ApplePayService {
  static const _channel = MethodChannel('edfah_pay/apple_pay');

  /// Your merchant identifier, registered in the Apple Developer portal and
  /// linked to EdfaPay. Sandbox test prefixes are often `merchant.sandbox.`.
  static const String merchantIdentifier =
      EdfaPayConfig.appleMerchantIdentifier;

  final EdfaPayPaymentService _edfaPay;

  ApplePayService([EdfaPayPaymentService? edfaPay])
    : _edfaPay = edfaPay ?? EdfaPayPaymentService();

  /// Whether Apple Pay is available on this device (iOS only).
  bool get isSupported => Platform.isIOS;

  Future<Map<String, dynamic>> pay({
    required double amount,
    required String currency,
    required String countryCode,
    required String summaryLabel,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String orderId,
  }) async {
    final configuredMerchantId = merchantIdentifier.trim();
    if (configuredMerchantId.isEmpty ||
        configuredMerchantId == 'REPLACE_WITH_YOUR_APPLE_MERCHANT_ID') {
      throw StateError(
        'Apple Pay is not configured. Set a valid merchant identifier in '
        'EdfaPayConfig.appleMerchantIdentifier.',
      );
    }

    final token = await _channel.invokeMethod<String>('presentApplePay', {
      'merchantIdentifier': configuredMerchantId,
      'amount': amount.toString(),
      'currencyCode': currency,
      'countryCode': countryCode,
      'summaryLabel': summaryLabel,
    });

    if (token == null || token.isEmpty) {
      throw StateError('Apple Pay was cancelled or returned no token.');
    }

    final request = ApplePayRequest(
      orderId: orderId,
      amount: amount,
      currency: currency,
      customer: ApplePayCustomer(
        name: customerName,
        email: customerEmail,
        phone: customerPhone,
      ),
      successUrl: EdfaPayConfig.successUrl,
      failureUrl: EdfaPayConfig.failureUrl,
      card: ApplePayCard(token: token),
    );

    return _edfaPay.applePay(request);
  }
}
