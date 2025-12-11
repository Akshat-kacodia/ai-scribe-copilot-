import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dio client configured to use the local mock backend by default.
///
/// Default URLs (for local development):
/// - Base URL: http://localhost:3000/api (or http://10.0.2.2:3000/api for Android emulator)
/// - Backend URL: Same as base URL
///
/// For deployed backend, configure URLs via SharedPreferences:
/// - 'api_base_url' for the main API base URL
/// - 'backend_base_url' for the user ID resolution endpoint
///
/// The URLs in the API documentation are reference examples only.
/// You need to deploy your own backend (see backend/README.md).
class DioClient {
  DioClient({String? authToken, String? baseUrl, String? backendBaseUrl})
      : _baseUrl = baseUrl ?? _getDefaultBaseUrl(),
        _backendBaseUrl = backendBaseUrl ?? _getDefaultBaseUrl(),
        _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? _getDefaultBaseUrl(),
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 60),
          ),
        ) {
    this.authToken = authToken;
  }

  /// Get default base URL based on platform
  /// - Android emulator: 10.0.2.2 maps to host machine's localhost
  /// - iOS simulator: localhost works directly
  /// - Physical device: Use your machine's LAN IP (e.g., 192.168.x.x:3000)
  static String _getDefaultBaseUrl() {
    if (Platform.isAndroid) {
      // Android emulator - 10.0.2.2 maps to host machine's localhost
      return 'http://10.0.2.2:3000/api';
    } else if (Platform.isIOS) {
      // iOS simulator - localhost works directly
      return 'http://localhost:3000/api';
    } else {
      // Desktop or other platforms
      return 'http://localhost:3000/api';
    }
  }

  final Dio _dio;
  String? _authToken;
  final String _baseUrl;
  final String _backendBaseUrl;

  /// Backend base URL used for the `/users/asd3fd2faec` identity resolution endpoint.
  String get backendBaseUrl => _backendBaseUrl;

  /// Main API base URL.
  String get baseUrl => _baseUrl;
  
  /// Get current auth token.
  String? get authToken => _authToken;

  /// Load configuration from SharedPreferences and create a new instance.
  /// If no custom URLs are set, uses default localhost URLs.
  static Future<DioClient> fromPreferences({String? authToken}) async {
    final prefs = await SharedPreferences.getInstance();
    final customBaseUrl = prefs.getString('api_base_url');
    final customBackendUrl = prefs.getString('backend_base_url');
    return DioClient(
      authToken: authToken,
      baseUrl: customBaseUrl?.isNotEmpty == true ? customBaseUrl : null,
      backendBaseUrl: customBackendUrl?.isNotEmpty == true ? customBackendUrl : null,
    );
  }

  set authToken(String? token) {
    _authToken = token;
    _dio.interceptors.clear();
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null && _authToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          return handler.next(options);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
