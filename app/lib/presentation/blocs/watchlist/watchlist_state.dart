part of 'watchlist_bloc.dart';

class WatchlistState extends Equatable {
  const WatchlistState({
    this.status = LoadStatus.initial,
    this.ids = const [],
    this.coins = const [],
    this.error,
  });

  final LoadStatus status;

  /// Source of truth (persisted), newest first.
  final List<String> ids;

  /// Market data for [ids], in the same order.
  final List<Coin> coins;
  final String? error;

  bool contains(String id) => ids.contains(id);

  WatchlistState copyWith({
    LoadStatus? status,
    List<String>? ids,
    List<Coin>? coins,
    String? error,
    bool clearError = false,
  }) =>
      WatchlistState(
        status: status ?? this.status,
        ids: ids ?? this.ids,
        coins: coins ?? this.coins,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [status, ids, coins, error];
}
