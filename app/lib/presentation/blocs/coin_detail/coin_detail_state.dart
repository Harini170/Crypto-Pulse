part of 'coin_detail_bloc.dart';

class CoinDetailState extends Equatable {
  const CoinDetailState({
    required this.coin,
    this.chart = const [],
    this.range = ChartRange.d7,
    this.chartStatus = LoadStatus.initial,
    this.detailLoaded = false,
    this.chartError,
  });

  /// Seeded from the list row so the screen paints instantly, then enriched by the API.
  final Coin coin;
  final List<ChartPoint> chart;
  final ChartRange range;
  final LoadStatus chartStatus;
  final bool detailLoaded;
  final String? chartError;

  /// Trend over the *selected range* (drives chart colour).
  bool get rangeIsUp => chart.length < 2 || chart.last.price >= chart.first.price;

  double? get rangeChangePct => chart.length < 2 || chart.first.price == 0
      ? null
      : (chart.last.price - chart.first.price) / chart.first.price * 100;

  CoinDetailState copyWith({
    Coin? coin,
    List<ChartPoint>? chart,
    ChartRange? range,
    LoadStatus? chartStatus,
    bool? detailLoaded,
    String? chartError,
    bool clearChartError = false,
  }) =>
      CoinDetailState(
        coin: coin ?? this.coin,
        chart: chart ?? this.chart,
        range: range ?? this.range,
        chartStatus: chartStatus ?? this.chartStatus,
        detailLoaded: detailLoaded ?? this.detailLoaded,
        chartError: clearChartError ? null : (chartError ?? this.chartError),
      );

  @override
  List<Object?> get props => [coin, chart, range, chartStatus, detailLoaded, chartError];
}
