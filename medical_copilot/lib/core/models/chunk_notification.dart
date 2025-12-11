class ChunkNotification {
  ChunkNotification({
    required this.sessionId,
    required this.gcsPath,
    required this.chunkNumber,
    required this.isLast,
    required this.totalChunksClient,
    required this.publicUrl,
    required this.mimeType,
    required this.selectedTemplate,
    required this.selectedTemplateId,
    required this.model,
  });

  final String sessionId;
  final String gcsPath;
  final int chunkNumber;
  final bool isLast;
  final int totalChunksClient;
  final String publicUrl;
  final String mimeType;
  final String selectedTemplate;
  final String selectedTemplateId;
  final String model;

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'gcsPath': gcsPath,
      'chunkNumber': chunkNumber,
      'isLast': isLast,
      'totalChunksClient': totalChunksClient,
      'publicUrl': publicUrl,
      'mimeType': mimeType,
      'selectedTemplate': selectedTemplate,
      'selectedTemplateId': selectedTemplateId,
      'model': model,
    };
  }
}
