import 'package:bloc_test/bloc_test.dart';
import 'package:crypto_pulse/core/error/app_exception.dart';
import 'package:crypto_pulse/core/utils/load_status.dart';
import 'package:crypto_pulse/data/models/chart_point.dart';
import 'package:crypto_pulse/data/models/coin.dart';
import 'package:crypto_pulse/data/models/market_stats.dart';
import 'package:crypto_pulse/data/models/paged_coins.dart';
import 'package:crypto_pulse/domain/entities/market_options.dart';
import 'package:crypto_pulse/domain/repositories/coin_repository.dart';
import 'package:crypto_pulse/presentation/blocs/market/market_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements CoinRepository {
  _FakeRepo({this.fail = false});
  final bool fail;

  static const _btc = Coin(
    id: 'bitcoin', symbol: 'btc', name: 'Bitcoin', currentPrice: 67000, marketCap: 1e12,
    marketCapRank: 1, totalVolume: 3e10, high24h: 68000, low24h: 66000, priceChange24h: 1.2,
    circulatingSupply: 19.7e6, ath: 73000, atl: 67,
  );

  @override
  Future<PagedCoins> getCoins({
    required int page,
    required int perPage,
    String query = '',
    CoinSort sort = CoinSort.marketCap,
    bool ascending = false,
    CoinFilter filter = CoinFilter.all,
  }) async {
    if (fail) throw const AppException('boom', ErrorKind.network);
    return const PagedCoins(coins: [_btc], page: 1, hasMore: false, total: 1, source: 'mock');
  }

  @override
  Future<List<Coin>> getCoinsByIds(List<String> ids) async => const [_btc];
  @override
  Future<Coin> getCoinDetail(String id) async => _btc;
  @override
  Future<List<ChartPoint>> getChart(String id, ChartRange range) async => const [];
  @override
  Future<MarketStats> getMarketStats() => throw UnimplementedError();
}

void main() {
  group('MarketBloc', () {
    blocTest<MarketBloc, MarketState>(
      'emits loading then success with coins',
      build: () => MarketBloc(_FakeRepo()),
      act: (b) => b.add(const MarketStarted()),
      expect: () => [
        isA<MarketState>().having((s) => s.status, 'status', LoadStatus.loading),
        isA<MarketState>()
            .having((s) => s.status, 'status', LoadStatus.success)
            .having((s) => s.coins.length, 'coins', 1)
            .having((s) => s.source, 'source', 'mock'),
      ],
    );

    blocTest<MarketBloc, MarketState>(
      'emits failure with message when the API fails',
      build: () => MarketBloc(_FakeRepo(fail: true)),
      act: (b) => b.add(const MarketStarted()),
      expect: () => [
        isA<MarketState>().having((s) => s.status, 'status', LoadStatus.loading),
        isA<MarketState>()
            .having((s) => s.status, 'status', LoadStatus.failure)
            .having((s) => s.error, 'error', 'boom'),
      ],
    );
  });
}
