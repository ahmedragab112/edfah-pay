import Flutter
import UIKit
import PassKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  private var pendingApplePayResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let messenger = engineBridge.applicationRegistrar.messenger()
    let channel = FlutterMethodChannel(
      name: "edfah_pay/apple_pay",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "presentApplePay" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let self else {
        result(
          FlutterError(
            code: "APP_DELEGATE_GONE",
            message: "App delegate unavailable.",
            details: nil
          )
        )
        return
      }
      self.presentApplePay(arguments: call.arguments, result: result)
    }
  }

  // MARK: - Apple Pay

  private func presentApplePay(arguments: Any?, result: @escaping FlutterResult) {
    guard PKPaymentAuthorizationViewController.canMakePayments() else {
      result(
        FlutterError(
          code: "APPLE_PAY_UNAVAILABLE",
          message: "Apple Pay is not configured on this device.",
          details: nil
        )
      )
      return
    }

    guard
      let args = arguments as? [String: Any],
      let merchantId = args["merchantIdentifier"] as? String,
      !merchantId.isEmpty,
      merchantId != "REPLACE_WITH_YOUR_APPLE_MERCHANT_ID"
    else {
      result(
        FlutterError(
          code: "MERCHANT_ID_REQUIRED",
          message: "Set your Apple merchant identifier in ApplePayService.",
          details: nil
        )
      )
      return
    }

    let request = PKPaymentRequest()
    request.merchantIdentifier = merchantId
    request.supportedNetworks = [.visa, .masterCard, .amex, .discover]
    request.merchantCapabilities = [.capability3DS, .capabilityCredit, .capabilityDebit]
    request.currencyCode = (args["currencyCode"] as? String) ?? "SAR"
    request.countryCode = (args["countryCode"] as? String) ?? "SA"

    let rawAmount = (args["amount"] as? String) ?? "0"
    let amount = NSDecimalNumber(string: rawAmount)
    let label = (args["summaryLabel"] as? String) ?? "Order"
    request.paymentSummaryItems = [
      PKPaymentSummaryItem(label: label, amount: amount)
    ]

    guard let controller = PKPaymentAuthorizationViewController(paymentRequest: request) else {
      result(
        FlutterError(
          code: "APPLE_PAY_SHEET_FAILED",
          message: "Could not present the Apple Pay sheet. Check the merchant identifier.",
          details: nil
        )
      )
      return
    }

    controller.delegate = self
    pendingApplePayResult = result

    guard let topViewController = topViewController() else {
      pendingApplePayResult = nil
      result(
        FlutterError(
          code: "NO_VIEW_CONTROLLER",
          message: "No presenting view controller available.",
          details: nil
        )
      )
      return
    }
    topViewController.present(controller, animated: true, completion: nil)
  }

  private func topViewController() -> UIViewController? {
    let candidates: [UIViewController?] = [
      window?.rootViewController,
      UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.windows.first(where: \.isKeyWindow) }
        .first?.rootViewController,
    ]

    var top: UIViewController? = candidates.first { $0 != nil } ?? nil
    while let presented = top?.presentedViewController {
      top = presented
    }
    if let navigationController = top as? UINavigationController {
      return navigationController.visibleViewController ?? top
    }
    return top
  }

  private func sendApplePayResult(_ value: Any?) {
    guard let pending = pendingApplePayResult else { return }
    pendingApplePayResult = nil
    pending(value)
  }
}

// MARK: - PKPaymentAuthorizationViewControllerDelegate

extension AppDelegate: PKPaymentAuthorizationViewControllerDelegate {

  func paymentAuthorizationViewController(
    _ controller: PKPaymentAuthorizationViewController,
    didAuthorizePayment payment: PKPayment,
    handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
  ) {
    completion(PKPaymentAuthorizationResult(status: .success, errors: nil))

    let token = payment.token.paymentData.base64EncodedString()
    sendApplePayResult(token)
  }

  func paymentAuthorizationViewControllerDidFinish(
    _ controller: PKPaymentAuthorizationViewController
  ) {
    controller.dismiss(animated: true) { [weak self] in
      if self?.pendingApplePayResult != nil {
        self?.sendApplePayResult(nil)
      }
    }
  }
}