import 'package:dio/dio.dart';
import 'auth_service.dart';

/// One shared Dio instance for the whole app. The interceptor attaches the
/// Basic Auth header to every request, and the base URL is read fresh from
/// secure storage on each call (it can only change from the login screen,
/// which always creates a fresh ApiClient after saving new credentials).
class ApiClient {
  ApiClient._(this._dio);
  static ApiClient? _instance;

  final Dio _dio;

  static Future<ApiClient> create() async {
    final serverUrl = await AuthService.instance.getServerUrl();
    final dio = Dio(BaseOptions(
      baseUrl: serverUrl ?? '',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      validateStatus: (status) => status != null && status < 500,
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final auth = await AuthService.instance.basicAuthHeader();
        if (auth != null) options.headers['Authorization'] = auth;
        handler.next(options);
      },
    ));

    _instance = ApiClient._(dio);
    return _instance!;
  }

  static ApiClient get instance {
    if (_instance == null) {
      throw StateError('ApiClient.create() must be called after login, before use.');
    }
    return _instance!;
  }

  Dio get dio => _dio;
}
