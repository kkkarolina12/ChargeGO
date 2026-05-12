import 'dart:async';

import 'package:chargego/src/features/auth/data/auth_repository.dart';
import 'package:chargego/src/features/history/data/history_repository.dart';
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
  final AuthRepository _authRepository;
  final Ref _ref;
  Timer? _timer;

  RentalController(this._repository, this._authRepository, this._ref)
    : super(RentalState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    final user = _authRepository.currentUser;
    if (user == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final rental = await _repository.getActiveRental(user.id);
      if (rental != null) {
        state = state.copyWith(
          activeRental: rental,
          elapsed: DateTime.now().difference(rental.startTime),
          estimatedPrice: _calculatePrice(rental, DateTime.now()),
          isLoading: false,
        );
        _startTimer();
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _tick();
  }

  void _tick() {
    final rental = state.activeRental;
    if (rental == null) return;

    final now = DateTime.now();
    state = state.copyWith(
      elapsed: now.difference(rental.startTime),
      estimatedPrice: _calculatePrice(rental, now),
    );
  }

  double _calculatePrice(Rental rental, DateTime at) {
    return calculateRentalCost(
      startTime: rental.startTime,
      endTime: at,
      pricePerHour: rental.pricePerHour ?? 0,
      maxDailyPrice: rental.maxDailyPrice,
    );
  }

  Future<void> startNewRental(String rentalCode) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _authRepository.currentUser;
      if (user == null) {
        throw Exception('No hay un usuario autenticado.');
      }

      final rental = await _repository.startRental(
        userId: user.id,
        rentalCode: rentalCode,
      );
      state = state.copyWith(
        activeRental: rental,
        elapsed: Duration.zero,
        estimatedPrice: _calculatePrice(rental, DateTime.now()),
        isLoading: false,
      );
      _startTimer();
      _ref.invalidate(rentalHistoryProvider(user.id));
    } catch (_) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<Rental> stopRental(String returnStationCode) async {
    final rental = state.activeRental;
    if (rental == null) {
      throw Exception('No hay alquiler activo.');
    }

    state = state.copyWith(isLoading: true);
    try {
      final completedRental = await _repository.endRental(
        rental.id,
        returnStationCode: returnStationCode,
      );
      final user = _authRepository.currentUser;
      if (user != null) {
        _ref.invalidate(rentalHistoryProvider(user.id));
      }
      _timer?.cancel();
      state = RentalState();
      return completedRental;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final rentalControllerProvider =
    StateNotifierProvider<RentalController, RentalState>((ref) {
      final repository = ref.watch(rentalRepositoryProvider);
      final authRepository = ref.watch(authRepositoryProvider);
      return RentalController(repository, authRepository, ref);
    });
