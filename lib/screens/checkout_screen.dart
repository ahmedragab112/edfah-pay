import 'dart:developer';

import 'package:edfapay_pg_plugin/edfapay_pg_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../config/edfapay_config.dart';
import '../services/apple_pay_service.dart';
import '../services/edfapay_payment_service.dart';
import '../widgets/section_header.dart';

const _uuid = Uuid();

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _service = EdfaPayPaymentService();
  final _applePayService = ApplePayService();
  late final bool _applePaySupported = _applePayService.isSupported;

  final _amountController = TextEditingController(text: '1.00');
  final _currencyController = TextEditingController(text: 'SAR');
  final _descriptionController = TextEditingController(text: 'Sample order');
  final _firstNameController = TextEditingController(text: 'First');
  final _lastNameController = TextEditingController(text: 'Last');
  final _emailController =
      TextEditingController(text: 'customer@example.com');
  final _phoneController = TextEditingController(text: '+966500000000');
  final _addressController = TextEditingController(text: 'Street 1');
  final _cityController = TextEditingController(text: 'Riyadh');
  final _countryController = TextEditingController(text: 'SA');
  final _zipController = TextEditingController(text: '12345');

  EdfaPayDesignType _designType = EdfaPayDesignType.one;
  EdfaPayLanguage _language = EdfaPayLanguage.en;
  bool _auth = false;
  bool _isPaying = false;

  @override
  void dispose() {
    _amountController.dispose();
    _currencyController.dispose();
    _descriptionController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _startCheckout() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showMessage('Please enter a valid amount.');
      return;
    }

    setState(() => _isPaying = true);

    try {
      final cardPay = _service.cardPay()
        ..setOrder(EdfaPgSaleOrder(
          id: _uuid.v4(),
          amount: amount,
          currency: _currencyController.text.trim().toUpperCase(),
          description: _descriptionController.text.trim(),
        ))
        ..setPayer(EdfaPgPayer(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          address: _addressController.text.trim(),
          country: _countryController.text.trim().toUpperCase(),
          city: _cityController.text.trim(),
          zip: _zipController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          ip: '203.0.113.10',
        ))
        ..setDesignType(_designType)
        ..setLanguage(_language)
        ..setAuth(_auth)
        ..setResultUrls(
          successUrl: EdfaPayConfig.successUrl,
          failureUrl: EdfaPayConfig.failureUrl,
        )
        ..onTransactionSuccess((result) {
          _showResult('Payment approved', result);
        })
        ..onTransactionFailure((error) {
          _showMessage('Payment failed: ${error ?? 'Unknown error'}');
        })
        ..onDismiss(() {
          if (mounted) setState(() => _isPaying = false);
        });

      await _service.startCheckout(cardPay);
    } on EdfaPgSdkIsNotInitializedException {
      if (mounted) {
        _showMessage('SDK not initialised. Please restart the app.');
        setState(() => _isPaying = false);
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Error starting checkout: $error');
        setState(() => _isPaying = false);
      }
    }
  }

  Future<void> _startApplePay() async {
    final amount = double.tryParse(_amountController.text);
    final currency = _currencyController.text.trim().toUpperCase();
    if (amount == null || amount <= 0 || currency.isEmpty) {
      _showMessage('Please enter a valid amount and currency.');
      return;
    }

    setState(() => _isPaying = true);

    try {
      final result = await _applePayService.pay(
        amount: amount,
        currency: currency,
        countryCode: _countryController.text.trim().toUpperCase(),
        summaryLabel: _descriptionController.text.trim().isEmpty
            ? 'Order'
            : _descriptionController.text.trim(),
        customerName:
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
                .trim(),
        customerEmail: _emailController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        orderId: _uuid.v4(),
      );
      
      _showResult('Apple Pay approved', result);
    } on MissingPluginException {
      if (mounted) {
        _showMessage(
            'Apple Pay is only available on iOS. Rebuild on a device.');
        setState(() => _isPaying = false);
      }
    } catch (error,stackTrace) {
      log(error.toString(), stackTrace: stackTrace);
      if (mounted) {
        _showMessage('Apple Pay failed: $error');
        setState(() => _isPaying = false);
      }
    }
  }

  void _showResult(String title, dynamic payload) {
    if (mounted) {
      setState(() => _isPaying = false);
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text('$payload',
                style: const TextStyle(fontFamily: 'monospace')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EdfaPay Checkout'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(title: 'Order', icon: Icons.receipt_long),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _currencyController,
              decoration:
                  const InputDecoration(labelText: 'Currency (e.g. SAR)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Payer', icon: Icons.person),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _firstNameController,
                    decoration:
                        const InputDecoration(labelText: 'First name'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _lastNameController,
                    decoration:
                        const InputDecoration(labelText: 'Last name'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _countryController,
                    decoration:
                        const InputDecoration(labelText: 'Country (SA)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _zipController,
                    decoration: const InputDecoration(labelText: 'Zip'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Checkout UI', icon: Icons.tune),
            DropdownButtonFormField<EdfaPayDesignType>(
              initialValue: _designType,
              decoration: const InputDecoration(labelText: 'Design type'),
              items: EdfaPayDesignType.values
                  .map((d) => DropdownMenuItem(
                        value: d,
                        child: Text(d.wireName),
                      ))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _designType = value ?? _designType),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<EdfaPayLanguage>(
              initialValue: _language,
              decoration: const InputDecoration(labelText: 'Language'),
              items: EdfaPayLanguage.values
                  .map((l) => DropdownMenuItem(
                        value: l,
                        child: Text(l.wireName),
                      ))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _language = value ?? _language),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pre-auth (authorise, capture later)'),
              value: _auth,
              onChanged: (value) => setState(() => _auth = value),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isPaying ? null : _startCheckout,
              icon: _isPaying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock),
              label: Text(_isPaying ? 'Opening checkout…' : 'Pay now'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            if (_applePaySupported) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: _isPaying ? null : _startApplePay,
                icon: const Icon(Icons.apple),
                label: Text(_isPaying ? 'Processing…' : 'Apple Pay'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}