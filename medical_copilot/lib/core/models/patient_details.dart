class PatientDetails {
  PatientDetails({
    required this.id,
    required this.name,
    required this.pronouns,
    required this.email,
    required this.background,
    required this.medicalHistory,
    required this.familyHistory,
    required this.socialHistory,
    required this.previousTreatment,
  });

  final String id;
  final String name;
  final String? pronouns;
  final String? email;
  final String? background;
  final String? medicalHistory;
  final String? familyHistory;
  final String? socialHistory;
  final String? previousTreatment;

  factory PatientDetails.fromJson(Map<String, dynamic> json) {
    return PatientDetails(
      id: json['id'] as String,
      name: json['name'] as String,
      pronouns: json['pronouns'] as String?,
      email: json['email'] as String?,
      background: json['background'] as String?,
      medicalHistory: json['medical_history'] as String?,
      familyHistory: json['family_history'] as String?,
      socialHistory: json['social_history'] as String?,
      previousTreatment: json['previous_treatment'] as String?,
    );
  }
}
