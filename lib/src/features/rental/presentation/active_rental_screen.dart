import 'package:chargego/src/core/theme/app_theme.dart';
import 'package:chargego/src/core/widgets/premium_widgets.dart';
import 'package:chargego/src/features/rental/domain/rental.dart';
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
  bool _isReturning = false;
  final _returnStationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.powerBankId != null) {
      Future.microtask(() async {
        try {
          await ref
              .read(rentalControllerProvider.notifier)
              .startNewRental(widget.powerBankId!);
        } catch (error) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_cleanError(error))));
          context.go('/home');
        }
      });
    }
  }

  @override
  void dispose() {
    _returnStationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    final twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  Future<void> _returnRental() async {
    final stationCode = _returnStationController.text.trim();
    if (stationCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce el codigo de estacion.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isReturning = true);
    final rentalController = ref.read(rentalControllerProvider.notifier);
    try {
      await rentalController.stopRental(stationCode);
      if (!mounted) {
        rentalController.clearRental();
        return;
      }

      context.go('/history');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        rentalController.clearRental();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isReturning = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_cleanError(error))));
    }
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
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
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
                    const SizedBox(height: 18),
                    _buildReturnStationCard(),
                    const SizedBox(height: 22),
                    GradientButton(
                      label: 'DEVOLVER POWERBANK',
                      icon: Icons.assignment_return_rounded,
                      isLoading: state.isLoading || _isReturning,
                      onPressed: _returnRental,
                    ),
                  ],
                ),
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
                  'Coste estimado',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  _formatMoney(price),
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

  Widget _buildDetailsCard(Rental rental) {
    return PremiumCard(
      child: Column(
        children: [
          _buildDetailRow(
            Icons.location_on_outlined,
            'Estacion de recogida',
            rental.stationStartName ?? rental.stationIdStart,
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
          const Divider(height: 24),
          _buildDetailRow(Icons.sell_outlined, 'Tarifa', _rateLabel(rental)),
        ],
      ),
    );
  }

  Widget _buildReturnStationCard() {
    return PremiumCard(
      child: TextField(
        controller: _returnStationController,
        enabled: !_isReturning,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
          labelText: 'Codigo de estacion de devolucion',
          hintText: 'Ej. estacionprubas',
          prefixIcon: Icon(
            Icons.pin_drop_outlined,
            color: premiumMutedColor(context),
          ),
        ),
        onSubmitted: (_) => _returnRental(),
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

String _formatMoney(double value) => '${value.toStringAsFixed(2)} EUR';

String _rateLabel(Rental rental) {
  final name = rental.rateName ?? 'Tarifa activa';
  final price = rental.pricePerHour;
  if (price == null || price <= 0) return name;
  final maxDay = rental.maxDailyPrice;
  final maxDayLabel = maxDay == null
      ? ''
      : ' - max ${_formatMoney(maxDay)}/dia';
  return '$name - ${_formatMoney(price)}/hora$maxDayLabel';
}

String _cleanError(Object error) {
  final message = error.toString();
  return message.startsWith('Exception: ')
      ? message.substring('Exception: '.length)
      : message;
}
