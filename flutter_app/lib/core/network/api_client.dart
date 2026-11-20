import 'package:dio/dio.dart';

class TalkoraApiClient {
  final Dio _dio;
  String? _authToken;

  TalkoraApiClient(String baseUrl)
      : _dio = Dio(
          BaseOptions(
            baseUrl: '$baseUrl/api/v1',
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 15),
          ),
        );

  void setToken(String token) {
    _authToken = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  String? get token => _authToken;

  Future<Map<String, dynamic>> evaluatePronunciation({
    required String targetText,
    required String spokenText,
    String accent = 'American',
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/pronunciation/evaluate',
      data: {
        'target_text': targetText,
        'spoken_text': spokenText,
        'accent': accent,
      },
    );
    return res.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> exportMemoryHistory() async {
    final res = await _dio.get<Map<String, dynamic>>('/memory/export');
    return res.data ?? <String, dynamic>{};
  }
}
