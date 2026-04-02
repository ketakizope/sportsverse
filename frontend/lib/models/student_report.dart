class StudentReport {
  final int id;
  final String title;
  final String file;
  final String uploadedAt;

  StudentReport({
    required this.id,
    required this.title,
    required this.file,
    required this.uploadedAt,
  });

  factory StudentReport.fromJson(Map<String, dynamic> json) {
    return StudentReport(
      id: json['id'],
      title: json['title'],
      file: json['report_file'],
      uploadedAt: json['uploaded_at'],
    );
  }
}