import 'dart:async';
import 'package:chargego/src/features/rental/data/rental_repository.dart';
import 'package:chargego/src/features/rental/domain/rental.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RentalState {
  final Rental? activeRental;
  final Duration elapsed;
  final double estimatedPrice;
  final bool isLoading;

  RentalState({
    this.activeRental,
    this.elapsed = Duration.zero,
    this.estimatedPrice = 0.0,
    this.isLoading = false,
  });

  RentalState copyWith({
    Rental? activeRental,
    Duration? elapsed,
    double? estimatedPrice,
    bool? isLoading,
  }) {
    return RentalState(
      activeRental: activeRental ?? this.activeRental,
      elapsed: elapsed ?? this.elapsed,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class RentalController extends StateNotifier<RentalState> {
  final RentalRepository _repository;
  Timer? _timer;

  RentalController(this._repository) : super(RentalState()) {
    _init();
  }

  void _init() async {
    state = state.copyWith(isLoading: true);
    final rental = await _repository.getActiveRental();
    if (rental != null) {
      state = state.copyWith(activeRental: rental, isLoading: false);
      _startTimer();
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.activeRental != null) {
        final now = DateTime.now();
        final elapsed = now.difference(state.activeRental!.startTime);
        final price = _calculatePrice(elapsed);
        state = state.copyWith(elapsed: elapsed, estimatedPrice: price);
      }
    });
  }

  double _calculatePrice(Duration elapsed) {
    // Simple price: $1.00 per hour, minimum $0.50
    final hours = elapsed.inSeconds / 3600;
    final price = 0.50 + (hours * 1.0);
    return double.parse(price.toStringAsFixed(2));
  }

  Future<void> startNewRental(String powerBankId) async {
    state = state.copyWith(isLoading: true);
    try {
      final rental = await _repository.startRental(
        userId: 'user_123', // Mock user
        powerBankId: powerBankId,
        stationIdStart: 'station_001', // Mock station
      );
      state = state.copyWith(activeRental: rental, isLoading: false);
      _startTimer();
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> stopRental() async {
    if (state.activeRental == null) return;
    state = state.copyWith(isLoading: true);
    try {
      await _repository.endRental(state.activeRental!.id, 'station_002');
      _timer?.cancel();
      state = RentalState();
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final rentalControllerProvider = StateNotifierProvider<RentalController, RentalState>((ref) {
  final repository = ref.watch(rentalRepositoryProvider);
  return RentalController(repository);
});
