import 'package:chargego/src/features/rental/domain/rental.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class HistoryRepository {
  Future<List<Rental>> getRentalHistory(String userId);
}

class MockHistoryRepository implements HistoryRepository {
  final List<Rental> _mockHistory = [
    Rental(
      id: 'r_1',
      userId: 'user_1',
      powerBankId: 'pb_101',
      stationIdStart: 's_1',
      stationIdEnd: 's_2',
      startTime: DateTime.now().subtract(const Duration(days: 2, hours: 1)),
      endTime: DateTime.now().subtract(const Duration(days: 2)),
      totalCost: 2.50,
      status: RentalStatus.completed,
    ),
    Rental(
      id: 'r_2',
      userId: 'user_1',
      powerBankId: 'pb_205',
      stationIdStart: 's_3',
      stationIdEnd: 's_1',
      startTime: DateTime.now().subtract(const Duration(days: 5, hours: 2)),
      endTime: DateTime.now().subtract(const Duration(days: 5)),
      totalCost: 5.00,
      status: RentalStatus.completed,
    ),
    Rental(
      id: 'r_3',
      userId: 'user_1',
      powerBankId: 'pb_303',
      stationIdStart: 's_2',
      stationIdEnd: 's_2',
      startTime: DateTime.now().subtract(const Duration(days: 10, minutes: 45)),
      endTime: DateTime.now().subtract(const Duration(days: 10)),
      totalCost: 1.50,
      status: RentalStatus.completed,
    ),
  ];

  @override
  Future<List<Rental>> getRentalHistory(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockHistory.where((r) => r.userId == userId).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }
}

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return MockHistoryRepository();
});

final rentalHistoryProvider = FutureProvider.family<List<Rental>, String>((ref, userId) async {
  final repository = ref.watch(historyRepositoryProvider);
  return repository.getRentalHistory(userId);
});
