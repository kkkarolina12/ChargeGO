import 'dart:math' as math;

import 'package:chargego/src/core/firebase/firestore_collections.dart';
import 'package:chargego/src/features/rental/domain/rental.dart';
import 'package:chargego/src/features/rental/domain/rental_rate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class RentalRepository {
  Future<Rental?> getActiveRental(String userId);

  Future<Rental> startRental({
    required String userId,
    required String rentalCode,
  });

  Future<Rental> endRental(
    String rentalId, {
    required String returnStationCode,
  });
}

class FirebaseRentalRepository implements RentalRepository {
  FirebaseRentalRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _rentals =>
      _firestore.collection(FirestoreCollections.rentals);

  CollectionReference<Map<String, dynamic>> get _batteries =>
      _firestore.collection(FirestoreCollections.batteries);

  CollectionReference<Map<String, dynamic>> get _stations =>
      _firestore.collection(FirestoreCollections.stations);

  CollectionReference<Map<String, dynamic>> get _rates =>
      _firestore.collection(FirestoreCollections.rates);

  @override
  Future<Rental?> getActiveRental(String userId) async {
    if (userId.isEmpty) return null;

    final snapshot = await _rentals
        .where('id_usuario', isEqualTo: userId)
        .where('estado', isEqualTo: 'activo')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final rental = Rental.fromJson({
      ...snapshot.docs.first.data(),
      'id_alquiler':
          snapshot.docs.first.data()['id_alquiler'] ?? snapshot.docs.first.id,
    });
    return _rentalWithFallbackRate(rental);
  }

  @override
  Future<Rental> startRental({
    required String userId,
    required String rentalCode,
  }) async {
    final code = rentalCode.trim();
    if (code.isEmpty) {
      throw Exception('Introduce un codigo de estacion o bateria.');
    }

    final activeRental = await getActiveRental(userId);
    if (activeRental != null) {
      throw Exception('Ya tienes una bateria alquilada.');
    }

    final rate = await _fetchActiveRate();
    final selection = await _resolveBatteryForCode(code);
    final rentalDoc = _rentals.doc();
    var rental = Rental(
      id: rentalDoc.id,
      userId: userId,
      powerBankId: selection.batteryId,
      stationIdStart: selection.stationId,
      stationStartName: selection.stationName,
      rateId: rate.id,
      rateName: rate.name,
      pricePerHour: rate.pricePerHour,
      maxDailyPrice: rate.maxDailyPrice,
      missingReturnPenalty: rate.missingReturnPenalty,
      startTime: DateTime.now(),
      status: RentalStatus.active,
    );

    await _firestore.runTransaction((transaction) async {
      final batterySnapshot = await transaction.get(selection.batteryRef);
      if (!batterySnapshot.exists || batterySnapshot.data() == null) {
        throw Exception('Bateria no encontrada.');
      }

      final batteryData = batterySnapshot.data()!;
      if (!_isBatteryAvailable(batteryData['estado'])) {
        throw Exception('Esta bateria no esta disponible.');
      }

      final currentStationId =
          _readString(batteryData['id_estacion']) ?? selection.stationId;
      if (currentStationId.isEmpty) {
        throw Exception('La bateria no esta asociada a una estacion.');
      }

      if (selection.stationId.isNotEmpty &&
          currentStationId != selection.stationId) {
        throw Exception('La bateria ya no esta disponible en esa estacion.');
      }

      rental = rental.copyWith(
        powerBankId:
            _readString(batteryData['id_bateria']) ?? selection.batteryId,
        stationIdStart: currentStationId,
      );

      transaction.set(rentalDoc, {
        ...rental.toFirestoreSchema(),
        'fecha_creacion': FieldValue.serverTimestamp(),
      });
      transaction.update(selection.batteryRef, {
        'estado': 'en_uso',
        'id_estacion': null,
      });
    });

    return rental;
  }

  @override
  Future<Rental> endRental(
    String rentalId, {
    required String returnStationCode,
  }) async {
    final station = await _resolveStation(returnStationCode.trim());
    if (station == null) {
      throw Exception('Estacion de devolucion no encontrada.');
    }
    final fallbackRate = await _fetchActiveRate();

    final rentalRef = _rentals.doc(rentalId);
    late Rental finishedRental;

    await _firestore.runTransaction((transaction) async {
      final rentalSnapshot = await transaction.get(rentalRef);
      if (!rentalSnapshot.exists || rentalSnapshot.data() == null) {
        throw Exception('Alquiler no encontrado.');
      }

      final rental = Rental.fromJson({
        ...rentalSnapshot.data()!,
        'id_alquiler':
            rentalSnapshot.data()!['id_alquiler'] ?? rentalSnapshot.id,
      });

      if (rental.status != RentalStatus.active) {
        throw Exception('Este alquiler ya esta finalizado.');
      }

      final batteryRef = _batteries.doc(rental.powerBankId);
      final batterySnapshot = await transaction.get(batteryRef);
      final ratedRental = _rentalWithRate(rental, fallbackRate);
      final endTime = DateTime.now();
      final totalCost = calculateRentalCost(
        startTime: ratedRental.startTime,
        endTime: endTime,
        pricePerHour: ratedRental.pricePerHour ?? 0,
        maxDailyPrice: ratedRental.maxDailyPrice,
      );

      finishedRental = ratedRental.copyWith(
        stationIdEnd: station.id,
        stationEndName: station.name,
        endTime: endTime,
        totalCost: totalCost,
        status: RentalStatus.completed,
      );

      transaction.update(rentalRef, {
        ...finishedRental.toFirestoreSchema(),
        'duracion_minutos': math.max(
          1,
          endTime.difference(ratedRental.startTime).inMinutes,
        ),
        'fecha_actualizacion': FieldValue.serverTimestamp(),
      });

      if (batterySnapshot.exists) {
        transaction.update(batteryRef, {
          'estado': 'disponible',
          'id_estacion': station.id,
        });
      }
    });

    return finishedRental;
  }

  Future<RentalRate> _fetchActiveRate() async {
    final snapshot = await _rates.get();
    if (snapshot.docs.isEmpty) {
      throw Exception('No hay tarifas configuradas en Firebase.');
    }

    final rates = snapshot.docs.map(RentalRate.fromDocument).toList();
    final activeRates = rates.where((rate) => rate.active).toList();
    final selectedRate = (activeRates.isEmpty ? rates : activeRates)
      ..sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));

    final rate = selectedRate.first;
    if (rate.pricePerHour <= 0) {
      throw Exception('La tarifa activa no tiene precio por hora valido.');
    }
    return rate;
  }

  Future<Rental> _rentalWithFallbackRate(Rental rental) async {
    if ((rental.pricePerHour ?? 0) > 0) return rental;
    final rate = await _fetchActiveRate();
    return _rentalWithRate(rental, rate);
  }

  Rental _rentalWithRate(Rental rental, RentalRate rate) {
    return rental.copyWith(
      rateId: rental.rateId ?? rate.id,
      rateName: rental.rateName ?? rate.name,
      pricePerHour: (rental.pricePerHour ?? 0) > 0
          ? rental.pricePerHour
          : rate.pricePerHour,
      maxDailyPrice: rental.maxDailyPrice ?? rate.maxDailyPrice,
      missingReturnPenalty:
          rental.missingReturnPenalty ?? rate.missingReturnPenalty,
    );
  }

  Future<_BatterySelection> _resolveBatteryForCode(String code) async {
    final directBattery = await _findBatteryByCode(code);
    if (directBattery != null) {
      final stationId = _readString(directBattery.data['id_estacion']);
      if (!_isBatteryAvailable(directBattery.data['estado'])) {
        throw Exception('Esta bateria no esta disponible.');
      }
      if (stationId == null || stationId.isEmpty) {
        throw Exception('La bateria no esta en ninguna estacion.');
      }

      final station = await _resolveStation(stationId);
      return _BatterySelection(
        batteryRef: directBattery.reference,
        batteryId: directBattery.id,
        stationId: stationId,
        stationName: station?.name,
      );
    }

    final station = await _resolveStation(code);
    if (station == null) {
      throw Exception('Codigo de estacion o bateria no encontrado.');
    }

    final batteries = await _batteries
        .where('id_estacion', isEqualTo: station.id)
        .get();
    final available =
        batteries.docs
            .where((doc) => _isBatteryAvailable(doc.data()['estado']))
            .toList()
          ..sort((a, b) {
            final aCharge = _readDouble(a.data()['porcentaje_carga']);
            final bCharge = _readDouble(b.data()['porcentaje_carga']);
            return bCharge.compareTo(aCharge);
          });

    if (available.isEmpty) {
      throw Exception('No hay baterias disponibles en esta estacion.');
    }

    final battery = available.first;
    return _BatterySelection(
      batteryRef: battery.reference,
      batteryId: _readString(battery.data()['id_bateria']) ?? battery.id,
      stationId: station.id,
      stationName: station.name,
    );
  }

  Future<_BatterySnapshot?> _findBatteryByCode(String code) async {
    final byDocumentId = await _batteries.doc(code).get();
    if (byDocumentId.exists && byDocumentId.data() != null) {
      return _BatterySnapshot.fromDocument(byDocumentId);
    }

    final bySchemaId = await _batteries
        .where('id_bateria', isEqualTo: code)
        .limit(1)
        .get();
    if (bySchemaId.docs.isNotEmpty) {
      return _BatterySnapshot.fromDocument(bySchemaId.docs.first);
    }

    final byQr = await _batteries
        .where('codigo_qr', isEqualTo: code)
        .limit(1)
        .get();
    if (byQr.docs.isNotEmpty) {
      return _BatterySnapshot.fromDocument(byQr.docs.first);
    }

    return null;
  }

  Future<_StationSnapshot?> _resolveStation(String code) async {
    if (code.isEmpty) return null;

    final byDocumentId = await _stations.doc(code).get();
    if (byDocumentId.exists && byDocumentId.data() != null) {
      return _stationFromDocument(byDocumentId);
    }

    final bySchemaId = await _stations
        .where('id_estacion', isEqualTo: code)
        .limit(1)
        .get();
    if (bySchemaId.docs.isNotEmpty) {
      return _stationFromDocument(bySchemaId.docs.first);
    }

    final byQr = await _stations
        .where('codigo_qr', isEqualTo: code)
        .limit(1)
        .get();
    if (byQr.docs.isNotEmpty) {
      return _stationFromDocument(byQr.docs.first);
    }

    final allStations = await _stations.get();
    for (final station in allStations.docs) {
      final data = station.data();
      final values = [
        station.id,
        data['id_estacion'],
        data['codigo_qr'],
      ].whereType<Object>().map((value) => value.toString().trim());

      if (values.any((value) => value == code)) {
        return _stationFromDocument(station);
      }
    }

    return null;
  }

  _StationSnapshot _stationFromDocument(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    if (!_isStationAvailable(data['estado'])) {
      throw Exception('Esta estacion no esta disponible.');
    }

    return _StationSnapshot(
      id: _readString(data['id_estacion']) ?? snapshot.id,
      name: _readString(data['nombre']) ?? 'Estacion ${snapshot.id}',
    );
  }
}

double calculateRentalCost({
  required DateTime startTime,
  required DateTime endTime,
  required double pricePerHour,
  double? maxDailyPrice,
}) {
  final billableSeconds = math.max(60, endTime.difference(startTime).inSeconds);
  final hourlyCost = pricePerHour <= 0 ? 0 : pricePerHour;
  if (hourlyCost <= 0) return 0;

  final dailyCap = maxDailyPrice;
  if (dailyCap == null || dailyCap <= 0) {
    return _roundCurrency((billableSeconds / 3600) * hourlyCost);
  }

  const daySeconds = 24 * 60 * 60;
  final fullDays = billableSeconds ~/ daySeconds;
  final remainingSeconds = billableSeconds.remainder(daySeconds);
  final remainingCost = math.min(
    dailyCap,
    (remainingSeconds / 3600) * hourlyCost,
  );
  return _roundCurrency((fullDays * dailyCap) + remainingCost);
}

double _roundCurrency(double value) => double.parse(value.toStringAsFixed(2));

bool _isBatteryAvailable(dynamic statusValue) {
  if (statusValue is bool) return !statusValue;

  final status = (statusValue ?? 'disponible')
      .toString()
      .trim()
      .toLowerCase();
  return {
    'disponible',
    'available',
    'cargada',
    'libre',
    'activo',
    'activa',
  }.contains(status);
}

bool _isStationAvailable(dynamic statusValue) {
  final status = (statusValue ?? 'activa').toString().toLowerCase();
  return !{
    'mantenimiento',
    'mant',
    'fuera_servicio',
    'fuera de servicio',
    'fuera',
    'fueraservicio',
    'inactiva',
    'bloqueada',
  }.contains(status);
}

String? _readString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

double _readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  return 0;
}

class _BatterySelection {
  final DocumentReference<Map<String, dynamic>> batteryRef;
  final String batteryId;
  final String stationId;
  final String? stationName;

  const _BatterySelection({
    required this.batteryRef,
    required this.batteryId,
    required this.stationId,
    required this.stationName,
  });
}

class _BatterySnapshot {
  final DocumentReference<Map<String, dynamic>> reference;
  final String id;
  final Map<String, dynamic> data;

  const _BatterySnapshot({
    required this.reference,
    required this.id,
    required this.data,
  });

  factory _BatterySnapshot.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return _BatterySnapshot(
      reference: snapshot.reference,
      id: _readString(data['id_bateria']) ?? snapshot.id,
      data: data,
    );
  }
}

class _StationSnapshot {
  final String id;
  final String name;

  const _StationSnapshot({required this.id, required this.name});
}

final rentalRepositoryProvider = Provider<RentalRepository>((ref) {
  return FirebaseRentalRepository();
});
