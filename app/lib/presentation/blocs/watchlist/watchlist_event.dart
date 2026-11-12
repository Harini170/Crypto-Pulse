part of 'watchlist_bloc.dart';

sealed class WatchlistEvent extends Equatable {
  const WatchlistEvent();
  @override
  List<Object?> get props => [];
}

final class WatchlistStarted extends WatchlistEvent {
  const WatchlistStarted();
}

final class WatchlistRefreshed extends WatchlistEvent {
  const WatchlistRefreshed();
}

/// Adds the coin if it is not watched, removes it otherwise.
final class WatchlistToggled extends WatchlistEvent {
  const WatchlistToggled(this.coin);
  final Coin coin;
  @override
  List<Object?> get props => [coin.id];
}
