import 'dart:async';

import 'package:flutter/services.dart';

class AudioNativeChannel {
  AudioNativeChannel._() {
    _channel.setMethodCallHandler(_onMethodCall);
  }

  static final AudioNativeChannel instance = AudioNativeChannel._();

  static const _channel = MethodChannel('medical_copilot/audio_native');

  final _interruptionController = StreamController<String>.broadcast();

  Stream<String> get interruptionStream => _interruptionController.stream;

  Future<void> setGain(double gain) async {
    await _channel.invokeMethod('setGain', {'gain': gain});
  }

  Future<void> startForegroundService() async {
    await _channel.invokeMethod('startForegroundService');
  }

  Future<void> stopForegroundService() async {
    await _channel.invokeMethod('stopForegroundService');
  }

  Future<void> _onMethodCall(MethodCall call) async {
    if (call.method == 'onAudioInterruption') {
      final reason = call.arguments as String? ?? 'unknown';
      _interruptionController.add(reason);
    }
  }
}
