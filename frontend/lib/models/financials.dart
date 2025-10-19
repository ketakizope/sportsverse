class StudentFinancials {
  final double totalPaid;
  final double totalDue;

  StudentFinancials({required this.totalPaid, required this.totalDue});

  factory StudentFinancials.fromJson(Map<String, dynamic> json) {
    return StudentFinancials(
      totalPaid: double.tryParse(json['total_paid'].toString()) ?? 0.0,
      totalDue: double.tryParse(json['total_due'].toString()) ?? 0.0,
    );
  }
}
