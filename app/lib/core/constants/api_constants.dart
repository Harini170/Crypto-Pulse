import 'package:flutter/foundation.dart';

/// Central place for network + app-wide tuning constants.
class ApiConstants {
  ApiConstants._();

  static const String _override = String.fromEnvironment('API_BASE_URL');

  /// Android emulator reaches the host machine through 10.0.2.2.
  /// Real device: `--dart-define=API_BASE_URL=http://<your-pc-ip>:3000/api`
  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration refreshInterval = Duration(seconds: 15);
  static const int pageSize = 20;
  static const int maxPageSize = 250;
}
