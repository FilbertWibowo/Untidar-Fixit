import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'endpoints.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  String? _authToken;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: Endpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.baseUrl = Endpoints.baseUrl;
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          } else {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('auth_token');
            if (token != null) {
              _authToken = token;
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Extract message from server response if available
          String message = 'Terjadi kesalahan jaringan atau server.';
          if (e.response?.data is Map && e.response?.data['message'] != null) {
            message = e.response!.data['message'].toString();
          }
          final customError = DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            type: e.type,
            error: message,
          );
          return handler.next(customError);
        },
      ),
    );
  }

  void setToken(String? token) {
    _authToken = token;
  }
}
