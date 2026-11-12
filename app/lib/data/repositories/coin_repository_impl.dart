import '../../core/constants/api_constants.dart';
import '../../core/error/app_exception.dart';
import '../../domain/entities/market_options.dart';
import '../../domain/repositories/coin_repository.dart';
import '../datasources/cache_local_data_source.dart';
import '../datasources/coin_remote_data_source.dart';
import '../models/chart_point.dart';
import '../models/coin.dart';
import '../models/market_stats.dart';
import '../models/paged_coins.dart';

class CoinRepositoryImpl implements CoinRepository {
  CoinRepositoryImpl(this._remote, this._cache);

  final CoinRemoteDataSource _remote;
  final CacheLocalDataSource _cache;

  static const _marketKey = 'market_page1';

  @override
  Future<PagedCoins> getCoins({
    required int page,
    required int perPage,
    String query = '',
    CoinSort sort = CoinSort.marketCap,
    bool ascending = false,
    CoinFilter filter = CoinFilter.all,
  }) async {
    // Only the default first page (what you see on launch) is cached for offline use.
    final cacheable = page == 1 &&
        perPage == ApiConstants.pageSize &&
        query.isEmpty &&
        sort == CoinSort.marketCap &&
        !ascending &&
        filter == CoinFilter.all;

    try {
      final result = await _remote.fetchCoins(
        page: page,
        perPage: perPage,
        query: query,
        sort: sort,
        ascending: ascending,
        filter: filter,
      );
      if (cacheable) await _cache.saveJson(_marketKey, result.toJson());
      return result;
    } on AppException catch (e) {
      final offline = e.kind == ErrorKind.network || e.kind == ErrorKind.timeout;
      if (cacheable && offline) {
        final json = _cache.readJson(_marketKey);
        if (json != null) return PagedCoins.fromJson(json).withSource('cache');
      }
      rethrow;
    }
  }

  @override
  Future<List<Coin>> getCoinsByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final res = await _remote.fetchCoins(
      page: 1,
      perPage: ApiConstants.maxPageSize,
      query: '',
      sort: CoinSort.marketCap,
      ascending: false,
      filter: CoinFilter.all,
      ids: ids,
    );
    return res.coins;
  }

  @override
  Future<Coin> getCoinDetail(String id) => _remote.fetchCoin(id);

  @override
  Future<List<ChartPoint>> getChart(String id, ChartRange range) =>
      _remote.fetchChart(id, range.days);

  @override
  Future<MarketStats> getMarketStats() => _remote.fetchStats();
}
