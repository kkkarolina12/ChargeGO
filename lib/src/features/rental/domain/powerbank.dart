enum PowerBankStatus { available, inUse, charging }

class PowerBank {
  final String id;
  final String serialNumber;
  final double batteryLevel;
  final PowerBankStatus status;

  const PowerBank({
    required this.id,
    required this.serialNumber,
    required this.batteryLevel,
    required this.status,
  });

  factory PowerBank.fromJson(Map<String, dynamic> json) {
    final batteryLevel = json['batteryLevel'] ?? json['porcentaje_carga'] ?? 0;
    return PowerBank(
      id: (json['id'] ?? json['id_bateria']) as String,
      serialNumber: (json['serialNumber'] ?? json['id_bateria']) as String,
      batteryLevel: (batteryLevel as num).toDouble(),
      status: _powerBankStatusFromValue(json['status'] ?? json['estado']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serialNumber': serialNumber,
      'batteryLevel': batteryLevel,
      'status': status.name,
    };
  }

  Map<String, dynamic> toFirestoreSchema({String? stationId}) {
    return {
      'id_bateria': id,
      if (stationId != null) 'id_estacion': stationId,
      'porcentaje_carga': batteryLevel,
      'estado': _powerBankStatusToString(status),
    };
  }

  PowerBank copyWith({
    String? id,
    String? serialNumber,
    double? batteryLevel,
    PowerBankStatus? status,
  }) {
    return PowerBank(
      id: id ?? this.id,
      serialNumber: serialNumber ?? this.serialNumber,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      status: status ?? this.status,
    );
  }
}

PowerBankStatus _powerBankStatusFromValue(dynamic value) {
  if (value is bool) {
    return value ? PowerBankStatus.inUse : PowerBankStatus.available;
  }

  switch (value?.toString().trim().toLowerCase()) {
    case 'en_uso':
    case 'en uso':
    case 'in_use':
    case 'inuse':
    case 'ocupada':
    case 'ocupado':
      return PowerBankStatus.inUse;
    case 'cargando':
    case 'charging':
      return PowerBankStatus.charging;
    case 'disponible':
    case 'libre':
    case 'activa':
    case 'activo':
    case 'available':
    default:
      return PowerBankStatus.available;
  }
}

String _powerBankStatusToString(PowerBankStatus status) {
  switch (status) {
    case PowerBankStatus.inUse:
      return 'en_uso';
    case PowerBankStatus.charging:
      return 'cargando';
    case PowerBankStatus.available:
      return 'disponible';
  }
}
