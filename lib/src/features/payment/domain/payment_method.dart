enum PaymentMethodType {
  creditCard,
  applePay,
  googlePay,
  paypal,
}

class PaymentMethod {
  final String id;
  final String userId;
  final PaymentMethodType type;
  final String? last4;
  final String? cardBrand;
  final String? expiryDate;
  final bool isDefault;

  const PaymentMethod({
    required this.id,
    required this.userId,
    required this.type,
    this.last4,
    this.cardBrand,
    this.expiryDate,
    this.isDefault = false,
  });

  PaymentMethod copyWith({
    String? id,
    String? userId,
    PaymentMethodType? type,
    String? last4,
    String? cardBrand,
    String? expiryDate,
    bool? isDefault,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      last4: last4 ?? this.last4,
      cardBrand: cardBrand ?? this.cardBrand,
      expiryDate: expiryDate ?? this.expiryDate,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
