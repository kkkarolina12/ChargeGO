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
    final id = _readString(json['id'] ?? json['id_estacion']);
    return Station(
      id: id ?? 'estacion_sin_id',
      name: _readString(json['name'] ?? json['nombre']) ?? 'Estacion ChargeGO',
      latitude: _readCoordinate(json, location, 'latitude', 'latitud'),
      longitude: _readCoordinate(json, location, 'longitude', 'longitud'),
      address: _readString(json['address'] ?? json['direccion']) ?? '',
      availableCount: _readInt(json['availableCount'] ?? json['disponibles']),
      totalSlots: _readInt(json['totalSlots'] ?? json['capacidad_total']),
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
  if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? 0;

  if (location is GeoPoint) {
    if (schemaKey == 'latitud') return location.latitude;
    if (schemaKey == 'longitud') return location.longitude;
  }

  if (location is Map<String, dynamic>) {
    final nestedValue = location[englishKey] ?? location[schemaKey];
    if (nestedValue is num) return nestedValue.toDouble();
    if (nestedValue is String) {
      return double.tryParse(nestedValue.replaceAll(',', '.')) ?? 0;
    }
  }

  return 0;
}

String? _readString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
