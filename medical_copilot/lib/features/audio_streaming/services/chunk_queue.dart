import 'dart:async';

import '../../../core/storage/chunk_queue_store.dart';
import '../models/audio_chunk.dart';

class ChunkQueue {
  ChunkQueue(this._store);

  final ChunkQueueStore _store;

  final _pendingController = StreamController<List<AudioChunk>>.broadcast();

  Stream<List<AudioChunk>> get pendingStream => _pendingController.stream;

  Future<void> enqueue(AudioChunk chunk) async {
    await _store.insertChunk(chunk);
    await _emitPending();
  }

  Future<List<AudioChunk>> getPending({int limit = 20}) async {
    return _store.getPendingChunks(limit: limit);
  }

  Future<void> markUploaded(AudioChunk chunk) async {
    if (chunk.id == null) return;
    await _store.markUploaded(chunk.id!);
    await _emitPending();
  }

  Future<void> _emitPending() async {
    final list = await getPending();
    _pendingController.add(list);
  }
}
