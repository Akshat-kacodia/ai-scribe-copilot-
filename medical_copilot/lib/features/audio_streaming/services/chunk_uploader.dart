import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/chunk_notification.dart';
import '../../../core/models/presigned_url.dart';
import '../../../core/network/api_client.dart';
import '../models/audio_chunk.dart';
import '../providers/session_metadata_provider.dart';
import 'chunk_queue.dart';

class ChunkUploader {
  ChunkUploader({
    required ApiClient apiClient,
    required ChunkQueue queue,
    required Connectivity connectivity,
    required Ref ref,
  })  : _apiClient = apiClient,
        _queue = queue,
        _connectivity = connectivity,
        _ref = ref {
    _connectivity.onConnectivityChanged.listen((_) {
      // Try to drain whenever connectivity changes.
      drainQueue();
    });
  }

  final ApiClient _apiClient;
  final ChunkQueue _queue;
  final Connectivity _connectivity;
  final Ref _ref;

  bool _draining = false;

  Future<void> drainQueue() async {
    if (_draining) return;
    _draining = true;
    try {
      final status = await _connectivity.checkConnectivity();
      final online = switch (status) {
        ConnectivityResult.mobile => true,
        ConnectivityResult.wifi => true,
        ConnectivityResult.ethernet => true,
        _ => false,
      };
      if (!online) return;

      while (true) {
        final pending = await _queue.getPending(limit: 1);
        if (pending.isEmpty) break;
        final chunk = pending.first;
        try {
          await _uploadSingleChunk(chunk);
        } on DioException catch (e) {
          // Network error - stop trying for now, will retry when connectivity changes
          debugPrint('Network error in drainQueue, stopping: ${e.message}');
          break;
        } catch (e) {
          // Other errors - log and continue with next chunk
          debugPrint('Error uploading chunk, continuing: $e');
          // Small delay before trying next chunk to avoid rapid retries
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    } finally {
      _draining = false;
    }
  }

  Future<void> _uploadSingleChunk(AudioChunk chunk) async {
    try {
      final file = File(chunk.filePath);
      if (!await file.exists()) {
        // If file is missing, mark as uploaded to avoid infinite retries.
        debugPrint('Chunk file not found: ${chunk.filePath}');
        await _queue.markUploaded(chunk);
        return;
      }

      final bytes = await file.readAsBytes();

      // Get presigned URL with error handling
      PresignedUrlResponse presigned;
      try {
        presigned = await _apiClient.getPresignedUrl(
          sessionId: chunk.sessionId,
          chunkNumber: chunk.chunkNumber,
          mimeType: chunk.mimeType,
        );
      } on DioException catch (e) {
        // Network error getting presigned URL - chunk stays in queue for retry
        debugPrint('Failed to get presigned URL for chunk ${chunk.chunkNumber}: ${e.message}');
        if (e.type == DioExceptionType.connectionError || 
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          // Connection errors - will retry when network is available
          rethrow;
        }
        // Other errors - log and skip this chunk (will retry later)
        return;
      } catch (e) {
        debugPrint('Unexpected error getting presigned URL: $e');
        return; // Skip this chunk, will retry later
      }

      // Upload chunk to presigned URL with error handling
      try {
        await _apiClient.uploadChunkToPresignedUrl(
          url: presigned.url,
          bytes: bytes,
          mimeType: chunk.mimeType,
        );
      } on DioException catch (e) {
        // Network error uploading chunk - chunk stays in queue for retry
        debugPrint('Failed to upload chunk ${chunk.chunkNumber} to presigned URL: ${e.message}');
        if (e.type == DioExceptionType.connectionError || 
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          // Connection errors - will retry when network is available
          rethrow;
        }
        // Other errors - log and skip this chunk (will retry later)
        return;
      } catch (e) {
        debugPrint('Unexpected error uploading chunk: $e');
        return; // Skip this chunk, will retry later
      }

      // Get session metadata for template info
      final metadata = _ref.read(getSessionMetadataProvider(chunk.sessionId));
      final templateTitle = metadata?.templateTitle ?? 'New Patient Visit';
      final templateId = metadata?.templateId ?? 'new_patient_visit';

      final notification = ChunkNotification(
        sessionId: chunk.sessionId,
        gcsPath: presigned.gcsPath,
        chunkNumber: chunk.chunkNumber,
        isLast: chunk.isLast,
        totalChunksClient: 0, // Unknown client-side total at this stage.
        publicUrl: presigned.publicUrl,
        mimeType: chunk.mimeType,
        selectedTemplate: templateTitle,
        selectedTemplateId: templateId,
        model: 'fast',
      );

      // Notify backend with error handling
      try {
        await _apiClient.notifyChunkUploaded(notification);
      } on DioException catch (e) {
        // If notification fails, log but don't fail the upload
        // The chunk was already uploaded successfully
        debugPrint('Failed to notify chunk uploaded (chunk was uploaded): ${e.message}');
      } catch (e) {
        debugPrint('Unexpected error notifying chunk uploaded: $e');
      }

      // Mark as uploaded only after successful upload
      await _queue.markUploaded(chunk);
    } on DioException catch (e) {
      // Re-throw connection errors so they can be handled by drainQueue
      // This allows the chunk to remain in queue for retry
      debugPrint('Network error uploading chunk ${chunk.chunkNumber}: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      // Log unexpected errors but don't crash
      debugPrint('Unexpected error in _uploadSingleChunk: $e');
      debugPrint('Stack trace: $stackTrace');
      // Don't rethrow - chunk stays in queue for retry
    }
  }
}
