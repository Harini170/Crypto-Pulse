import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/utils/load_status.dart';
import '../../../data/models/market_stats.dart';
import '../../../domain/repositories/coin_repository.dart';

part 'stats_event.dart';
part 'stats_state.dart';

class StatsBloc extends Bloc<StatsEvent, StatsState> {
  StatsBloc(this._repository) : super(const StatsState()) {
    on<StatsStarted>(_onStarted, transformer: droppable());
    on<StatsRefreshed>(_onRefreshed, transformer: droppable());
    on<StatsTicked>(_onTicked, transformer: droppable());
  }

  final CoinRepository _repository;
  Timer? _timer;

  Future<void> _onStarted(StatsStarted event, Emitter<StatsState> emit) async {
    emit(state.copyWith(status: LoadStatus.loading, clearError: true));
    try {
      final stats = await _repository.getMarketStats();
      emit(state.copyWith(status: LoadStatus.success, stats: stats));
    } on AppException catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, error: e.message));
    }
    _timer ??= Timer.periodic(
      ApiConstants.refreshInterval * 2,
      (_) => add(const StatsTicked()),
    );
  }

  Future<void> _onRefreshed(StatsRefreshed event, Emitter<StatsState> emit) async {
    emit(state.copyWith(isRefreshing: true, clearError: true));
    try {
      final stats = await _repository.getMarketStats();
      emit(state.copyWith(status: LoadStatus.success, stats: stats, isRefreshing: false));
    } on AppException catch (e) {
      emit(state.copyWith(
        isRefreshing: false,
        status: state.stats == null ? LoadStatus.failure : state.status,
        error: e.message,
      ));
    }
  }

  Future<void> _onTicked(StatsTicked event, Emitter<StatsState> emit) async {
    if (state.status != LoadStatus.success) return;
    try {
      emit(state.copyWith(stats: await _repository.getMarketStats()));
    } on AppException {
      // silent
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
