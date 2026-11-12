part of 'market_bloc.dart';

sealed class MarketEvent extends Equatable {
  const MarketEvent();
  @override
  List<Object?> get props => [];
}

final class MarketStarted extends MarketEvent {
  const MarketStarted();
}

/// Pull-to-refresh.
final class MarketRefreshed extends MarketEvent {
  const MarketRefreshed();
}

/// Periodic silent refresh to keep prices "live".
final class MarketTicked extends MarketEvent {
  const MarketTicked();
}

final class MarketLoadMore extends MarketEvent {
  const MarketLoadMore();
}

final class MarketSearchChanged extends MarketEvent {
  const MarketSearchChanged(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

final class MarketSortChanged extends MarketEvent {
  const MarketSortChanged(this.sort, {required this.ascending});
  final CoinSort sort;
  final bool ascending;
  @override
  List<Object?> get props => [sort, ascending];
}

final class MarketFilterChanged extends MarketEvent {
  const MarketFilterChanged(this.filter);
  final CoinFilter filter;
  @override
  List<Object?> get props => [filter];
}
