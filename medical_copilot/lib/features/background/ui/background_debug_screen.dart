import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/native/audio_native_channel.dart';

class BackgroundDebugScreen extends StatelessWidget {
  const BackgroundDebugScreen({super.key});

  static const routeName = '/background-debug';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('background_debug_title')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () async {
                await AudioNativeChannel.instance.startForegroundService();
              },
              child: Text(loc.translate('background_service_start')),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await AudioNativeChannel.instance.stopForegroundService();
              },
              child: Text(loc.translate('background_service_stop')),
            ),
            const SizedBox(height: 24),
            const Text(
              'Use this screen to manually start/stop the Android foreground '
              'service and verify that notifications with actions appear while '
              'the app is in the background or the phone is locked.',
            ),
          ],
        ),
      ),
    );
  }
}
