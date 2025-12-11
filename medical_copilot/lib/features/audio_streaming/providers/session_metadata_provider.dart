import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Metadata stored for each recording session
class SessionMetadata {
  SessionMetadata({
    required this.sessionId,
    required this.templateId,
    required this.templateTitle,
  });

  final String sessionId;
  final String templateId;
  final String templateTitle;
}

/// Provider that stores session metadata by session ID
final sessionMetadataProvider = StateProvider<Map<String, SessionMetadata>>((ref) => {});

/// Helper to get metadata for a session
final getSessionMetadataProvider = Provider.family<SessionMetadata?, String>((ref, sessionId) {
  final metadataMap = ref.watch(sessionMetadataProvider);
  return metadataMap[sessionId];
});

