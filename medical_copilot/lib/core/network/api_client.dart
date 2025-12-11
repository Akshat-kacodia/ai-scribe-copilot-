import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:dio/dio.dart';

import '../models/patient.dart';
import '../models/patient_details.dart';
import '../models/patient_sessions.dart';
import '../models/template_model.dart';
import '../models/upload_session.dart';
import '../models/presigned_url.dart';
import '../models/chunk_notification.dart';
import 'dio_client.dart';

class ApiClient {
  ApiClient({String? authToken, String? baseUrl, String? backendBaseUrl})
      : _client = DioClient(
          authToken: authToken,
          baseUrl: baseUrl,
          backendBaseUrl: backendBaseUrl,
        );

  final DioClient _client;

  Dio get _dio => _client.dio;

  /// Resolve user database ID from email.
  Future<String> getUserIdByEmail(String email) async {
    try {
      final backendUrl = _client.backendBaseUrl;
      final dio = Dio(BaseOptions(
        baseUrl: backendUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
      ));
      
      final authToken = _client.authToken;
      if (authToken != null && authToken.isNotEmpty) {
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              options.headers['Authorization'] = 'Bearer $authToken';
              return handler.next(options);
            },
          ),
        );
      }
      
      final response = await dio.get(
        '/users/asd3fd2faec',
        queryParameters: {'email': email},
      );
      
      if (response.data is Map && response.data.containsKey('id')) {
        return response.data['id'] as String;
      }
      throw Exception('Invalid response format: ${response.data}');
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response?.data;
        final errorMsg = errorData is Map 
            ? errorData['details'] ?? errorData['error'] ?? errorData.toString()
            : errorData.toString();
        throw Exception('API error ${e.response?.statusCode}: $errorMsg');
      } else {
        throw Exception('Network error: ${e.message}. Check:\n1. Backend is running\n2. Correct IP address in API Base URL\n3. Phone and computer on same WiFi');
      }
    }
  }

  /// Get patients for a specific user.
  Future<List<Patient>> getPatients({required String userId}) async {
    final response = await _dio.get(
      '/v1/patients',
      queryParameters: {'userId': userId},
    );
    final patientsJson = response.data['patients'] as List<dynamic>;
    return patientsJson.map((e) => Patient.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Create a new patient.
  Future<Patient> createPatient({
    required String name,
    required String userId,
  }) async {
    final response = await _dio.post(
      '/v1/add-patient-ext',
      data: {
        'name': name,
        'userId': userId,
      },
    );
    return Patient.fromJson(response.data['patient'] as Map<String, dynamic>);
  }

  /// Update an existing patient.
  Future<void> updatePatient({
    required String patientId,
    required Map<String, dynamic> data,
  }) async {
    await _dio.put('/v1/patient/$patientId', data: data);
  }

  /// Get full patient details by ID.
  Future<PatientDetails> getPatientDetails(String patientId) async {
    final response = await _dio.get('/v1/patient-details/$patientId');
    return PatientDetails.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get sessions for a specific patient.
  Future<List<PatientSessionSummary>> getSessionsForPatient(String patientId) async {
    final response = await _dio.get('/v1/fetch-session-by-patient/$patientId');
    final sessionsJson = response.data['sessions'] as List<dynamic>;
    return sessionsJson
        .map((e) => PatientSessionSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get all sessions for a user with patient map.
  Future<AllSessionsResponse> getAllSessions({required String userId}) async {
    final response = await _dio.get(
      '/v1/all-session',
      queryParameters: {'userId': userId},
    );
    return AllSessionsResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get templates for a user.
  Future<List<TemplateModel>> getTemplates({required String userId}) async {
    final response = await _dio.get(
      '/v1/fetch-default-template-ext',
      queryParameters: {'userId': userId},
    );
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => TemplateModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Start a recording session.
  Future<UploadSessionResponse> createUploadSession(
    UploadSessionRequest request,
  ) async {
    final response = await _dio.post('/v1/upload-session', data: request.toJson());
    return UploadSessionResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get presigned URL for an audio chunk.
  Future<PresignedUrlResponse> getPresignedUrl({
    required String sessionId,
    required int chunkNumber,
    required String mimeType,
  }) async {
    final response = await _dio.post('/v1/get-presigned-url', data: {
      'sessionId': sessionId,
      'chunkNumber': chunkNumber,
      'mimeType': mimeType,
    });
    return PresignedUrlResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Notify backend that a chunk was uploaded.
  Future<void> notifyChunkUploaded(ChunkNotification notification) async {
    await _dio.post('/v1/notify-chunk-uploaded', data: notification.toJson());
  }

  /// Upload binary audio data to the given presigned URL.
  Future<void> uploadChunkToPresignedUrl({
    required String url,
    required List<int> bytes,
    required String mimeType,
  }) async {
    // IMPORTANT: Use a clean Dio instance for presigned URLs.
    // We must NOT send the Backend's 'Authorization' header to S3/GCS.
    final uploadDio = Dio();

    try {
      final response = await uploadDio.put(
        url,
        data: Uint8List.fromList(bytes),
        options: Options(
          headers: {
            'Content-Type': mimeType,
            // REMOVED Content-Length: Dio adds this automatically.
            // Adding it manually can cause signature mismatches on S3/GCS.
          },
          // Allow 403/400 errors so we can read the response body for debugging
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        // Log the actual error from S3/GCS
        debugPrint('⚠️ Upload Failed: ${response.statusCode}');
        debugPrint('⚠️ Response Body: ${response.data}');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Upload failed with status ${response.statusCode}',
        );
      }
    } catch (e) {
      // Re-throw to trigger retry logic in caller
      rethrow;
    }
  }
}