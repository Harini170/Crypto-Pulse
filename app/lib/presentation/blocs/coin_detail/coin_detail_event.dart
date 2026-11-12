part of 'coin_detail_bloc.dart';

sealed class CoinDetailEvent extends Equatable {
  const CoinDetailEvent();
  @override
  List<Object?> get props => [];
}

final class CoinDetailStarted extends CoinDetailEvent {
  const CoinDetailStarted();
}

final class CoinDetailTicked extends CoinDetailEvent {
  const CoinDetailTicked();
}

final class ChartRangeChanged extends CoinDetailEvent {
  const ChartRangeChanged(this.range);
  final ChartRange range;
  @override
  List<Object?> get props => [range];
}

final class ChartRetried extends CoinDetailEvent {
  const ChartRetried();
}
