import 'package:cloud_firestore/cloud_firestore.dart';

enum RentalStatus { active, completed, cancelled }

class Rental {
  final String id;
  final String userId;
  final String powerBankId;
  final String stationIdStart;
  final String? stationIdEnd;
  final String? stationStartName;
  final String? stationEndName;
  final String? rateId;
  final String? rateName;
  final double? pricePerHour;
  final double? maxDailyPrice;
  final double? missingReturnPenalty;
  final DateTime startTime;
  final DateTime? endTime;
  final double totalCost;
  final RentalStatus status;

  const Rental({
    required this.id,
    required this.userId,
    required this.powerBankId,
    required this.stationIdStart,
    this.stationIdEnd,
    this.stationStartName,
    this.stationEndName,
    this.rateId,
    this.rateName,
    this.pricePerHour,
    this.maxDailyPrice,
    this.missingReturnPenalty,
    required this.startTime,
    this.endTime,
    this.totalCost = 0.0,
    required this.status,
  });

  factory Rental.fromJson(Map<String, dynamic> json) {
    return Rental(
      id: (json['id'] ?? json['id_alquiler']) as String,
      userId: (json['userId'] ?? json['id_usuario']) as String,
      powerBankId: (json['powerBankId'] ?? json['id_bateria']) as String,
      stationIdStart:
          (json['stationIdStart'] ?? json['id_estacion_salida']) as String,
      stationIdEnd:
          (json['stationIdEnd'] ?? json['id_estacion_devolucion']) as String?,
      stationStartName:
          (json['stationStartName'] ?? json['nombre_estacion_salida'])
              as String?,
      stationEndName:
          (json['stationEndName'] ?? json['nombre_estacion_devolucion'])
              as String?,
      rateId: (json['rateId'] ?? json['id_tarifa']) as String?,
      rateName: (json['rateName'] ?? json['nombre_tarifa']) as String?,
      pricePerHour: _readNullableDouble(
        json['pricePerHour'] ?? json['precio_por_hora'],
      ),
      maxDailyPrice: _readNullableDouble(
        json['maxDailyPrice'] ?? json['precio_max_dia'],
      ),
      missingReturnPenalty: _readNullableDouble(
        json['missingReturnPenalty'] ?? json['penalizacion_no_dev'],
      ),
      startTime:
          _readDateTime(json['startTime'] ?? json['fecha_inicio']) ??
          DateTime.now(),
      endTime: _readDateTime(json['endTime'] ?? json['fecha_fin']),
      totalCost: ((json['totalCost'] ?? json['coste_total'] ?? 0) as num)
          .toDouble(),
      status: _rentalStatusFromString(
        (json['status'] ?? json['estado']) as String?,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'powerBankId': powerBankId,
      'stationIdStart': stationIdStart,
      'stationIdEnd': stationIdEnd,
      'stationStartName': stationStartName,
      'stationEndName': stationEndName,
      'rateId': rateId,
      'rateName': rateName,
      'pricePerHour': pricePerHour,
      'maxDailyPrice': maxDailyPrice,
      'missingReturnPenalty': missingReturnPenalty,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'totalCost': totalCost,
      'status': status.name,
    };
  }

  Map<String, dynamic> toFirestoreSchema() {
    return {
      'id_alquiler': id,
      'id_usuario': userId,
      'id_bateria': powerBankId,
      'id_estacion_salida': stationIdStart,
      'id_estacion_devolucion': stationIdEnd,
      'nombre_estacion_salida': stationStartName,
      'nombre_estacion_devolucion': stationEndName,
      'id_tarifa': rateId,
      'nombre_tarifa': rateName,
      'precio_por_hora': pricePerHour,
      'precio_max_dia': maxDailyPrice,
      'penalizacion_no_dev': missingReturnPenalty,
      'fecha_inicio': Timestamp.fromDate(startTime),
      'fecha_fin': endTime == null ? null : Timestamp.fromDate(endTime!),
      'coste_total': totalCost,
      'estado': _rentalStatusToString(status),
    };
  }

  Rental copyWith({
    String? id,
    String? userId,
    String? powerBankId,
    String? stationIdStart,
    String? stationIdEnd,
    String? stationStartName,
    String? stationEndName,
    String? rateId,
    String? rateName,
    double? pricePerHour,
    double? maxDailyPrice,
    double? missingReturnPenalty,
    DateTime? startTime,
    DateTime? endTime,
    double? totalCost,
    RentalStatus? status,
  }) {
    return Rental(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      powerBankId: powerBankId ?? this.powerBankId,
      stationIdStart: stationIdStart ?? this.stationIdStart,
      stationIdEnd: stationIdEnd ?? this.stationIdEnd,
      stationStartName: stationStartName ?? this.stationStartName,
      stationEndName: stationEndName ?? this.stationEndName,
      rateId: rateId ?? this.rateId,
      rateName: rateName ?? this.rateName,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      maxDailyPrice: maxDailyPrice ?? this.maxDailyPrice,
      missingReturnPenalty: missingReturnPenalty ?? this.missingReturnPenalty,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalCost: totalCost ?? this.totalCost,
      status: status ?? this.status,
    );
  }
}

DateTime? _readDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

double? _readNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.replaceAll(',', '.'));
  return null;
}

RentalStatus _rentalStatusFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'finalizado':
    case 'completado':
    case 'completed':
      return RentalStatus.completed;
    case 'cancelado':
    case 'cancelled':
      return RentalStatus.cancelled;
    case 'activo':
    case 'act':
    case 'active':
    default:
      return RentalStatus.active;
  }
}

String _rentalStatusToString(RentalStatus status) {
  switch (status) {
    case RentalStatus.completed:
      return 'finalizado';
    case RentalStatus.cancelled:
      return 'cancelado';
    case RentalStatus.active:
      return 'activo';
  }
}
