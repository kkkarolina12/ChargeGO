import 'package:chargego/src/features/rental/domain/rental.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RentalRepository {
  Rental? _activeRental;

  Future<Rental?> getActiveRental() async {
    // Mocking an API call
    await Future.delayed(const Duration(milliseconds: 500));
    return _activeRental;
  }

  Future<Rental> startRental({
    required String userId,
    required String powerBankId,
    required String stationIdStart,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    _activeRental = Rental(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      powerBankId: powerBankId,
      stationIdStart: stationIdStart,
      startTime: DateTime.now(),
      status: RentalStatus.active,
    );
    return _activeRental!;
  }

  Future<void> endRental(String rentalId, String stationIdEnd) async {
    await Future.delayed(const Duration(seconds: 1));
    if (_activeRental?.id == rentalId) {
      _activeRental = null;
    }
  }
}

final rentalRepositoryProvider = Provider<RentalRepository>((ref) {
  return RentalRepository();
});
