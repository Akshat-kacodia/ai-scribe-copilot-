import '../../../core/storage/chunk_queue_store.dart';
import 'chunk_queue.dart';

class SessionRecoveryManager {
  SessionRecoveryManager(this._queueStore);

  final ChunkQueueStore _queueStore;

  Future<ChunkQueue> buildQueue() async {
    // Simply returns a ChunkQueue using the existing store; the caller can then
    // use drainQueue() on a ChunkUploader to recover unsent chunks.
    return ChunkQueue(_queueStore);
  }
}
