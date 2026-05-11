import 'package:chargego/src/core/theme/app_theme.dart';
import 'package:chargego/src/core/widgets/premium_widgets.dart';
import 'package:chargego/src/features/rental/presentation/rental_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ActiveRentalScreen extends ConsumerStatefulWidget {
  const ActiveRentalScreen({super.key, this.powerBankId});

  final String? powerBankId;

  @override
  ConsumerState<ActiveRentalScreen> createState() => _ActiveRentalScreenState();
}

class _ActiveRentalScreenState extends ConsumerState<ActiveRentalScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.powerBankId != null) {
      Future.microtask(() {
        ref
            .read(rentalControllerProvider.notifier)
            .startNewRental(widget.powerBankId!);
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    final twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rentalControllerProvider);
    final rental = state.activeRental;

    return PremiumScaffold(
      appBar: AppBar(
        title: const Text('Alquiler activo'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : rental == null
          ? const EmptyState(
              icon: Icons.battery_unknown_rounded,
              title: 'No hay alquiler activo',
              subtitle: 'Inicia un nuevo alquiler desde la pantalla principal.',
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BrandHeader(
                    title: 'Disfruta tu ChargeGO',
                    subtitle:
                        'Tu alquiler esta activo. Devuelve el powerbank cuando termines.',
                    compact: true,
                    trailing: Icon(
                      Icons.battery_charging_full_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildTimerCard(state.elapsed, state.estimatedPrice),
                  const SizedBox(height: 18),
                  _buildDetailsCard(rental),
                  const Spacer(),
                  GradientButton(
                    label: 'DEVOLVER POWERBANK',
                    icon: Icons.assignment_return_rounded,
                    onPressed: () async {
                      await ref
                          .read(rentalControllerProvider.notifier)
                          .stopRental();
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Alquiler finalizado correctamente.'),
                        ),
                      );
                      context.go('/home');
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTimerCard(Duration elapsed, double price) {
    return PremiumCard(
      gradient: LinearGradient(
        colors: isPremiumDark(context)
            ? const [Color(0xFF111A28), Color(0xFF16243A)]
            : [Colors.white, ChargeGoColors.frost.withValues(alpha: 0.92)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        children: [
          Text(
            'TIEMPO TRANSCURRIDO',
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
              color: premiumMutedColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDuration(elapsed),
            style: TextStyle(
              fontSize: 46,
              fontWeight: FontWeight.w900,
              color: premiumTextColor(context),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: premiumSoftFill(context),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Precio estimado',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: ChargeGoColors.royal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(rental) {
    return PremiumCard(
      child: Column(
        children: [
          _buildDetailRow(
            Icons.location_on_outlined,
            'Estacion de recogida',
            'Estacion central (demo)',
          ),
          const Divider(height: 24),
          _buildDetailRow(
            Icons.vibration,
            'ID del PowerBank',
            rental.powerBankId,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            Icons.access_time_rounded,
            'Hora de inicio',
            DateFormat('HH:mm, dd/MM').format(rental.startTime),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: premiumSoftFill(context),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, size: 21, color: ChargeGoColors.royal),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: premiumMutedColor(context),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
