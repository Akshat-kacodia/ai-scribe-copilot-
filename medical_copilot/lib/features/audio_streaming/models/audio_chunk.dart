class AudioChunk {
  AudioChunk({
    this.id,
    required this.sessionId,
    required this.chunkNumber,
    required this.checksum,
    required this.filePath,
    required this.mimeType,
    required this.isLast,
    required this.createdAt,
    this.uploaded = false,
  });

  final int? id;
  final String sessionId;
  final int chunkNumber;
  final String checksum;
  final String filePath;
  final String mimeType;
  final bool isLast;
  final DateTime createdAt;
  final bool uploaded;

  AudioChunk copyWith({
    int? id,
    bool? uploaded,
  }) {
    return AudioChunk(
      id: id ?? this.id,
      sessionId: sessionId,
      chunkNumber: chunkNumber,
      checksum: checksum,
      filePath: filePath,
      mimeType: mimeType,
      isLast: isLast,
      createdAt: createdAt,
      uploaded: uploaded ?? this.uploaded,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'chunk_number': chunkNumber,
      'checksum': checksum,
      'file_path': filePath,
      'mime_type': mimeType,
      'is_last': isLast ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'uploaded': uploaded ? 1 : 0,
    };
  }

  static AudioChunk fromMap(Map<String, dynamic> map) {
    return AudioChunk(
      id: map['id'] as int?,
      sessionId: map['session_id'] as String,
      chunkNumber: map['chunk_number'] as int,
      checksum: map['checksum'] as String,
      filePath: map['file_path'] as String,
      mimeType: map['mime_type'] as String,
      isLast: (map['is_last'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      uploaded: (map['uploaded'] as int) == 1,
    );
  }
}
