abstract class WatchlistRepository {
  Future<List<String>> getIds();
  Future<void> saveIds(List<String> ids);
}
