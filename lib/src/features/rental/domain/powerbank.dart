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
    return PowerBank(
      id: json['id'] as String,
      serialNumber: json['serialNumber'] as String,
      batteryLevel: (json['batteryLevel'] as num).toDouble(),
      status: PowerBankStatus.values.firstWhere(
        (e) => e.toString() == 'PowerBankStatus.${json['status']}',
        orElse: () => PowerBankStatus.available,
      ),
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
