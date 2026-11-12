part of 'market_bloc.dart';

class MarketState extends Equatable {
  const MarketState({
    this.status = LoadStatus.initial,
    this.coins = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.query = '',
    this.sort = CoinSort.marketCap,
    this.ascending = false,
    this.filter = CoinFilter.all,
    this.source = 'live',
    this.error,
  });

  final LoadStatus status;
  final List<Coin> coins;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isRefreshing;
  final String query;
  final CoinSort sort;
  final bool ascending;
  final CoinFilter filter;
  final String source;
  final String? error;

  bool get isDefaultQuery =>
      query.isEmpty && sort == CoinSort.marketCap && !ascending && filter == CoinFilter.all;

  MarketState copyWith({
    LoadStatus? status,
    List<Coin>? coins,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isRefreshing,
    String? query,
    CoinSort? sort,
    bool? ascending,
    CoinFilter? filter,
    String? source,
    String? error,
    bool clearError = false,
  }) =>
      MarketState(
        status: status ?? this.status,
        coins: coins ?? this.coins,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        isRefreshing: isRefreshing ?? this.isRefreshing,
        query: query ?? this.query,
        sort: sort ?? this.sort,
        ascending: ascending ?? this.ascending,
        filter: filter ?? this.filter,
        source: source ?? this.source,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [
        status, coins, page, hasMore, isLoadingMore, isRefreshing,
        query, sort, ascending, filter, source, error,
      ];
}
