import 'package:chargego/src/core/firebase/firestore_collections.dart';
import 'package:chargego/src/features/payment/domain/payment_method.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class PaymentRepository {
  Future<List<PaymentMethod>> getPaymentMethods(String userId);
  Future<void> addPaymentMethod(PaymentMethod paymentMethod);
  Future<void> removePaymentMethod(String paymentMethodId);
  Future<void> setDefaultPaymentMethod(String userId, String paymentMethodId);
}

class FirebasePaymentRepository implements PaymentRepository {
  FirebasePaymentRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _paymentMethods =>
      _firestore.collection(FirestoreCollections.paymentMethods);

  @override
  Future<List<PaymentMethod>> getPaymentMethods(String userId) async {
    if (userId.isEmpty) return [];

    final snapshot = await _paymentMethods
        .where('id_usuario', isEqualTo: userId)
        .get();
    final methods = snapshot.docs
        .map(
          (doc) => PaymentMethod.fromJson({
            ...doc.data(),
            'id_metodo_pago': doc.data()['id_metodo_pago'] ?? doc.id,
          }),
        )
        .toList();
    methods.sort((a, b) {
      if (a.isDefault == b.isDefault) return a.id.compareTo(b.id);
      return a.isDefault ? -1 : 1;
    });
    return methods;
  }

  @override
  Future<void> addPaymentMethod(PaymentMethod paymentMethod) async {
    final doc = paymentMethod.id.isEmpty
        ? _paymentMethods.doc()
        : _paymentMethods.doc(paymentMethod.id);

    await doc.set({
      ...paymentMethod.copyWith(id: doc.id).toFirestoreSchema(),
      'fecha_creacion': FieldValue.serverTimestamp(),
    });

    if (paymentMethod.isDefault) {
      await setDefaultPaymentMethod(paymentMethod.userId, doc.id);
    }
  }

  @override
  Future<void> removePaymentMethod(String paymentMethodId) {
    return _paymentMethods.doc(paymentMethodId).delete();
  }

  @override
  Future<void> setDefaultPaymentMethod(
    String userId,
    String paymentMethodId,
  ) async {
    final snapshot = await _paymentMethods
        .where('id_usuario', isEqualTo: userId)
        .get();
    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      final methodId = (doc.data()['id_metodo_pago'] ?? doc.id) as String;
      batch.update(doc.reference, {
        'predeterminado':
            methodId == paymentMethodId || doc.id == paymentMethodId,
      });
    }

    await batch.commit();
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return FirebasePaymentRepository();
});

final paymentMethodsProvider =
    FutureProvider.family<List<PaymentMethod>, String>((ref, userId) async {
      final repository = ref.watch(paymentRepositoryProvider);
      return repository.getPaymentMethods(userId);
    });
