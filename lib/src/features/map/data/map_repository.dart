import 'package:chargego/src/core/firebase/firestore_collections.dart';
import 'package:chargego/src/features/map/domain/station.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class MapRepository {
  Future<List<Station>> fetchStations();
  Future<Station> fetchStationById(String id);
}

class FirebaseMapRepository implements MapRepository {
  FirebaseMapRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _stations =>
      _firestore.collection(FirestoreCollections.stations);

  CollectionReference<Map<String, dynamic>> get _batteries =>
      _firestore.collection(FirestoreCollections.batteries);

  @override
  Future<List<Station>> fetchStations() async {
    final snapshot = await _stations.get();
    final stations = await Future.wait(
      snapshot.docs
          .where((doc) => _isStationVisible(doc.data()))
          .map((doc) => _stationFromDocument(doc)),
    );
    stations.sort((a, b) => a.name.compareTo(b.name));
    return stations;
  }

  @override
  Future<Station> fetchStationById(String id) async {
    final snapshot = await _stations.doc(id).get();
    if (!snapshot.exists || snapshot.data() == null) {
      throw Exception('Estacion no encontrada.');
    }
    return _stationFromDocument(snapshot);
  }

  Future<Station> _stationFromDocument(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) async {
    final data = snapshot.data()!;
    final stationId = (data['id_estacion'] ?? snapshot.id) as String;
    final batteries = await _batteries
        .where('id_estacion', isEqualTo: stationId)
        .get();
    final availableCount = batteries.docs
        .where((doc) => _isBatteryAvailable(doc.data()['estado']))
        .length;

    return Station.fromJson({
      ...data,
      'id_estacion': stationId,
      'direccion': _fullAddress(data),
      'disponibles': availableCount,
    });
  }
}

final mapRepositoryProvider = Provider<MapRepository>((ref) {
  return FirebaseMapRepository();
});

final stationsProvider = FutureProvider<List<Station>>((ref) {
  return ref.watch(mapRepositoryProvider).fetchStations();
});

bool _isStationVisible(Map<String, dynamic> data) {
  final status = (data['estado'] ?? 'activa').toString().toLowerCase();
  return !{
    'mantenimiento',
    'mant',
    'fuera_servicio',
    'fuera de servicio',
    'fuera',
    'fueraservicio',
    'inactiva',
    'bloqueada',
  }.contains(status);
}

bool _isBatteryAvailable(dynamic statusValue) {
  final status = (statusValue ?? 'disponible').toString().toLowerCase();
  return {
    'disponible',
    'available',
    'cargada',
    'activo',
    'activa',
  }.contains(status);
}

String _fullAddress(Map<String, dynamic> data) {
  final address = (data['direccion'] ?? data['address'] ?? '').toString();
  final city = (data['ciudad'] ?? '').toString();
  if (city.isEmpty || address.contains(city)) return address;
  return '$address, $city';
}
