import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/utils/load_status.dart';
import '../../../data/models/coin.dart';
import '../../../data/models/paged_coins.dart';
import '../../../domain/entities/market_options.dart';
import '../../../domain/repositories/coin_repository.dart';

part 'market_event.dart';
part 'market_state.dart';

/// ViewModel for the coin list: paging, search (debounced), filter, sort and live refresh.
class MarketBloc extends Bloc<MarketEvent, MarketState> {
  MarketBloc(this._repository) : super(const MarketState()) {
    on<MarketStarted>(_onStarted, transformer: droppable());
    on<MarketRefreshed>(_onRefreshed, transformer: restartable());
    on<MarketTicked>(_onTicked, transformer: droppable());
    on<MarketLoadMore>(_onLoadMore, transformer: droppable());
    on<MarketSearchChanged>(_onSearchChanged, transformer: restartable());
    on<MarketSortChanged>(_onSortChanged, transformer: restartable());
    on<MarketFilterChanged>(_onFilterChanged, transformer: restartable());
  }

  final CoinRepository _repository;
  Timer? _timer;

  Future<PagedCoins> _fetch(int page, {int perPage = ApiConstants.pageSize}) =>
      _repository.getCoins(
        page: page,
        perPage: perPage,
        query: state.query,
        sort: state.sort,
        ascending: state.ascending,
        filter: state.filter,
      );

  /// Shows the shimmer, then replaces the list with page 1 of the current query.
  Future<void> _loadFirstPage(Emitter<MarketState> emit, MarketState base) async {
    emit(base.copyWith(
      status: LoadStatus.loading,
      page: 1,
      hasMore: true,
      isLoadingMore: false,
      clearError: true,
    ));
    try {
      final res = await _fetch(1);
      emit(state.copyWith(
        status: LoadStatus.success,
        coins: res.coins,
        page: 1,
        hasMore: res.hasMore,
        source: res.source,
        clearError: true,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, coins: const [], error: e.message));
    }
  }

  Future<void> _onStarted(MarketStarted event, Emitter<MarketState> emit) async {
    await _loadFirstPage(emit, state);
    _timer ??= Timer.periodic(
      ApiConstants.refreshInterval,
      (_) => add(const MarketTicked()),
    );
  }

  Future<void> _onRefreshed(MarketRefreshed event, Emitter<MarketState> emit) async {
    emit(state.copyWith(isRefreshing: true, clearError: true));
    try {
      final res = await _fetch(1);
      emit(state.copyWith(
        status: LoadStatus.success,
        coins: res.coins,
        page: 1,
        hasMore: res.hasMore,
        source: res.source,
        isRefreshing: false,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(
        isRefreshing: false,
        status: state.coins.isEmpty ? LoadStatus.failure : state.status,
        error: e.message,
      ));
    }
  }

  /// Silent refresh of everything already loaded (prices flash in the UI).
  Future<void> _onTicked(MarketTicked event, Emitter<MarketState> emit) async {
    if (state.status != LoadStatus.success || state.isLoadingMore || state.isRefreshing) return;
    try {
      final size = state.coins.length.clamp(ApiConstants.pageSize, ApiConstants.maxPageSize);
      final res = await _fetch(1, perPage: size);
      emit(state.copyWith(coins: res.coins, source: res.source));
    } on AppException {
      // Ignore: a background refresh must never disturb the screen.
    }
  }

  Future<void> _onLoadMore(MarketLoadMore event, Emitter<MarketState> emit) async {
    if (!state.hasMore || state.isLoadingMore || state.status != LoadStatus.success) return;
    emit(state.copyWith(isLoadingMore: true, clearError: true));
    try {
      final next = state.page + 1;
      final res = await _fetch(next);
      emit(state.copyWith(
        coins: [...state.coins, ...res.coins],
        page: next,
        hasMore: res.hasMore,
        isLoadingMore: false,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(isLoadingMore: false, error: e.message));
    }
  }

  Future<void> _onSearchChanged(MarketSearchChanged event, Emitter<MarketState> emit) async {
    final q = event.query.trim();
    if (q == state.query) return;
    await Future<void>.delayed(const Duration(milliseconds: 400)); // debounce
    await _loadFirstPage(emit, state.copyWith(query: q));
  }

  Future<void> _onSortChanged(MarketSortChanged event, Emitter<MarketState> emit) =>
      _loadFirstPage(emit, state.copyWith(sort: event.sort, ascending: event.ascending));

  Future<void> _onFilterChanged(MarketFilterChanged event, Emitter<MarketState> emit) =>
      _loadFirstPage(emit, state.copyWith(filter: event.filter));

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
