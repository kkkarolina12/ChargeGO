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
      id: json['id'] as String,
      userId: json['userId'] as String,
      powerBankId: json['powerBankId'] as String,
      stationIdStart: json['stationIdStart'] as String,
      stationIdEnd: json['stationIdEnd'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      totalCost: (json['totalCost'] as num).toDouble(),
      status: RentalStatus.values.firstWhere(
        (e) => e.toString() == 'RentalStatus.${json['status']}',
        orElse: () => RentalStatus.active,
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
