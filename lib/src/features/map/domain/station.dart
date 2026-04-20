class Station {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final int availableCount;
  final int totalSlots;

  const Station({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.availableCount,
    required this.totalSlots,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String,
      availableCount: json['availableCount'] as int,
      totalSlots: json['totalSlots'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'availableCount': availableCount,
      'totalSlots': totalSlots,
    };
  }

  Station copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    String? address,
    int? availableCount,
    int? totalSlots,
  }) {
    return Station(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      availableCount: availableCount ?? this.availableCount,
      totalSlots: totalSlots ?? this.totalSlots,
    );
  }
}
