import 'package:chargego/src/core/theme/app_theme.dart';
import 'package:chargego/src/core/widgets/premium_widgets.dart';
import 'package:chargego/src/features/map/data/map_repository.dart';
import 'package:chargego/src/features/map/domain/station.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final LatLng _initialPosition = const LatLng(51.5074, -0.1278);

  void _onMapCreated(GoogleMapController controller) {}

  void _showStationDetails(Station station) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StationDetailsSheet(station: station);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stationsAsyncValue = ref.watch(stationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Station'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: stationsAsyncValue.when(
        data: (stations) {
          final markers = stations.map((station) {
            return Marker(
              markerId: MarkerId(station.id),
              position: LatLng(station.latitude, station.longitude),
              infoWindow: InfoWindow(
                title: station.name,
                snippet: '${station.availableCount} available',
              ),
              onTap: () => _showStationDetails(station),
            );
          }).toSet();

          return Stack(
            children: [
              GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _initialPosition,
                  zoom: 13,
                ),
                markers: markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: PremiumCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.near_me_rounded,
                        color: ChargeGoColors.royal,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${stations.length} ChargeGO stations nearby',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class StationDetailsSheet extends StatelessWidget {
  const StationDetailsSheet({super.key, required this.station});

  final Station station;

  @override
  Widget build(BuildContext context) {
    final available = station.availableCount > 0;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: PremiumCard(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: ChargeGoColors.sky.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        station.address,
                        style: const TextStyle(color: ChargeGoColors.muted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (available
                                ? ChargeGoColors.success
                                : ChargeGoColors.danger)
                            .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    available ? 'Available' : 'Empty',
                    style: TextStyle(
                      color: available
                          ? ChargeGoColors.success
                          : ChargeGoColors.danger,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    icon: Icons.battery_charging_full_rounded,
                    label: 'Available',
                    value: station.availableCount.toString(),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _InfoItem(
                    icon: Icons.power_rounded,
                    label: 'Total Slots',
                    value: station.totalSlots.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                label: 'Unlock Powerbank',
                icon: Icons.lock_open_rounded,
                onPressed: available
                    ? () {
                        context.pop();
                        context.push('/qr-scan');
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChargeGoColors.frost.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: ChargeGoColors.royal, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: const TextStyle(color: ChargeGoColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
