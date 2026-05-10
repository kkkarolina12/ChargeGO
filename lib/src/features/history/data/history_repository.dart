import 'package:chargego/src/core/firebase/firestore_collections.dart';
import 'package:chargego/src/features/rental/domain/rental.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class HistoryRepository {
  Future<List<Rental>> getRentalHistory(String userId);
}

class FirebaseHistoryRepository implements HistoryRepository {
  FirebaseHistoryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _rentals =>
      _firestore.collection(FirestoreCollections.rentals);

  @override
  Future<List<Rental>> getRentalHistory(String userId) async {
    if (userId.isEmpty) return [];

    final snapshot = await _rentals
        .where('id_usuario', isEqualTo: userId)
        .get();
    final rentals =
        snapshot.docs
            .map(
              (doc) => Rental.fromJson({
                ...doc.data(),
                'id_alquiler': doc.data()['id_alquiler'] ?? doc.id,
              }),
            )
            .where((rental) => rental.status != RentalStatus.active)
            .toList()
          ..sort((a, b) => b.startTime.compareTo(a.startTime));

    return rentals;
  }
}

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return FirebaseHistoryRepository();
});

final rentalHistoryProvider = FutureProvider.family<List<Rental>, String>((
  ref,
  userId,
) async {
  final repository = ref.watch(historyRepositoryProvider);
  return repository.getRentalHistory(userId);
});
