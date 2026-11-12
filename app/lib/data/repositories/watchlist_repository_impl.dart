import '../../domain/repositories/watchlist_repository.dart';
import '../datasources/watchlist_local_data_source.dart';

class WatchlistRepositoryImpl implements WatchlistRepository {
  WatchlistRepositoryImpl(this._local);
  final WatchlistLocalDataSource _local;

  @override
  Future<List<String>> getIds() async => _local.read();

  @override
  Future<void> saveIds(List<String> ids) => _local.write(ids);
}
