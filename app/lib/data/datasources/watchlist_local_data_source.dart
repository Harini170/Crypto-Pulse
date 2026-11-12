import 'package:hive/hive.dart';

/// Persists the watchlist ids in a Hive box.
class WatchlistLocalDataSource {
  WatchlistLocalDataSource(this._box);
  final Box<dynamic> _box;

  static const _key = 'ids';

  List<String> read() {
    final raw = _box.get(_key);
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return const [];
  }

  Future<void> write(List<String> ids) => _box.put(_key, ids);
}
