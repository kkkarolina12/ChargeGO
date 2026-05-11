import 'package:chargego/src/core/theme/app_theme.dart';
import 'package:chargego/src/core/widgets/premium_widgets.dart';
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

    return PremiumScaffold(
      appBar: AppBar(title: const Text('Saved Cards')),
      body: paymentMethodsAsync.when(
        data: (methods) => methods.isEmpty
            ? const EmptyState(
                icon: Icons.credit_card_off_rounded,
                title: 'No saved cards',
                subtitle: 'Add a card to rent power banks faster.',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                itemCount: methods.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final method = methods[index];
                  return PremiumCard(
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                ChargeGoColors.royal,
                                ChargeGoColors.electric,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            method.type == PaymentMethodType.creditCard
                                ? Icons.credit_card_rounded
                                : Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              if (!method.isDefault && user != null) {
                                ref
                                    .read(paymentRepositoryProvider)
                                    .setDefaultPaymentMethod(
                                      user.id,
                                      method.id,
                                    );
                                ref.invalidate(paymentMethodsProvider(user.id));
                              }
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _paymentMethodTitle(method),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _paymentMethodSubtitle(method),
                                  style: const TextStyle(
                                    color: ChargeGoColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (method.isDefault)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: ChargeGoColors.success,
                          ),
                        IconButton(
                          tooltip: 'Eliminar tarjeta',
                          icon: const Icon(Icons.delete_outline_rounded),
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
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-card'),
        icon: const Icon(Icons.add_card_rounded),
        label: const Text('Add Card'),
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
