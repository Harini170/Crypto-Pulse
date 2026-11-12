part of 'stats_bloc.dart';

class StatsState extends Equatable {
  const StatsState({
    this.status = LoadStatus.initial,
    this.stats,
    this.error,
    this.isRefreshing = false,
  });

  final LoadStatus status;
  final MarketStats? stats;
  final String? error;
  final bool isRefreshing;

  StatsState copyWith({
    LoadStatus? status,
    MarketStats? stats,
    String? error,
    bool? isRefreshing,
    bool clearError = false,
  }) =>
      StatsState(
        status: status ?? this.status,
        stats: stats ?? this.stats,
        error: clearError ? null : (error ?? this.error),
        isRefreshing: isRefreshing ?? this.isRefreshing,
      );

  @override
  List<Object?> get props => [status, stats, error, isRefreshing];
}
