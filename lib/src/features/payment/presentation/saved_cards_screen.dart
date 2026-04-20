import 'package:chargego/src/features/auth/data/auth_repository.dart';
import 'package:chargego/src/features/payment/data/payment_repository.dart';
import 'package:chargego/src/features/payment/domain/payment_method.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SavedCardsScreen extends ConsumerWidget {
  const SavedCardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider(user?.id ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Cards'),
      ),
      body: paymentMethodsAsync.when(
        data: (methods) => methods.isEmpty
            ? const Center(child: Text('No saved cards'))
            : ListView.builder(
                itemCount: methods.length,
                itemBuilder: (context, index) {
                  final method = methods[index];
                  return ListTile(
                    leading: Icon(
                      method.type == PaymentMethodType.creditCard
                          ? Icons.credit_card
                          : Icons.account_balance_wallet,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: Text(
                      method.type == PaymentMethodType.creditCard
                          ? '${method.cardBrand} **** ${method.last4}'
                          : method.type.name.toUpperCase(),
                    ),
                    subtitle: method.expiryDate != null ? Text('Expires: ${method.expiryDate}') : null,
                    trailing: method.isDefault
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () {
                      if (!method.isDefault && user != null) {
                        ref.read(paymentRepositoryProvider).setDefaultPaymentMethod(user.id, method.id);
                        ref.invalidate(paymentMethodsProvider(user.id));
                      }
                    },
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-card'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
