import 'package:equatable/equatable.dart';

import 'coin.dart';

class DominanceSlice extends Equatable {
  const DominanceSlice(this.symbol, this.share);
  final String symbol;
  final double share;

  @override
  List<Object?> get props => [symbol, share];
}

class MarketStats extends Equatable {
  const MarketStats({
    required this.totalMarketCap,
    required this.totalVolume,
    required this.marketCapChange24h,
    required this.btcDominance,
    required this.ethDominance,
    required this.activeCoins,
    required this.gainers,
    required this.losers,
    required this.dominance,
    required this.topGainers,
    required this.topLosers,
    required this.source,
  });

  final double totalMarketCap;
  final double totalVolume;
  final double marketCapChange24h;
  final double btcDominance;
  final double ethDominance;
  final int activeCoins;
  final int gainers;
  final int losers;
  final List<DominanceSlice> dominance;
  final List<Coin> topGainers;
  final List<Coin> topLosers;
  final String source;

  factory MarketStats.fromJson(Map<String, dynamic> j) {
    double d(Object? v) => (v as num?)?.toDouble() ?? 0;
    List<Coin> coins(Object? v) =>
        (v as List? ?? []).map((e) => Coin.fromJson(e as Map<String, dynamic>)).toList();
    return MarketStats(
      totalMarketCap: d(j['total_market_cap']),
      totalVolume: d(j['total_volume']),
      marketCapChange24h: d(j['market_cap_change_24h']),
      btcDominance: d(j['btc_dominance']),
      ethDominance: d(j['eth_dominance']),
      activeCoins: (j['active_coins'] as num?)?.toInt() ?? 0,
      gainers: (j['gainers'] as num?)?.toInt() ?? 0,
      losers: (j['losers'] as num?)?.toInt() ?? 0,
      dominance: (j['dominance'] as List? ?? [])
          .map((e) => DominanceSlice(e['symbol'] as String, d(e['share'])))
          .toList(),
      topGainers: coins(j['top_gainers']),
      topLosers: coins(j['top_losers']),
      source: j['source'] as String? ?? 'live',
    );
  }

  @override
  List<Object?> get props => [
        totalMarketCap, totalVolume, marketCapChange24h, btcDominance, ethDominance,
        activeCoins, gainers, losers, dominance, topGainers, topLosers, source,
      ];
}
