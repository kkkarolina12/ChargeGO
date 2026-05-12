import 'package:cloud_firestore/cloud_firestore.dart';

class RentalRate {
  final String id;
  final String name;
  final double pricePerHour;
  final double? maxDailyPrice;
  final double? missingReturnPenalty;
  final bool active;

  const RentalRate({
    required this.id,
    required this.name,
    required this.pricePerHour,
    this.maxDailyPrice,
    this.missingReturnPenalty,
    required this.active,
  });

  factory RentalRate.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return RentalRate.fromJson({
      ...data,
      'id_tarifa': data['id_tarifa'] ?? snapshot.id,
    });
  }

  factory RentalRate.fromJson(Map<String, dynamic> json) {
    return RentalRate(
      id: (json['id'] ?? json['id_tarifa']) as String,
      name:
          (json['name'] ?? json['nombre_tarifa'] ?? json['nombre'] ?? 'Tarifa')
              as String,
      pricePerHour: _readDouble(
        json['pricePerHour'] ?? json['precio_por_hora'],
      ),
      maxDailyPrice: _readNullableDouble(
        json['maxDailyPrice'] ?? json['precio_max_dia'],
      ),
      missingReturnPenalty: _readNullableDouble(
        json['missingReturnPenalty'] ?? json['penalizacion_no_dev'],
      ),
      active: _readActive(json['active'] ?? json['activa'] ?? json['estado']),
    );
  }
}

double _readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  return 0;
}

double? _readNullableDouble(dynamic value) {
  if (value == null) return null;
  final parsed = _readDouble(value);
  return parsed <= 0 ? null : parsed;
}

bool _readActive(dynamic value) {
  if (value == null) return true;
  if (value is bool) return value;
  final normalized = value.toString().trim().toLowerCase();
  return {'activa', 'activo', 'active', 'true', '1'}.contains(normalized);
}
