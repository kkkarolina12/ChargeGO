import 'package:chargego/src/core/theme/app_theme.dart';
import 'package:chargego/src/core/widgets/premium_widgets.dart';
import 'package:chargego/src/features/auth/data/auth_repository.dart';
import 'package:chargego/src/features/history/data/history_repository.dart';
import 'package:chargego/src/features/rental/domain/rental.dart';
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
                  final minutes = _rentalMinutes(rental);
                  return PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: ChargeGoColors.sky.withValues(
                                  alpha: 0.22,
                                ),
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
                                    'Bateria ${rental.powerBankId}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$minutes min · ${rental.rateName ?? 'Tarifa aplicada'}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: premiumMutedColor(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatMoney(rental.totalCost),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: ChargeGoColors.royal,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: premiumSoftFill(context),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              _HistoryLine(
                                icon: Icons.login_rounded,
                                label: 'Alquiler',
                                station:
                                    rental.stationStartName ??
                                    rental.stationIdStart,
                                date: rental.startTime,
                              ),
                              if (rental.endTime != null) ...[
                                const SizedBox(height: 10),
                                _HistoryLine(
                                  icon: Icons.assignment_return_rounded,
                                  label: 'Devolucion',
                                  station:
                                      rental.stationEndName ??
                                      rental.stationIdEnd ??
                                      'Sin estacion',
                                  date: rental.endTime!,
                                ),
                              ],
                            ],
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

class _HistoryLine extends StatelessWidget {
  const _HistoryLine({
    required this.icon,
    required this.label,
    required this.station,
    required this.date,
  });

  final IconData icon;
  final String label;
  final String station;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: ChargeGoColors.royal),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label · $station',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                DateFormat('dd/MM/yyyy HH:mm').format(date),
                style: TextStyle(
                  color: premiumMutedColor(context),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

int _rentalMinutes(Rental rental) {
  final endTime = rental.endTime;
  if (endTime == null) return 0;
  return endTime.difference(rental.startTime).inMinutes.clamp(1, 999999);
}

String _formatMoney(double value) => '${value.toStringAsFixed(2)} EUR';
