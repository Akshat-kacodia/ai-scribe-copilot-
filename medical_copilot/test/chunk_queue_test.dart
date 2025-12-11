import 'package:flutter_test/flutter_test.dart';

import 'package:medical_copilot/features/audio_streaming/models/audio_chunk.dart';

class InMemoryChunkQueue {
  final _items = <AudioChunk>[];

  Future<void> enqueue(AudioChunk chunk) async {
    _items.add(chunk);
  }

  Future<List<AudioChunk>> getPending() async {
    _items.sort((a, b) {
      final cmp = a.createdAt.compareTo(b.createdAt);
      if (cmp != 0) return cmp;
      return a.chunkNumber.compareTo(b.chunkNumber);
    });
    return List.unmodifiable(_items);
  }
}

void main() {
  test('ChunkQueue enqueues and returns pending chunks in order', () async {
    final queue = InMemoryChunkQueue();

    final now = DateTime.now().toUtc();
    final chunk1 = AudioChunk(
      sessionId: 'session_1',
      chunkNumber: 1,
      checksum: 'checksum1',
      filePath: '/tmp/chunk1.pcm',
      mimeType: 'audio/wav',
      isLast: false,
      createdAt: now,
    );
    final chunk2 = AudioChunk(
      sessionId: 'session_1',
      chunkNumber: 2,
      checksum: 'checksum2',
      filePath: '/tmp/chunk2.pcm',
      mimeType: 'audio/wav',
      isLast: false,
      createdAt: now.add(const Duration(seconds: 1)),
    );

    await queue.enqueue(chunk2);
    await queue.enqueue(chunk1);

    final pending = await queue.getPending();
    expect(pending.length, 2);
    expect(pending[0].chunkNumber, 1);
    expect(pending[1].chunkNumber, 2);
  });
}
