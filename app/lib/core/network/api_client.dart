import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../error/app_exception.dart';

/// Thin Dio wrapper: one place for base URL, timeouts and error mapping.
class ApiClient {
  ApiClient()
      : _dio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: ApiConstants.connectTimeout,
            receiveTimeout: ApiConstants.receiveTimeout,
            headers: {'accept': 'application/json'},
          ),
        );

  final Dio _dio;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(path, queryParameters: query);
      final data = res.data;
      if (data == null) {
        throw const AppException('Empty response from server', ErrorKind.parse);
      }
      return data;
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  AppException _map(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppException(
            'The request timed out. Please try again.', ErrorKind.timeout);
      case DioExceptionType.connectionError:
        return const AppException(
            'Cannot reach the server. Check your connection and make sure the backend is running.',
            ErrorKind.network);
      case DioExceptionType.badResponse:
        final body = e.response?.data;
        final msg = body is Map ? body['message']?.toString() : null;
        return AppException(
            msg ?? 'Server error (${e.response?.statusCode})', ErrorKind.server);
      default:
        return AppException(e.message ?? 'Something went wrong', ErrorKind.unknown);
    }
  }
}
