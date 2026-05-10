import 'package:chargego/src/core/firebase/firestore_collections.dart';
import 'package:chargego/src/features/rental/domain/rental.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class RentalRepository {
  Future<Rental?> getActiveRental(String userId);

  Future<Rental> startRental({
    required String userId,
    required String powerBankId,
    required String stationIdStart,
  });

  Future<void> endRental(
    String rentalId,
    String stationIdEnd, {
    required double totalCost,
  });
}

class FirebaseRentalRepository implements RentalRepository {
  FirebaseRentalRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _rentals =>
      _firestore.collection(FirestoreCollections.rentals);

  CollectionReference<Map<String, dynamic>> get _batteries =>
      _firestore.collection(FirestoreCollections.batteries);

  @override
  Future<Rental?> getActiveRental(String userId) async {
    if (userId.isEmpty) return null;

    final snapshot = await _rentals
        .where('id_usuario', isEqualTo: userId)
        .where('estado', isEqualTo: 'activo')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return Rental.fromJson({
      ...snapshot.docs.first.data(),
      'id_alquiler':
          snapshot.docs.first.data()['id_alquiler'] ?? snapshot.docs.first.id,
    });
  }

  @override
  Future<Rental> startRental({
    required String userId,
    required String powerBankId,
    required String stationIdStart,
  }) async {
    final rentalDoc = _rentals.doc();
    var rental = Rental(
      id: rentalDoc.id,
      userId: userId,
      powerBankId: powerBankId,
      stationIdStart: stationIdStart,
      startTime: DateTime.now(),
      status: RentalStatus.active,
    );

    await _firestore.runTransaction((transaction) async {
      final batteryRef = _batteries.doc(powerBankId);
      final batterySnapshot = await transaction.get(batteryRef);
      final batteryStationId =
          batterySnapshot.data()?['id_estacion'] as String?;
      rental = rental.copyWith(
        stationIdStart: batteryStationId ?? stationIdStart,
      );

      transaction.set(rentalDoc, rental.toFirestoreSchema());
      if (batterySnapshot.exists) {
        transaction.update(batteryRef, {
          'estado': 'en_uso',
          'id_estacion': null,
        });
      }
    });

    return rental;
  }

  @override
  Future<void> endRental(
    String rentalId,
    String stationIdEnd, {
    required double totalCost,
  }) async {
    final rentalRef = _rentals.doc(rentalId);

    await _firestore.runTransaction((transaction) async {
      final rentalSnapshot = await transaction.get(rentalRef);
      if (!rentalSnapshot.exists || rentalSnapshot.data() == null) {
        throw Exception('Alquiler no encontrado.');
      }

      final rental = Rental.fromJson({
        ...rentalSnapshot.data()!,
        'id_alquiler':
            rentalSnapshot.data()!['id_alquiler'] ?? rentalSnapshot.id,
      });
      final batteryRef = _batteries.doc(rental.powerBankId);
      final batterySnapshot = await transaction.get(batteryRef);

      transaction.update(rentalRef, {
        'id_estacion_devolucion': stationIdEnd,
        'fecha_fin': Timestamp.fromDate(DateTime.now()),
        'estado': 'finalizado',
        'coste_total': totalCost,
      });

      if (batterySnapshot.exists) {
        transaction.update(batteryRef, {
          'estado': 'disponible',
          'id_estacion': stationIdEnd,
        });
      }
    });
  }
}

final rentalRepositoryProvider = Provider<RentalRepository>((ref) {
  return FirebaseRentalRepository();
});
