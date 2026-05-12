import 'package:chargego/src/core/theme/app_theme.dart';
import 'package:chargego/src/core/widgets/premium_widgets.dart';
import 'package:chargego/src/features/map/data/map_repository.dart';
import 'package:chargego/src/features/map/domain/station.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  static const LatLng _fallbackPosition = LatLng(41.6176, 0.62);

  final _mapController = MapController();
  LatLng? _currentPosition;
  List<Station> _stationsWithLocation = const [];
  String _stationSignature = '';
  bool _mapReady = false;
  bool _canUseLocation = false;
  bool _isLoadingLocation = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
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
      _moveCameraToBestView();
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

  void _onMapReady() {
    _mapReady = true;
    _moveCameraToBestView();
  }

  void _moveCameraToBestView() {
    if (!_mapReady) return;

    final stations = _stationsWithLocation;
    if (stations.isNotEmpty) {
      _mapController.move(_centerFor(stations), stations.length == 1 ? 15 : 13);
      return;
    }

    _mapController.move(
      _currentPosition ?? _fallbackPosition,
      _currentPosition == null ? 13 : 15,
    );
  }

  void _moveCameraToCurrentLocation() {
    final position = _currentPosition;
    if (!_mapReady || position == null) return;
    _mapController.move(position, 15);
  }

  void _syncStations(List<Station> stations) {
    final signature = stations
        .map(
          (station) => '${station.id}:${station.latitude}:${station.longitude}',
        )
        .join('|');
    if (signature == _stationSignature) return;

    _stationSignature = signature;
    _stationsWithLocation = stations;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _moveCameraToBestView();
    });
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
          final stationsWithLocation = stations.where(_hasCoordinates).toList();
          _syncStations(stationsWithLocation);

          final initialTarget = stationsWithLocation.isNotEmpty
              ? _centerFor(stationsWithLocation)
              : _currentPosition ?? _fallbackPosition;

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: initialTarget,
                  initialZoom: stationsWithLocation.length == 1 ? 15 : 13,
                  minZoom: 4,
                  maxZoom: 18,
                  onMapReady: _onMapReady,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.chargego',
                  ),
                  MarkerLayer(
                    markers: [
                      if (_currentPosition != null)
                        Marker(
                          point: _currentPosition!,
                          width: 34,
                          height: 34,
                          child: const _CurrentLocationMarker(),
                        ),
                      ...stationsWithLocation.map(
                        (station) => Marker(
                          point: LatLng(station.latitude, station.longitude),
                          width: 58,
                          height: 58,
                          child: _StationMarker(
                            station: station,
                            onTap: () => _showStationDetails(station),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
                          _stationCountLabel(stations.length),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(
                left: 10,
                bottom: 10,
                child: _OpenStreetMapAttribution(),
              ),
              if (_canUseLocation)
                Positioned(
                  right: 16,
                  bottom: _locationError == null ? 24 : 92,
                  child: FloatingActionButton.small(
                    heroTag: 'center-location',
                    tooltip: 'Mi ubicacion',
                    onPressed: _moveCameraToCurrentLocation,
                    child: const Icon(Icons.my_location_rounded),
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

  String _stationCountLabel(int count) {
    final unit = count == 1 ? 'estacion' : 'estaciones';
    return '$count $unit ChargeGO en Lleida';
  }
}

LatLng _centerFor(List<Station> stations) {
  if (stations.isEmpty) return _MapScreenState._fallbackPosition;

  var latitude = 0.0;
  var longitude = 0.0;
  for (final station in stations) {
    latitude += station.latitude;
    longitude += station.longitude;
  }

  return LatLng(latitude / stations.length, longitude / stations.length);
}

bool _hasCoordinates(Station station) {
  final hasValidLatitude = station.latitude >= -90 && station.latitude <= 90;
  final hasValidLongitude =
      station.longitude >= -180 && station.longitude <= 180;
  final isEmptyCoordinate = station.latitude == 0 && station.longitude == 0;
  return hasValidLatitude && hasValidLongitude && !isEmptyCoordinate;
}

class _StationMarker extends StatelessWidget {
  const _StationMarker({required this.station, required this.onTap});

  final Station station;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final available = station.availableCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: available ? ChargeGoColors.royal : ChargeGoColors.danger,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: ChargeGoColors.navy.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.ev_station_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

class _CurrentLocationMarker extends StatelessWidget {
  const _CurrentLocationMarker();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ChargeGoColors.electric.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: ChargeGoColors.electric,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
        ),
      ),
    );
  }
}

class _OpenStreetMapAttribution extends StatelessWidget {
  const _OpenStreetMapAttribution();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          '© OpenStreetMap',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
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
                label: 'Alquilar en esta estacion',
                icon: Icons.lock_open_rounded,
                onPressed: available
                    ? () {
                        context.pop();
                        context.push('/active-rental', extra: station.id);
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
