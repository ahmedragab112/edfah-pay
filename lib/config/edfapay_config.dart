/// EdfaPay merchant configuration.
///
/// Replace with your real credentials issued by EdfaPay:
///   Production base URL: https://app-api.edfapay.com
///   Staging base URL:    provided per merchant by EdfaPay support
class EdfaPayConfig {
  static const String apiKey =
      '694092ABD74192F9B5BC475AAD6FB583CAAA5EAE00C0CDA91F673A81CD0E5195';
  static const String baseUrl = 'https://app-api.edfapay.com';
  static const String successUrl = 'https://edfapay.com/process-completed';
  static const String failureUrl = 'https://edfapay.com/process-failed';

  /// Temporarily set a static Apple merchant identifier for local testing.
  /// Replace this with your real merchant identifier from Apple Developer.
  static const String appleMerchantIdentifier = 'merchant.com.edfahpay.test';

  EdfaPayConfig._();
}
