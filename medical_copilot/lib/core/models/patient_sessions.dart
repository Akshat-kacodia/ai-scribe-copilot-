class PatientSessionSummary {
  PatientSessionSummary({
    required this.id,
    required this.date,
    required this.sessionTitle,
    required this.sessionSummary,
    required this.startTime,
  });

  final String id;
  final String? date;
  final String? sessionTitle;
  final String? sessionSummary;
  final String? startTime;

  factory PatientSessionSummary.fromJson(Map<String, dynamic> json) {
    return PatientSessionSummary(
      id: json['id'] as String,
      date: json['date'] as String?,
      sessionTitle: json['session_title'] as String?,
      sessionSummary: json['session_summary'] as String?,
      startTime: json['start_time'] as String?,
    );
  }
}

class AllSessionsResponse {
  AllSessionsResponse({
    required this.sessions,
    required this.patientMap,
  });

  final List<AllSessionItem> sessions;
  final Map<String, PatientMapEntry> patientMap;

  factory AllSessionsResponse.fromJson(Map<String, dynamic> json) {
    final sessionsJson = json['sessions'] as List<dynamic>;
    final patientMapJson = json['patientMap'] as Map<String, dynamic>? ?? {};
    return AllSessionsResponse(
      sessions: sessionsJson
          .map((e) => AllSessionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      patientMap: patientMapJson.map(
        (key, value) => MapEntry(
          key,
          PatientMapEntry.fromJson(value as Map<String, dynamic>),
        ),
      ),
    );
  }
}

class AllSessionItem {
  AllSessionItem({
    required this.id,
    required this.userId,
    required this.patientId,
    required this.sessionTitle,
    required this.sessionSummary,
    required this.transcriptStatus,
    required this.transcript,
    required this.status,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.patientName,
    this.audioUrl,
  });

  final String id;
  final String? userId;
  final String? patientId;
  final String? sessionTitle;
  final String? sessionSummary;
  final String? transcriptStatus;
  final String? transcript;
  final String? status;
  final String? date;
  final String? startTime;
  final String? endTime;
  final String? patientName;
  final String? audioUrl;

  factory AllSessionItem.fromJson(Map<String, dynamic> json) {
    return AllSessionItem(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      patientId: json['patient_id'] as String?,
      sessionTitle: json['session_title'] as String?,
      sessionSummary: json['session_summary'] as String?,
      transcriptStatus: json['transcript_status'] as String?,
      transcript: json['transcript'] as String?,
      status: json['status'] as String?,
      date: json['date'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      patientName: json['patient_name'] as String?,
      audioUrl: json['audio_url'] as String?,
    );
  }
}

class PatientMapEntry {
  PatientMapEntry({
    required this.name,
    required this.pronouns,
  });

  final String name;
  final String? pronouns;

  factory PatientMapEntry.fromJson(Map<String, dynamic> json) {
    return PatientMapEntry(
      name: json['name'] as String,
      pronouns: json['pronouns'] as String?,
    );
  }
}
