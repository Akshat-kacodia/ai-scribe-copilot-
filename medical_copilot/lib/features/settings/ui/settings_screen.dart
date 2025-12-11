import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final authToken = ref.watch(authTokenProvider);
    final userEmail = ref.watch(userEmailProvider);
    final userIdAsync = ref.watch(userIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('settings_title')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(loc.translate('theme'),
              style: Theme.of(context).textTheme.titleMedium),
          RadioListTile<ThemeMode>(
            title: Text(loc.translate('theme_system')),
            value: ThemeMode.system,
            groupValue: themeMode,
            onChanged: (value) {
              if (value != null) {
                ref.read(themeModeProvider.notifier).setThemeMode(value);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: Text(loc.translate('theme_light')),
            value: ThemeMode.light,
            groupValue: themeMode,
            onChanged: (value) {
              if (value != null) {
                ref.read(themeModeProvider.notifier).setThemeMode(value);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: Text(loc.translate('theme_dark')),
            value: ThemeMode.dark,
            groupValue: themeMode,
            onChanged: (value) {
              if (value != null) {
                ref.read(themeModeProvider.notifier).setThemeMode(value);
              }
            },
          ),
          const Divider(),
          Text(loc.translate('language'),
              style: Theme.of(context).textTheme.titleMedium),
          RadioListTile<String>(
            title: Text(loc.translate('language_english')),
            value: 'en',
            groupValue: locale.languageCode,
            onChanged: (value) {
              if (value != null) {
                ref
                    .read(localeProvider.notifier)
                    .setLocale(Locale(value));
              }
            },
          ),
          RadioListTile<String>(
            title: Text(loc.translate('language_hindi')),
            value: 'hi',
            groupValue: locale.languageCode,
            onChanged: (value) {
              if (value != null) {
                ref
                    .read(localeProvider.notifier)
                    .setLocale(Locale(value));
              }
            },
          ),
          const Divider(),
          Text('Backend Configuration',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FutureBuilder<SharedPreferences>(
            future: SharedPreferences.getInstance(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final prefs = snapshot.data!;
              final apiUrl = prefs.getString('api_base_url') ?? '';
              final backendUrl = prefs.getString('backend_base_url') ?? '';
              
              // Get current effective URL
              final effectiveUrl = apiUrl.isNotEmpty 
                  ? apiUrl 
                  : (Platform.isAndroid 
                      ? 'http://10.0.2.2:3000/api' 
                      : 'http://localhost:3000/api');
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current URL display
                  Card(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Backend URL:',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            effectiveUrl,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          // Test connection button
                          _TestConnectionButton(
                            url: effectiveUrl,
                            authToken: authToken ?? '',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Help text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Quick Setup',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '1. Start backend: cd backend && npm run dev\n'
                          '2. For Android emulator: Leave URL empty (uses 10.0.2.2:3000)\n'
                          '3. For physical device: Use your computer IP (e.g., http://192.168.1.100:3000/api)\n'
                          '4. Click "Test Connection" to verify',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: apiUrl.isEmpty ? null : apiUrl,
                    decoration: const InputDecoration(
                      labelText: 'API Base URL (optional)',
                      border: OutlineInputBorder(),
                      hintText: 'https://your-backend.com/api',
                      helperText: 'Leave empty for localhost (10.0.2.2:3000 for Android emulator)',
                    ),
                    onChanged: (value) async {
                      if (value.trim().isEmpty) {
                        await prefs.remove('api_base_url');
                      } else {
                        await prefs.setString('api_base_url', value.trim());
                      }
                      // Invalidate API client to reload with new URL
                      ref.invalidate(apiClientProvider);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: backendUrl.isEmpty ? null : backendUrl,
                    decoration: const InputDecoration(
                      labelText: 'Backend Base URL (optional)',
                      border: OutlineInputBorder(),
                      hintText: 'https://your-backend.com/api',
                      helperText: 'Leave empty to use API Base URL',
                    ),
                    onChanged: (value) async {
                      if (value.trim().isEmpty) {
                        await prefs.remove('backend_base_url');
                      } else {
                        await prefs.setString('backend_base_url', value.trim());
                      }
                      ref.invalidate(apiClientProvider);
                    },
                  ),
                ],
              );
            },
          ),
          const Divider(),
          Text('Authentication',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: authToken,
            decoration: const InputDecoration(
              labelText: 'Auth Token',
              border: OutlineInputBorder(),
              hintText: 'Bearer token (any token works with mock backend)',
            ),
            obscureText: true,
            onChanged: (value) async {
              await ref.read(authTokenProvider.notifier).setToken(value.trim());
              // Invalidate userId to trigger re-resolution with new token
              ref.invalidate(userIdProvider);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: userEmail,
            decoration: const InputDecoration(
              labelText: 'User Email',
              border: OutlineInputBorder(),
              hintText: 'user@example.com',
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) async {
              await ref.read(userEmailProvider.notifier).setEmail(value.trim());
              // Invalidate userId to trigger re-resolution
              ref.invalidate(userIdProvider);
            },
          ),
          const SizedBox(height: 8),
          userIdAsync.when(
            data: (userId) => Text(
              userId != null ? 'User ID: $userId' : 'User ID: Not resolved',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: userId != null ? Colors.green : Colors.orange,
              ),
            ),
            loading: () => const Text('Resolving user ID...', style: TextStyle(color: Colors.grey)),
            error: (e, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error resolving User ID',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
                ),
                const SizedBox(height: 4),
                Text(
                  e.toString().replaceAll('Exception: ', ''),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TestConnectionButton extends StatefulWidget {
  const _TestConnectionButton({
    required this.url,
    required this.authToken,
  });

  final String url;
  final String authToken;

  @override
  State<_TestConnectionButton> createState() => _TestConnectionButtonState();
}

class _TestConnectionButtonState extends State<_TestConnectionButton> {
  bool _testing = false;
  String? _result;
  bool? _success;

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _result = null;
      _success = null;
    });

    try {
      final dio = Dio(BaseOptions(
        baseUrl: widget.url,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));

      if (widget.authToken.isNotEmpty) {
        dio.options.headers['Authorization'] = 'Bearer ${widget.authToken}';
      }

      // Try health check endpoint (doesn't require auth)
      final healthUrl = '${widget.url.replaceAll('/api', '')}/health';
      final response = await dio.get(healthUrl);

      setState(() {
        _success = response.statusCode == 200;
        _result = _success! 
            ? '✓ Connection successful! Backend is reachable.'
            : '✗ Unexpected response: ${response.statusCode}';
      });
    } on DioException catch (e) {
      setState(() {
        _success = false;
        if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout) {
          _result = '✗ Cannot reach backend. Check:\n'
              '• Backend is running (npm run dev)\n'
              '• Correct URL/IP address\n'
              '• Device and computer on same network';
        } else if (e.type == DioExceptionType.receiveTimeout) {
          _result = '✗ Connection timeout. Backend may be slow or unreachable.';
        } else {
          _result = '✗ Error: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        _success = false;
        _result = '✗ Unexpected error: $e';
      });
    } finally {
      setState(() {
        _testing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _testing ? null : _testConnection,
            icon: _testing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.network_check),
            label: Text(_testing ? 'Testing...' : 'Test Connection'),
          ),
        ),
        if (_result != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _success == true
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _success == true ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _success == true ? Icons.check_circle : Icons.error_outline,
                  color: _success == true ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _result!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _success == true ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
