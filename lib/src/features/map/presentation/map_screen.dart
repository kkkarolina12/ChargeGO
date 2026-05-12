import 'package:chargego/src/core/theme/app_theme.dart';
import 'package:chargego/src/core/widgets/premium_widgets.dart';
import 'package:chargego/src/features/map/data/map_repository.dart';
import 'package:chargego/src/features/map/domain/station.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  static const LatLng _fallbackPosition = LatLng(41.6176, 0.62);

  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  bool _canUseLocation = false;
  bool _isLoadingLocation = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _moveCameraToCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setLocationUnavailable('Activa la ubicacion del dispositivo.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _setLocationUnavailable('Permiso de ubicacion denegado.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _setLocationUnavailable(
          'Permiso bloqueado. Activalo desde los ajustes del sistema.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _canUseLocation = true;
        _isLoadingLocation = false;
      });
      _moveCameraToCurrentLocation();
    } catch (_) {
      _setLocationUnavailable('No se pudo obtener tu ubicacion.');
    }
  }

  void _setLocationUnavailable(String message) {
    if (!mounted) return;
    setState(() {
      _canUseLocation = false;
      _isLoadingLocation = false;
      _locationError = message;
    });
  }

  Future<void> _moveCameraToCurrentLocation() async {
    final position = _currentPosition;
    final controller = _mapController;
    if (position == null || controller == null) return;

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: 15),
      ),
    );
  }

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
        title: const Text('Buscar estacion'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: stationsAsyncValue.when(
        data: (stations) {
          final markers = stations
              .where(
                (station) => station.latitude != 0 || station.longitude != 0,
              )
              .map((station) {
                return Marker(
                  markerId: MarkerId(station.id),
                  position: LatLng(station.latitude, station.longitude),
                  infoWindow: InfoWindow(
                    title: station.name,
                    snippet: '${station.availableCount} disponibles',
                  ),
                  onTap: () => _showStationDetails(station),
                );
              })
              .toSet();

          return Stack(
            children: [
              GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _currentPosition ?? _fallbackPosition,
                  zoom: _currentPosition == null ? 13 : 15,
                ),
                markers: markers,
                myLocationEnabled: _canUseLocation,
                myLocationButtonEnabled: _canUseLocation,
                zoomControlsEnabled: false,
              ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: PremiumCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _canUseLocation
                            ? Icons.near_me_rounded
                            : Icons.location_on_rounded,
                        color: ChargeGoColors.royal,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _canUseLocation
                              ? '${stations.length} estaciones ChargeGO cerca'
                              : '${stations.length} estaciones ChargeGO en Lleida',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isLoadingLocation)
                const Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: _MapStatusBanner(
                    icon: Icons.my_location_rounded,
                    message: 'Buscando tu ubicacion...',
                  ),
                ),
              if (_locationError != null)
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: _MapStatusBanner(
                    icon: Icons.location_off_rounded,
                    message: _locationError!,
                    actionLabel: 'Reintentar',
                    onActionPressed: _loadCurrentLocation,
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
                        style: TextStyle(color: premiumMutedColor(context)),
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
                    available ? 'Disponible' : 'Vacia',
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
                    label: 'Disponibles',
                    value: station.availableCount.toString(),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _InfoItem(
                    icon: Icons.power_rounded,
                    label: 'Espacios',
                    value: station.totalSlots.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                label: 'Desbloquear PowerBank',
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

class _MapStatusBanner extends StatelessWidget {
  const _MapStatusBanner({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onActionPressed,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: ChargeGoColors.royal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (actionLabel != null && onActionPressed != null)
            TextButton(onPressed: onActionPressed, child: Text(actionLabel!)),
        ],
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
        color: premiumSoftFill(context),
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
            style: TextStyle(color: premiumMutedColor(context), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
