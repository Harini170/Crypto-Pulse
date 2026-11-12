import '../../core/network/api_client.dart';
import '../../domain/entities/market_options.dart';
import '../models/chart_point.dart';
import '../models/coin.dart';
import '../models/market_stats.dart';
import '../models/paged_coins.dart';

/// Talks to the backend API and turns the JSON into app models.
class CoinRemoteDataSource {
  CoinRemoteDataSource(this._api);

  final ApiClient _api;

  /// GET /coins  (paging, search, sort, filter, optional list of ids)
  Future<PagedCoins> fetchCoins({
    required int page,
    required int perPage,
    required String query,
    required CoinSort sort,
    required bool ascending,
    required CoinFilter filter,
    List<String>? ids,
  }) async {
    final json = await _api.get('/coins', query: {
      'page': page,
      'per_page': perPage,
      if (query.isNotEmpty) 'q': query,
      'sort': sort.apiValue,
      'order': ascending ? 'asc' : 'desc',
      'filter': filter.apiValue,
      if (ids != null && ids.isNotEmpty) 'ids': ids.join(','),
    });
    return PagedCoins.fromJson(json);
  }

  /// GET /coins/{id}
  Future<Coin> fetchCoin(String id) async {
    final json = await _api.get('/coins/$id');
    return Coin.fromJson(json);
  }

  /// GET /coins/{id}/chart?days=7
  Future<List<ChartPoint>> fetchChart(String id, int days) async {
    final json = await _api.get('/coins/$id/chart', query: {'days': days});
    final prices = json['prices'] as List? ?? const [];
    return prices.map((e) => ChartPoint.fromList(e as List<dynamic>)).toList();
  }

  /// GET /market/stats
  Future<MarketStats> fetchStats() async {
    final json = await _api.get('/market/stats');
    return MarketStats.fromJson(json);
  }
}
