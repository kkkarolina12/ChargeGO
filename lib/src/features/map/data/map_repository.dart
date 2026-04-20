import 'package:chargego/src/features/map/domain/station.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class MapRepository {
  Future<List<Station>> fetchStations();
  Future<Station> fetchStationById(String id);
}

class MockMapRepository implements MapRepository {
  final List<Station> _mockStations = [
    const Station(
      id: '1',
      name: 'Central Station',
      latitude: 51.5074,
      longitude: -0.1278,
      address: 'Trafalgar Square, London',
      availableCount: 5,
      totalSlots: 10,
    ),
    const Station(
      id: '2',
      name: 'Southbank Center',
      latitude: 51.5055,
      longitude: -0.1150,
      address: 'Belvedere Rd, London',
      availableCount: 3,
      totalSlots: 8,
    ),
    const Station(
      id: '3',
      name: 'King\'s Cross',
      latitude: 51.5309,
      longitude: -0.1238,
      address: 'Euston Rd, London',
      availableCount: 0,
      totalSlots: 12,
    ),
    const Station(
      id: '4',
      name: 'Victoria Station',
      latitude: 51.4952,
      longitude: -0.1439,
      address: 'Victoria St, London',
      availableCount: 8,
      totalSlots: 15,
    ),
  ];

  @override
  Future<List<Station>> fetchStations() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockStations;
  }

  @override
  Future<Station> fetchStationById(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockStations.firstWhere((s) => s.id == id);
  }
}

final mapRepositoryProvider = Provider<MapRepository>((ref) {
  return MockMapRepository();
});

final stationsProvider = FutureProvider<List<Station>>((ref) {
  return ref.watch(mapRepositoryProvider).fetchStations();
});
