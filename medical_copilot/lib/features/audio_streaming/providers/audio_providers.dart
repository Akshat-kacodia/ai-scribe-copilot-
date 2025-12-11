import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/upload_session.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/storage/chunk_queue_store.dart';
import '../../recording/providers/recording_providers.dart';
import '../models/audio_chunk.dart';
import '../providers/session_metadata_provider.dart';
import '../services/chunk_queue.dart';
import '../services/chunk_uploader.dart';
import '../services/recording_engine.dart';

final recordingEngineProvider = Provider<RecordingEngine>((ref) {
  final engine = RecordingEngine();
  ref.onDispose(engine.dispose);
  return engine;
});

final chunkQueueStoreProvider = FutureProvider<ChunkQueueStore>((ref) async {
  return ChunkQueueStore.open();
});

final chunkQueueProvider = FutureProvider<ChunkQueue>((ref) async {
  final store = await ref.watch(chunkQueueStoreProvider.future);
  return ChunkQueue(store);
});

final chunkUploaderProvider = FutureProvider<ChunkUploader>((ref) async {
  final api = await ref.watch(apiClientProvider.future);
  final queue = await ref.watch(chunkQueueProvider.future);
  final connectivity = Connectivity();
  final uploader = ChunkUploader(
    apiClient: api,
    queue: queue,
    connectivity: connectivity,
    ref: ref,
  );
  // Kick off an initial drain attempt.
  uploader.drainQueue();
  return uploader;
});

enum RecordingStatus { idle, recording, paused }

class RecordingController extends StateNotifier<RecordingStatus> {
  RecordingController({
    required this.engine,
    required this.ref,
  }) : super(RecordingStatus.idle);

  final RecordingEngine engine;
  final Ref ref;

  String? _sessionId;

  double _gain = 1.0;

  double get gain => _gain;

  StreamSubscription<AudioChunk>? _chunkSubscription;

  Future<void> startNewSession() async {
    if (state == RecordingStatus.recording) return;
    
    try {
      // Get selected patient and template from providers
      final selectedPatient = ref.read(selectedPatientProvider);
      final selectedTemplate = ref.read(selectedTemplateProvider);
      final userIdAsync = await ref.read(userIdProvider.future);
      
      if (selectedPatient == null) {
        throw Exception('Please select a patient before starting recording');
      }
      
      if (selectedTemplate == null) {
        throw Exception('Please select a template before starting recording');
      }
      
      if (userIdAsync == null) {
        throw Exception('User ID not available. Please set your email in settings.');
      }

      final api = await ref.read(apiClientProvider.future);
      final request = UploadSessionRequest(
        patientId: selectedPatient.id,
        userId: userIdAsync,
        patientName: selectedPatient.name,
        status: 'recording',
        startTime: DateTime.now().toUtc().toIso8601String(),
        templateId: selectedTemplate.id,
      );
      final response = await api.createUploadSession(request);
      _sessionId = response.id;

      // Store session metadata for later use in chunk uploads
      final metadataMap = ref.read(sessionMetadataProvider.notifier);
      metadataMap.state = {
        ...metadataMap.state,
        _sessionId!: SessionMetadata(
          sessionId: _sessionId!,
          templateId: selectedTemplate.id,
          templateTitle: selectedTemplate.title,
        ),
      };

      await engine.start(sessionId: _sessionId!);

      // Cancel any existing subscription
      await _chunkSubscription?.cancel();
      
      // Set up chunk stream listener with error handling
      final queue = await ref.read(chunkQueueProvider.future);
      _chunkSubscription = engine.chunkStream.listen(
        (chunk) async {
          try {
            await queue.enqueue(chunk);
            final uploader = await ref.read(chunkUploaderProvider.future);
            await uploader.drainQueue();
          } catch (e) {
            // Log error but don't crash - chunks will be retried later
            debugPrint('Error processing chunk: $e');
          }
        },
        onError: (error) {
          // Handle stream errors gracefully
          debugPrint('Chunk stream error: $error');
        },
      );

      state = RecordingStatus.recording;
    } catch (e) {
      // Reset state on error
      _sessionId = null;
      state = RecordingStatus.idle;
      rethrow;
    }
  }

  Future<void> pause() async {
    if (state != RecordingStatus.recording) return;
    await engine.pause();
    state = RecordingStatus.paused;
  }

  Future<void> resume() async {
    if (state != RecordingStatus.paused) return;
    await engine.resume();
    state = RecordingStatus.recording;
  }

  Future<void> stop() async {
    if (state == RecordingStatus.idle) return;
    await _chunkSubscription?.cancel();
    _chunkSubscription = null;
    await engine.stop();
    state = RecordingStatus.idle;
  }
  
  @override
  void dispose() {
    _chunkSubscription?.cancel();
    super.dispose();
  }

  void setGain(double value) {
    _gain = value;
    engine.setGain(value);
  }
}

final recordingControllerProvider =
    StateNotifierProvider<RecordingController, RecordingStatus>((ref) {
  final engine = ref.watch(recordingEngineProvider);
  return RecordingController(engine: engine, ref: ref);
});

final micLevelProvider = StreamProvider<double>((ref) {
  final engine = ref.watch(recordingEngineProvider);
  return engine.levelStream;
});

final gainProvider = StateProvider<double>((ref) => 1.0);
