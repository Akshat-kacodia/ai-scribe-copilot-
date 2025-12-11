class TemplateModel {
  TemplateModel({
    required this.id,
    required this.title,
    required this.type,
  });

  final String id;
  final String title;
  final String? type;

  factory TemplateModel.fromJson(Map<String, dynamic> json) {
    return TemplateModel(
      id: json['id'] as String,
      title: json['title'] as String,
      type: json['type'] as String?,
    );
  }
}
