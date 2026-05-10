import 'package:cloud_firestore/cloud_firestore.dart';

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
    final location = json['ubicacion'];
    return Station(
      id: (json['id'] ?? json['id_estacion']) as String,
      name: (json['name'] ?? json['nombre']) as String,
      latitude: _readCoordinate(json, location, 'latitude', 'latitud'),
      longitude: _readCoordinate(json, location, 'longitude', 'longitud'),
      address: (json['address'] ?? json['direccion'] ?? '') as String,
      availableCount:
          (json['availableCount'] ?? json['disponibles'] ?? 0) as int,
      totalSlots: (json['totalSlots'] ?? json['capacidad_total'] ?? 0) as int,
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

  Map<String, dynamic> toFirestoreSchema() {
    return {
      'id_estacion': id,
      'nombre': name,
      'direccion': address,
      'latitud': latitude,
      'longitud': longitude,
      'capacidad_total': totalSlots,
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

double _readCoordinate(
  Map<String, dynamic> json,
  dynamic location,
  String englishKey,
  String schemaKey,
) {
  final value = json[englishKey] ?? json[schemaKey];
  if (value is num) return value.toDouble();

  if (location is GeoPoint) {
    if (schemaKey == 'latitud') return location.latitude;
    if (schemaKey == 'longitud') return location.longitude;
  }

  return 0;
}
