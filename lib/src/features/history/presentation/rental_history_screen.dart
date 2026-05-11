import 'package:chargego/src/core/theme/app_theme.dart';
import 'package:chargego/src/core/widgets/premium_widgets.dart';
import 'package:chargego/src/features/auth/data/auth_repository.dart';
import 'package:chargego/src/features/history/data/history_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class RentalHistoryScreen extends ConsumerWidget {
  const RentalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final historyAsync = ref.watch(rentalHistoryProvider(user?.id ?? ''));

    return PremiumScaffold(
      appBar: AppBar(title: const Text('Historial de alquileres')),
      body: historyAsync.when(
        data: (rentals) => rentals.isEmpty
            ? const EmptyState(
                icon: Icons.history_rounded,
                title: 'No hay historial',
                subtitle: 'Tus alquileres finalizados apareceran aqui.',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                itemCount: rentals.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final rental = rentals[index];
                  final minutes =
                      rental.endTime?.difference(rental.startTime).inMinutes ??
                      0;
                  return PremiumCard(
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: ChargeGoColors.sky.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.battery_charging_full_rounded,
                            color: ChargeGoColors.royal,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Alquiler #${rental.id}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat(
                                  'dd/MM/yyyy HH:mm',
                                ).format(rental.startTime),
                                style: TextStyle(
                                  color: premiumMutedColor(context),
                                ),
                              ),
                              Text(
                                '$minutes min',
                                style: TextStyle(
                                  color: premiumMutedColor(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '\$${rental.totalCost.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: ChargeGoColors.royal,
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
    );
  }
}
