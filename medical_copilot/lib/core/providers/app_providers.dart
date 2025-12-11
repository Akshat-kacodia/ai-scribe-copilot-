import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';

const _prefKeyThemeMode = 'theme_mode';
const _prefKeyLanguageCode = 'language_code';
const _prefKeyAuthToken = 'auth_token';
const _prefKeyUserEmail = 'user_email';

class AuthTokenNotifier extends StateNotifier<String?> {
  AuthTokenNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_prefKeyAuthToken);
    if (token != null && token.isNotEmpty) {
      state = token;
    }
  }

  Future<void> setToken(String token) async {
    state = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyAuthToken, token);
  }
}

final authTokenProvider = StateNotifierProvider<AuthTokenNotifier, String?>((ref) {
  return AuthTokenNotifier();
});

class UserEmailNotifier extends StateNotifier<String?> {
  UserEmailNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_prefKeyUserEmail);
    if (email != null && email.isNotEmpty) {
      state = email;
    }
  }

  Future<void> setEmail(String email) async {
    state = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyUserEmail, email);
  }
}

final userEmailProvider = StateNotifierProvider<UserEmailNotifier, String?>((ref) {
  return UserEmailNotifier();
});

final apiClientProvider = FutureProvider<ApiClient>((ref) async {
  final token = ref.watch(authTokenProvider);
  // Load custom URLs from SharedPreferences if set, otherwise use defaults
  final prefs = await SharedPreferences.getInstance();
  final customBaseUrl = prefs.getString('api_base_url');
  final customBackendUrl = prefs.getString('backend_base_url');
  
  // If backend URL is not set, use the same as base URL (they should be the same)
  final effectiveBackendUrl = customBackendUrl?.isNotEmpty == true 
      ? customBackendUrl 
      : customBaseUrl;
  
  // Override with custom URLs if provided
  if (customBaseUrl?.isNotEmpty == true || customBackendUrl?.isNotEmpty == true) {
    return ApiClient(
      authToken: token,
      baseUrl: customBaseUrl?.isNotEmpty == true ? customBaseUrl : null,
      backendBaseUrl: effectiveBackendUrl?.isNotEmpty == true ? effectiveBackendUrl : null,
    );
  }
  
  // Use default DioClient (localhost)
  return ApiClient(authToken: token);
});

/// Provider that resolves userId from email
final userIdProvider = FutureProvider<String?>((ref) async {
  final email = ref.watch(userEmailProvider);
  final token = ref.watch(authTokenProvider);
  
  if (email == null || email.isEmpty) return null;
  if (token == null || token.isEmpty) {
    // Auth token is required for user ID resolution
    throw Exception('Auth token is required. Please enter an auth token in settings.');
  }
  
  try {
    final api = await ref.watch(apiClientProvider.future);
    final userId = await api.getUserIdByEmail(email);
    return userId;
  } catch (e) {
    // Re-throw with more context for debugging
    throw Exception('Failed to resolve user ID: $e');
  }
});

/// Save auth token to SharedPreferences
Future<void> saveAuthToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_prefKeyAuthToken, token);
}

/// Save user email to SharedPreferences
Future<void> saveUserEmail(String email) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_prefKeyUserEmail, email);
}

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_prefKeyThemeMode);
    switch (value) {
      case 'light':
        state = ThemeMode.light;
        break;
      case 'dark':
        state = ThemeMode.dark;
        break;
      case 'system':
      default:
        state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_prefKeyThemeMode, value);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKeyLanguageCode);
    if (code != null && code.isNotEmpty) {
      state = Locale(code);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyLanguageCode, locale.languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});
