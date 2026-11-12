import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/utils/load_status.dart';
import '../../../data/models/chart_point.dart';
import '../../../data/models/coin.dart';
import '../../../domain/entities/market_options.dart';
import '../../../domain/repositories/coin_repository.dart';

part 'coin_detail_event.dart';
part 'coin_detail_state.dart';

class CoinDetailBloc extends Bloc<CoinDetailEvent, CoinDetailState> {
  CoinDetailBloc(this._repository, Coin seed) : super(CoinDetailState(coin: seed)) {
    on<CoinDetailStarted>(_onStarted, transformer: droppable());
    on<CoinDetailTicked>(_onTicked, transformer: droppable());
    on<ChartRangeChanged>(_onRangeChanged, transformer: restartable());
    on<ChartRetried>(_onRetried, transformer: droppable());
  }

  final CoinRepository _repository;
  final Map<ChartRange, List<ChartPoint>> _chartCache = {};
  Timer? _timer;

  Future<void> _onStarted(CoinDetailStarted event, Emitter<CoinDetailState> emit) async {
    _timer ??= Timer.periodic(
      ApiConstants.refreshInterval,
      (_) => add(const CoinDetailTicked()),
    );
    await Future.wait([_loadDetail(emit), _loadChart(emit, state.range)]);
  }

  Future<void> _loadDetail(Emitter<CoinDetailState> emit) async {
    try {
      final coin = await _repository.getCoinDetail(state.coin.id);
      emit(state.copyWith(coin: coin, detailLoaded: true));
    } on AppException {
      // Keep the seeded coin; description simply stays hidden.
    }
  }

  Future<void> _loadChart(Emitter<CoinDetailState> emit, ChartRange range) async {
    final cached = _chartCache[range];
    if (cached != null) {
      emit(state.copyWith(
        range: range, chart: cached, chartStatus: LoadStatus.success, clearChartError: true));
      return;
    }
    emit(state.copyWith(range: range, chartStatus: LoadStatus.loading, clearChartError: true));
    try {
      final points = await _repository.getChart(state.coin.id, range);
      _chartCache[range] = points;
      emit(state.copyWith(chart: points, chartStatus: LoadStatus.success));
    } on AppException catch (e) {
      emit(state.copyWith(chartStatus: LoadStatus.failure, chartError: e.message));
    }
  }

  Future<void> _onTicked(CoinDetailTicked event, Emitter<CoinDetailState> emit) async {
    try {
      final coin = await _repository.getCoinDetail(state.coin.id);
      emit(state.copyWith(coin: coin, detailLoaded: true));
    } on AppException {
      // silent
    }
  }

  Future<void> _onRangeChanged(ChartRangeChanged event, Emitter<CoinDetailState> emit) =>
      _loadChart(emit, event.range);

  Future<void> _onRetried(ChartRetried event, Emitter<CoinDetailState> emit) =>
      _loadChart(emit, state.range);

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
