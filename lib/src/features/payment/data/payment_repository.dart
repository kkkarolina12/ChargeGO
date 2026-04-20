import 'package:chargego/src/features/payment/domain/payment_method.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class PaymentRepository {
  Future<List<PaymentMethod>> getPaymentMethods(String userId);
  Future<void> addPaymentMethod(PaymentMethod paymentMethod);
  Future<void> removePaymentMethod(String paymentMethodId);
  Future<void> setDefaultPaymentMethod(String userId, String paymentMethodId);
}

class MockPaymentRepository implements PaymentRepository {
  final List<PaymentMethod> _mockPaymentMethods = [
    const PaymentMethod(
      id: 'pm_1',
      userId: 'user_1',
      type: PaymentMethodType.creditCard,
      last4: '4242',
      cardBrand: 'Visa',
      expiryDate: '12/26',
      isDefault: true,
    ),
    const PaymentMethod(
      id: 'pm_2',
      userId: 'user_1',
      type: PaymentMethodType.applePay,
      isDefault: false,
    ),
  ];

  @override
  Future<List<PaymentMethod>> getPaymentMethods(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockPaymentMethods.where((pm) => pm.userId == userId).toList();
  }

  @override
  Future<void> addPaymentMethod(PaymentMethod paymentMethod) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockPaymentMethods.add(paymentMethod);
  }

  @override
  Future<void> removePaymentMethod(String paymentMethodId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockPaymentMethods.removeWhere((pm) => pm.id == paymentMethodId);
  }

  @override
  Future<void> setDefaultPaymentMethod(String userId, String paymentMethodId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    for (var i = 0; i < _mockPaymentMethods.length; i++) {
      if (_mockPaymentMethods[i].userId == userId) {
        _mockPaymentMethods[i] = _mockPaymentMethods[i].copyWith(
          isDefault: _mockPaymentMethods[i].id == paymentMethodId,
        );
      }
    }
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return MockPaymentRepository();
});

final paymentMethodsProvider = FutureProvider.family<List<PaymentMethod>, String>((ref, userId) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.getPaymentMethods(userId);
});
