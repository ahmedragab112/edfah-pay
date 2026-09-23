import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'config/edfapay_config.dart';
import 'screens/checkout_screen.dart';
import 'services/edfapay_payment_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initSdk();

  runApp(const EdfaPayApp());
}

Future<void> _initSdk() async {
  final service = EdfaPayPaymentService();
  try {
    await service.initialize(
      apiKey: EdfaPayConfig.apiKey,
      baseUrl: EdfaPayConfig.baseUrl,
      enableLogs: kDebugMode,
    );
  } catch (error) {
    // Already initialised in a previous hot-restart of the same process.
    debugPrint('EdfaPgSdk already initialised: $error');
  }
}

class EdfaPayApp extends StatelessWidget {
  const EdfaPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EdfaPay Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const CheckoutScreen(),
    );
  }
}