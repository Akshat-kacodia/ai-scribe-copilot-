class PresignedUrlResponse {
  PresignedUrlResponse({
    required this.url,
    required this.gcsPath,
    required this.publicUrl,
  });

  final String url;
  final String gcsPath;
  final String publicUrl;

  factory PresignedUrlResponse.fromJson(Map<String, dynamic> json) {
    return PresignedUrlResponse(
      url: json['url'] as String,
      gcsPath: json['gcsPath'] as String,
      publicUrl: json['publicUrl'] as String,
    );
  }
}
