class Student {
  final int id;
  final String fullName;

  Student({required this.id, required this.fullName});

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      fullName: json['full_name'] ?? '',
    );
  }
}
