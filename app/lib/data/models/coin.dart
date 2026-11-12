import 'package:equatable/equatable.dart';

double _d(Object? v) => (v as num?)?.toDouble() ?? 0;
double? _dn(Object? v) => (v as num?)?.toDouble();

class Coin extends Equatable {
  const Coin({
    required this.id,
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.marketCap,
    required this.marketCapRank,
    required this.totalVolume,
    required this.high24h,
    required this.low24h,
    required this.priceChange24h,
    required this.circulatingSupply,
    required this.ath,
    required this.atl,
    this.image,
    this.totalSupply,
    this.maxSupply,
    this.sparkline = const [],
    this.description,
    this.homepage,
    this.categories = const [],
  });

  final String id;
  final String symbol;
  final String name;
  final String? image;
  final double currentPrice;
  final double marketCap;
  final int marketCapRank;
  final double totalVolume;
  final double high24h;
  final double low24h;
  final double priceChange24h; // percent
  final double circulatingSupply;
  final double? totalSupply;
  final double? maxSupply;
  final double ath;
  final double atl;
  final List<double> sparkline;
  final String? description;
  final String? homepage;
  final List<String> categories;

  bool get isUp => priceChange24h >= 0;
  String get ticker => symbol.toUpperCase();

  /// Share of the supply that is already circulating (0..1), if knowable.
  double? get supplyProgress {
    final cap = maxSupply ?? totalSupply;
    if (cap == null || cap <= 0) return null;
    return (circulatingSupply / cap).clamp(0.0, 1.0);
  }

  factory Coin.fromJson(Map<String, dynamic> json) {
    final spark = ((json['sparkline_in_7d'] as Map?)?['price'] as List?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        const <double>[];
    return Coin(
      id: json['id'] as String,
      symbol: json['symbol'] as String? ?? '',
      name: json['name'] as String? ?? '',
      image: json['image'] as String?,
      currentPrice: _d(json['current_price']),
      marketCap: _d(json['market_cap']),
      marketCapRank: (json['market_cap_rank'] as num?)?.toInt() ?? 0,
      totalVolume: _d(json['total_volume']),
      high24h: _d(json['high_24h']),
      low24h: _d(json['low_24h']),
      priceChange24h: _d(json['price_change_percentage_24h']),
      circulatingSupply: _d(json['circulating_supply']),
      totalSupply: _dn(json['total_supply']),
      maxSupply: _dn(json['max_supply']),
      ath: _d(json['ath']),
      atl: _d(json['atl']),
      sparkline: spark,
      description: json['description'] as String?,
      homepage: json['homepage'] as String?,
      categories:
          (json['categories'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'name': name,
        'image': image,
        'current_price': currentPrice,
        'market_cap': marketCap,
        'market_cap_rank': marketCapRank,
        'total_volume': totalVolume,
        'high_24h': high24h,
        'low_24h': low24h,
        'price_change_percentage_24h': priceChange24h,
        'circulating_supply': circulatingSupply,
        'total_supply': totalSupply,
        'max_supply': maxSupply,
        'ath': ath,
        'atl': atl,
        'sparkline_in_7d': {'price': sparkline},
        'description': description,
        'homepage': homepage,
        'categories': categories,
      };

  @override
  List<Object?> get props => [
        id, currentPrice, marketCap, marketCapRank, totalVolume, high24h, low24h,
        priceChange24h, circulatingSupply, totalSupply, maxSupply, ath, atl,
        sparkline, description, image,
      ];
}
