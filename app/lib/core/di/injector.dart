import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/datasources/cache_local_data_source.dart';
import '../../data/datasources/coin_remote_data_source.dart';
import '../../data/datasources/watchlist_local_data_source.dart';
import '../../data/models/coin.dart';
import '../../data/repositories/coin_repository_impl.dart';
import '../../data/repositories/watchlist_repository_impl.dart';
import '../../domain/repositories/coin_repository.dart';
import '../../domain/repositories/watchlist_repository.dart';
import '../../presentation/blocs/coin_detail/coin_detail_bloc.dart';
import '../../presentation/blocs/market/market_bloc.dart';
import '../../presentation/blocs/stats/stats_bloc.dart';
import '../../presentation/blocs/watchlist/watchlist_bloc.dart';
import '../network/api_client.dart';
import '../storage/hive_boxes.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final watchlistBox = await Hive.openBox<dynamic>(HiveBoxes.watchlist);
  final cacheBox = await Hive.openBox<String>(HiveBoxes.cache);

  getIt
    // core / data
    ..registerLazySingleton<ApiClient>(ApiClient.new)
    ..registerLazySingleton<CoinRemoteDataSource>(() => CoinRemoteDataSource(getIt()))
    ..registerLazySingleton<WatchlistLocalDataSource>(
        () => WatchlistLocalDataSource(watchlistBox))
    ..registerLazySingleton<CacheLocalDataSource>(() => CacheLocalDataSource(cacheBox))
    ..registerLazySingleton<CoinRepository>(() => CoinRepositoryImpl(getIt(), getIt()))
    ..registerLazySingleton<WatchlistRepository>(() => WatchlistRepositoryImpl(getIt()))
    // view-models (BLoCs)
    ..registerLazySingleton<WatchlistBloc>(() => WatchlistBloc(getIt(), getIt()))
    ..registerFactory<MarketBloc>(() => MarketBloc(getIt()))
    ..registerFactory<StatsBloc>(() => StatsBloc(getIt()))
    ..registerFactoryParam<CoinDetailBloc, Coin, void>(
      (coin, _) => CoinDetailBloc(getIt(), coin!),
    );
}
