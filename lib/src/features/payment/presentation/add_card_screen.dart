import 'package:chargego/src/features/auth/data/auth_repository.dart';
import 'package:chargego/src/features/payment/data/payment_repository.dart';
import 'package:chargego/src/features/payment/domain/payment_method.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AddCardScreen extends ConsumerStatefulWidget {
  const AddCardScreen({super.key});

  @override
  ConsumerState<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends ConsumerState<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) return;
      final cardNumber = _cardNumberController.text.trim();

      final newCard = PaymentMethod(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.id,
        type: PaymentMethodType.creditCard,
        last4: cardNumber.substring(cardNumber.length - 4),
        cardBrand: 'Visa',
        expiryDate: _expiryDateController.text,
        holderName: _cardHolderController.text.trim(),
        displayName: _cardHolderController.text.trim(),
      );

      await ref.read(paymentRepositoryProvider).addPaymentMethod(newCard);
      ref.invalidate(paymentMethodsProvider(user.id));
      if (mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anadir tarjeta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _cardHolderController,
                decoration: const InputDecoration(
                  labelText: 'Titular de la tarjeta',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cardNumberController,
                decoration: const InputDecoration(
                  labelText: 'Numero de tarjeta',
                  counterText: '',
                ),
                keyboardType: TextInputType.number,
                maxLength: 16,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                ],
                validator: _validateCardNumber,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryDateController,
                      decoration: const InputDecoration(
                        labelText: 'Fecha (MM/AA)',
                        hintText: 'MM/AA',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                        const ExpiryDateInputFormatter(),
                      ],
                      validator: _validateExpiryDate,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      decoration: const InputDecoration(labelText: 'CVV'),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      validator: (value) => value == null || value.length != 3
                          ? 'Invalid CVV'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Guardar tarjeta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String? _validateCardNumber(String? value) {
  final cardNumber = value?.trim() ?? '';
  if (!RegExp(r'^\d{16}$').hasMatch(cardNumber)) {
    return 'La tarjeta debe tener exactamente 16 numeros';
  }
  return null;
}

String? _validateExpiryDate(String? value) {
  final expiryDate = value?.trim() ?? '';
  final match = RegExp(r'^(0[1-9]|1[0-2])\/(\d{2})$').firstMatch(expiryDate);
  if (match == null) {
    return 'Fecha incorrecta';
  }

  final month = int.parse(match.group(1)!);
  final year = 2000 + int.parse(match.group(2)!);
  final now = DateTime.now();
  if (year < now.year || year == now.year && month < now.month) {
    return 'Fecha incorrecta';
  }

  return null;
}

class ExpiryDateInputFormatter extends TextInputFormatter {
  const ExpiryDateInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (var index = 0; index < digits.length && index < 4; index++) {
      if (index == 2) {
        buffer.write('/');
      }
      buffer.write(digits[index]);
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
