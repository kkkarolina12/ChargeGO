import 'package:chargego/src/features/auth/data/auth_repository.dart';
import 'package:chargego/src/features/payment/data/payment_repository.dart';
import 'package:chargego/src/features/payment/domain/payment_method.dart';
import 'package:chargego/src/features/rental/presentation/rental_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SavedCardsScreen extends ConsumerWidget {
  const SavedCardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final paymentMethodsAsync = ref.watch(
      paymentMethodsProvider(user?.id ?? ''),
    );
    final hasActiveRental =
        ref.watch(rentalControllerProvider).activeRental != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Cards')),
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
                    title: Text(_paymentMethodTitle(method)),
                    subtitle: Text(_paymentMethodSubtitle(method)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (method.isDefault)
                          const Icon(Icons.check_circle, color: Colors.green),
                        IconButton(
                          tooltip: 'Eliminar tarjeta',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: user == null
                              ? null
                              : () => _removePaymentMethod(
                                  context,
                                  ref,
                                  user.id,
                                  method.id,
                                  hasActiveRental,
                                ),
                        ),
                      ],
                    ),
                    onTap: () {
                      if (!method.isDefault && user != null) {
                        ref
                            .read(paymentRepositoryProvider)
                            .setDefaultPaymentMethod(user.id, method.id);
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

String _paymentMethodTitle(PaymentMethod method) {
  if (method.type != PaymentMethodType.creditCard) {
    return method.type.name.toUpperCase();
  }

  final displayName = method.displayName?.trim();
  if (displayName != null && displayName.isNotEmpty) {
    return displayName;
  }

  final holderName = method.holderName?.trim();
  if (holderName != null && holderName.isNotEmpty) {
    return holderName;
  }

  return '${method.cardBrand ?? 'Tarjeta'} **** ${method.last4 ?? ''}';
}

String _paymentMethodSubtitle(PaymentMethod method) {
  if (method.type != PaymentMethodType.creditCard) {
    return method.isDefault
        ? 'Predeterminado'
        : 'Toca para marcar como predeterminado';
  }

  final cardDescription =
      '${method.cardBrand ?? 'Tarjeta'} **** ${method.last4 ?? ''}';
  final expiryDate = method.expiryDate;
  if (expiryDate == null || expiryDate.isEmpty) {
    return cardDescription;
  }
  return '$cardDescription - Vence: $expiryDate';
}

Future<void> _removePaymentMethod(
  BuildContext context,
  WidgetRef ref,
  String userId,
  String paymentMethodId,
  bool hasActiveRental,
) async {
  if (hasActiveRental) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No puedes eliminar una tarjeta mientras tienes una bateria alquilada.',
        ),
      ),
    );
    return;
  }

  try {
    await ref
        .read(paymentRepositoryProvider)
        .removePaymentMethod(userId, paymentMethodId);
    ref.invalidate(paymentMethodsProvider(userId));
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.toString())));
  }
}
