import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../models/audio_chunk.dart';

class RecordingEngine {
  RecordingEngine();

  final AudioRecorder _recorder = AudioRecorder();

  final _levelController = StreamController<double>.broadcast();
  final _chunkController = StreamController<AudioChunk>.broadcast();

  Stream<double> get levelStream => _levelController.stream;
  Stream<AudioChunk> get chunkStream => _chunkController.stream;

  bool _isRecording = false;
  String? _sessionId;
  int _chunkNumber = 0;
  double _gain = 1.0; // Linear gain multiplier
  BytesBuilder? _buffer; // Make buffer accessible to stop() method

  Future<void> start({required String sessionId}) async {
    if (_isRecording) return;

    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        throw const RecordingPermissionException('Microphone permission not granted');
      }

      _sessionId = sessionId;
      _chunkNumber = 0;
      _isRecording = true;

      final config = const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 128000,
      );

      final stream = await _recorder.startStream(config);

      _buffer = BytesBuilder(copy: false);
      const targetChunkSizeBytes = 16000 * 2; // ~1 second of 16-bit mono audio

      stream.listen((data) async {
        if (!_isRecording) return;
        if (data.isEmpty) return;
        if (_buffer == null) return;

        // Update mic level from current frame
        _updateLevel(data);

        // Apply simple gain
        final gained = _applyGain(data, _gain);

        _buffer!.add(gained);

        if (_buffer!.length >= targetChunkSizeBytes) {
          try {
            final bytes = _buffer!.toBytes();
            _buffer!.clear();
            await _emitChunk(bytes, isLast: false);
          } catch (e) {
            // Log error but continue recording
            debugPrint('Error emitting chunk: $e');
          }
        }
      }, onDone: () {
        // Stream ended - emit remaining buffer as last chunk
        if (_isRecording && _buffer != null && _buffer!.length > 0) {
          final bytes = _buffer!.toBytes();
          _buffer!.clear();
          _emitChunk(bytes, isLast: true);
        }
      }, onError: (error) {
        // Handle stream errors gracefully
        _isRecording = false;
        _chunkController.addError(error);
      });
    } catch (e) {
      // Reset state on error
      _isRecording = false;
      _sessionId = null;
      rethrow;
    }
  }

  Future<void> pause() async {
    if (!_isRecording) return;
    await _recorder.pause();
  }

  Future<void> resume() async {
    if (!_isRecording) return;
    await _recorder.resume();
  }

  Future<void> stop({bool emitRemainderAsLast = true}) async {
    if (!_isRecording) return;
    _isRecording = false;
    
    // Emit any remaining buffered data as the last chunk
    if (emitRemainderAsLast && _buffer != null && _buffer!.length > 0) {
      final bytes = _buffer!.toBytes();
      _buffer!.clear();
      await _emitChunk(bytes, isLast: true);
    } else if (emitRemainderAsLast && _chunkNumber > 0) {
      // If no buffered data but we have chunks, emit empty last chunk to signal end
      await _emitChunk([], isLast: true);
    }
    
    await _recorder.stop();
    _buffer = null;
  }

  Future<void> dispose() async {
    await _recorder.dispose();
    await _levelController.close();
    await _chunkController.close();
  }

  void setGain(double gain) {
    _gain = gain.clamp(0.0, 4.0);
  }

  void _updateLevel(Uint8List frame) {
    if (frame.isEmpty) return;
    final samples = frame.buffer.asInt16List();
    double sumSquares = 0;
    for (var i = 0; i < samples.length; i++) {
      final s = samples[i].toDouble();
      sumSquares += s * s;
    }
    final rms = math.sqrt(sumSquares / samples.length);
    const maxInt16 = 32768.0;
    final db = 20 * math.log(rms / maxInt16) / math.ln10;
    // Normalize roughly to 0..1 range for UI visualization
    final normalized = ((db + 60) / 60).clamp(0.0, 1.0);
    _levelController.add(normalized);
  }

  Uint8List _applyGain(Uint8List data, double gain) {
    if (gain == 1.0) return data;
    final samples = data.buffer.asInt16List();
    for (var i = 0; i < samples.length; i++) {
      final v = (samples[i] * gain).round();
      samples[i] = v.clamp(-32768, 32767);
    }
    return data;
  }

  Future<void> _emitChunk(List<int> bytes, {required bool isLast}) async {
    final sessionId = _sessionId;
    if (sessionId == null) return;

    _chunkNumber += 1;
    final checksum = md5.convert(bytes).toString();
    final dir = await getApplicationDocumentsDirectory();
    final filePath = p.join(
      dir.path,
      'session_${sessionId}_chunk_$_chunkNumber.pcm',
    );

    final file = await File(filePath).create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);

    final chunk = AudioChunk(
      sessionId: sessionId,
      chunkNumber: _chunkNumber,
      checksum: checksum,
      filePath: filePath,
      mimeType: 'audio/wav',
      isLast: isLast,
      createdAt: DateTime.now().toUtc(),
    );

    _chunkController.add(chunk);
  }
}

class RecordingPermissionException implements Exception {
  const RecordingPermissionException(this.message);

  final String message;

  @override
  String toString() => 'RecordingPermissionException: $message';
}
