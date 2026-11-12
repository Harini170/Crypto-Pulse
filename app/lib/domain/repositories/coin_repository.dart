import '../../data/models/chart_point.dart';
import '../../data/models/coin.dart';
import '../../data/models/market_stats.dart';
import '../../data/models/paged_coins.dart';
import '../entities/market_options.dart';

abstract class CoinRepository {
  Future<PagedCoins> getCoins({
    required int page,
    required int perPage,
    String query = '',
    CoinSort sort = CoinSort.marketCap,
    bool ascending = false,
    CoinFilter filter = CoinFilter.all,
  });

  Future<List<Coin>> getCoinsByIds(List<String> ids);
  Future<Coin> getCoinDetail(String id);
  Future<List<ChartPoint>> getChart(String id, ChartRange range);
  Future<MarketStats> getMarketStats();
}
