import 'package:chargego/src/features/auth/data/auth_repository.dart';
import 'package:chargego/src/features/payment/data/payment_repository.dart';
import 'package:chargego/src/features/payment/domain/payment_method.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

      final newCard = PaymentMethod(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.id,
        type: PaymentMethodType.creditCard,
        last4: _cardNumberController.text.substring(_cardNumberController.text.length - 4),
        cardBrand: 'Visa', // Hardcoded for mock
        expiryDate: _expiryDateController.text,
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
      appBar: AppBar(
        title: const Text('Add Card'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _cardHolderController,
                decoration: const InputDecoration(labelText: 'Card Holder Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cardNumberController,
                decoration: const InputDecoration(labelText: 'Card Number'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.length < 16 ? 'Invalid card number' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryDateController,
                      decoration: const InputDecoration(labelText: 'Expiry Date (MM/YY)'),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      decoration: const InputDecoration(labelText: 'CVV'),
                      obscureText: true,
                      validator: (value) => value!.length < 3 ? 'Invalid CVV' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Save Card'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
