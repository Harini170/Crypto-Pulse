import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/utils/load_status.dart';
import '../../../data/models/coin.dart';
import '../../../domain/repositories/coin_repository.dart';
import '../../../domain/repositories/watchlist_repository.dart';

part 'watchlist_event.dart';
part 'watchlist_state.dart';

/// App-wide singleton: the star buttons everywhere and the watchlist tab share it.
class WatchlistBloc extends Bloc<WatchlistEvent, WatchlistState> {
  WatchlistBloc(this._watchlist, this._coins) : super(const WatchlistState()) {
    on<WatchlistStarted>(_onStarted, transformer: droppable());
    on<WatchlistRefreshed>(_onRefreshed, transformer: restartable());
    on<WatchlistToggled>(_onToggled, transformer: sequential());
  }

  final WatchlistRepository _watchlist;
  final CoinRepository _coins;

  Future<void> _onStarted(WatchlistStarted event, Emitter<WatchlistState> emit) async {
    final ids = await _watchlist.getIds();
    if (ids.isEmpty) {
      emit(state.copyWith(status: LoadStatus.success, ids: const [], coins: const []));
      return;
    }
    emit(state.copyWith(status: LoadStatus.loading, ids: ids, clearError: true));
    await _fetch(emit, ids);
  }

  Future<void> _onRefreshed(WatchlistRefreshed event, Emitter<WatchlistState> emit) async {
    if (state.ids.isEmpty) return;
    await _fetch(emit, state.ids);
  }

  Future<void> _fetch(Emitter<WatchlistState> emit, List<String> ids) async {
    try {
      final fetched = await _coins.getCoinsByIds(ids);
      final byId = {for (final c in fetched) c.id: c};
      // Preserve the user's order; drop ids the API no longer knows.
      final ordered = [for (final id in state.ids) if (byId[id] != null) byId[id]!];
      emit(state.copyWith(status: LoadStatus.success, coins: ordered, clearError: true));
    } on AppException catch (e) {
      emit(state.copyWith(
        status: state.coins.isEmpty ? LoadStatus.failure : LoadStatus.success,
        error: e.message,
      ));
    }
  }

  Future<void> _onToggled(WatchlistToggled event, Emitter<WatchlistState> emit) async {
    final id = event.coin.id;
    final List<String> ids;
    final List<Coin> coins;
    if (state.contains(id)) {
      ids = state.ids.where((e) => e != id).toList();
      coins = state.coins.where((c) => c.id != id).toList();
    } else {
      ids = [id, ...state.ids];
      coins = [event.coin, ...state.coins];
    }
    emit(state.copyWith(
      status: LoadStatus.success,
      ids: ids,
      coins: coins,
      clearError: true,
    ));
    await _watchlist.saveIds(ids);
  }
}
