part of 'stats_bloc.dart';

sealed class StatsEvent extends Equatable {
  const StatsEvent();
  @override
  List<Object?> get props => [];
}

final class StatsStarted extends StatsEvent {
  const StatsStarted();
}

final class StatsRefreshed extends StatsEvent {
  const StatsRefreshed();
}

final class StatsTicked extends StatsEvent {
  const StatsTicked();
}
