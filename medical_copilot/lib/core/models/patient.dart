class Patient {
  Patient({
    required this.id,
    required this.name,
    this.pronouns,
  });

  final String id;
  final String name;
  final String? pronouns;

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String,
      name: json['name'] as String,
      pronouns: json['pronouns'] as String?,
    );
  }
}
