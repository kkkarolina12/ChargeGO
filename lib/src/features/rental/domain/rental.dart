import 'package:cloud_firestore/cloud_firestore.dart';

enum RentalStatus { active, completed, cancelled }

class Rental {
  final String id;
  final String userId;
  final String powerBankId;
  final String stationIdStart;
  final String? stationIdEnd;
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
