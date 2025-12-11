import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/audio_streaming/models/audio_chunk.dart';

class ChunkQueueStore {
  ChunkQueueStore._(this._db);

  static const _dbName = 'chunk_queue.db';
  static const _tableName = 'audio_chunks';

  final Database _db;

  static Future<ChunkQueueStore> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE $_tableName (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id TEXT NOT NULL,
  chunk_number INTEGER NOT NULL,
  checksum TEXT NOT NULL,
  file_path TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  is_last INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  uploaded INTEGER NOT NULL DEFAULT 0
);
''');
      },
    );
    return ChunkQueueStore._(db);
  }

  Future<int> insertChunk(AudioChunk chunk) async {
    return _db.insert(_tableName, chunk.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<AudioChunk>> getPendingChunks({int limit = 20}) async {
    final rows = await _db.query(
      _tableName,
      where: 'uploaded = ?',
      whereArgs: [0],
      orderBy: 'created_at ASC, chunk_number ASC',
      limit: limit,
    );
    return rows.map(AudioChunk.fromMap).toList();
  }

  Future<void> markUploaded(int id) async {
    await _db.update(
      _tableName,
      {'uploaded': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteUploadedOlderThan(DateTime cutoff) async {
    await _db.delete(
      _tableName,
      where: 'uploaded = 1 AND created_at < ?',
      whereArgs: [cutoff.toIso8601String()],
    );
  }
}
