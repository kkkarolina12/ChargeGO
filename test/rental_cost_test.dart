import 'package:chargego/src/features/rental/data/rental_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculates proportional hourly rental cost', () {
    final start = DateTime(2026, 5, 12, 10);
    final end = start.add(const Duration(minutes: 30));

    final cost = calculateRentalCost(
      startTime: start,
      endTime: end,
      pricePerHour: 2,
    );

    expect(cost, 1);
  });

  test('applies a daily maximum when configured', () {
    final start = DateTime(2026, 5, 12, 10);
    final end = start.add(const Duration(hours: 20));

    final cost = calculateRentalCost(
      startTime: start,
      endTime: end,
      pricePerHour: 2,
      maxDailyPrice: 12,
    );

    expect(cost, 12);
  });
}
