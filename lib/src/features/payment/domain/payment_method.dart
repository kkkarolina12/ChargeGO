enum PaymentMethodType { creditCard, applePay, googlePay, paypal }

class PaymentMethod {
  final String id;
  final String userId;
  final PaymentMethodType type;
  final String? last4;
  final String? cardBrand;
  final String? expiryDate;
  final String? holderName;
  final bool isDefault;

  const PaymentMethod({
    required this.id,
    required this.userId,
    required this.type,
    this.last4,
    this.cardBrand,
    this.expiryDate,
    this.holderName,
    this.isDefault = false,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: (json['id'] ?? json['id_metodo_pago']) as String,
      userId: (json['userId'] ?? json['id_usuario']) as String,
      type: _paymentMethodTypeFromString(
        (json['type'] ?? json['tipo']) as String?,
      ),
      last4: (json['last4'] ?? json['ultimos_4']) as String?,
      cardBrand: (json['cardBrand'] ?? json['marca_tarjeta']) as String?,
      expiryDate: (json['expiryDate'] ?? json['fecha_expiracion']) as String?,
      holderName: (json['holderName'] ?? json['titular']) as String?,
      isDefault: (json['isDefault'] ?? json['predeterminado'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toFirestoreSchema() {
    return {
      'id_metodo_pago': id,
      'id_usuario': userId,
      'tipo': _paymentMethodTypeToString(type),
      'token_pago': null,
      'ultimos_4': last4,
      'titular': holderName,
      'predeterminado': isDefault,
      'fecha_expiracion': expiryDate,
    };
  }

  PaymentMethod copyWith({
    String? id,
    String? userId,
    PaymentMethodType? type,
    String? last4,
    String? cardBrand,
    String? expiryDate,
    String? holderName,
    bool? isDefault,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      last4: last4 ?? this.last4,
      cardBrand: cardBrand ?? this.cardBrand,
      expiryDate: expiryDate ?? this.expiryDate,
      holderName: holderName ?? this.holderName,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

PaymentMethodType _paymentMethodTypeFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'apple_pay':
    case 'applepay':
      return PaymentMethodType.applePay;
    case 'google_pay':
    case 'googlepay':
      return PaymentMethodType.googlePay;
    case 'paypal':
      return PaymentMethodType.paypal;
    case 'tarjeta':
    case 'credit_card':
    default:
      return PaymentMethodType.creditCard;
  }
}

String _paymentMethodTypeToString(PaymentMethodType type) {
  switch (type) {
    case PaymentMethodType.applePay:
      return 'apple_pay';
    case PaymentMethodType.googlePay:
      return 'google_pay';
    case PaymentMethodType.paypal:
      return 'paypal';
    case PaymentMethodType.creditCard:
      return 'tarjeta';
  }
}
