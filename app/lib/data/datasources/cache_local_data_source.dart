import 'dart:convert';

import 'package:hive/hive.dart';

/// Tiny JSON cache on top of Hive, used for offline fallback.
class CacheLocalDataSource {
  CacheLocalDataSource(this._box);
  final Box<String> _box;

  Future<void> saveJson(String key, Map<String, dynamic> json) =>
      _box.put(key, jsonEncode(json));

  Map<String, dynamic>? readJson(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null; // corrupted entry -> behave as cache miss
    }
  }
}
