class UploadSessionRequest {
  UploadSessionRequest({
    required this.patientId,
    required this.userId,
    required this.patientName,
    required this.status,
    required this.startTime,
    required this.templateId,
  });

  final String patientId;
  final String userId;
  final String patientName;
  final String status;
  final String startTime;
  final String templateId;

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'userId': userId,
      'patientName': patientName,
      'status': status,
      'startTime': startTime,
      'templateId': templateId,
    };
  }
}

class UploadSessionResponse {
  UploadSessionResponse({required this.id});

  final String id;

  factory UploadSessionResponse.fromJson(Map<String, dynamic> json) {
    return UploadSessionResponse(id: json['id'] as String);
  }
}
