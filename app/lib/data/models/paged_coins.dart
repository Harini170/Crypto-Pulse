import 'coin.dart';

class PagedCoins {
  const PagedCoins({
    required this.coins,
    required this.page,
    required this.hasMore,
    required this.total,
    required this.source,
  });

  final List<Coin> coins;
  final int page;
  final bool hasMore;
  final int total;

  /// `live` (CoinGecko) or `mock` (built-in demo market).
  final String source;

  PagedCoins withSource(String newSource) => PagedCoins(
        coins: coins,
        page: page,
        hasMore: hasMore,
        total: total,
        source: newSource,
      );

  Map<String, dynamic> toJson() => {
        'data': coins.map((c) => c.toJson()).toList(),
        'page': page,
        'has_more': hasMore,
        'total': total,
        'source': source,
      };

  factory PagedCoins.fromJson(Map<String, dynamic> json) => PagedCoins(
        coins: (json['data'] as List)
            .map((e) => Coin.fromJson(e as Map<String, dynamic>))
            .toList(),
        page: (json['page'] as num).toInt(),
        hasMore: json['has_more'] as bool? ?? false,
        total: (json['total'] as num?)?.toInt() ?? 0,
        source: json['source'] as String? ?? 'live',
      );
}
