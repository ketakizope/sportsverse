import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_provider.dart';
import 'package:provider/provider.dart';
// ✅ USE YOUR EXISTING API CLIENT (VERY IMPORTANT)

// ✅ Your model file
import '/models/student_models.dart';

class AdminProvider with ChangeNotifier {
  List<StudentEnrollment> _allEnrollments = [];
  List<StudentEnrollment> _filteredEnrollments = [];
  bool _isLoading = false;

  List<StudentEnrollment> get enrollments => _filteredEnrollments;
  bool get isLoading => _isLoading;

  // 🔥 FETCH STUDENTS WITH FILTERS + AUTH TOKEN
Future<void> fetchAllStudents(BuildContext context,
    {String? branch, String? batch}) async {
  _isLoading = true;
  notifyListeners();

  try {
    String url = 'http://127.0.0.1:8000/api/accounts/students/';

    if (branch != null || batch != null) {
      url += '?';
      if (branch != null) url += 'branch=$branch&';
      if (batch != null) url += 'batch=$batch';
    }

  // ✅ GET REAL TOKEN FROM AUTH PROVIDER
final authProvider =
    Provider.of<AuthProvider>(context, listen: false);
final token = authProvider.accessToken;

// ✅ API CALL WITH REAL TOKEN
final response = await http.get(
  Uri.parse(url),
  headers: {
    "Authorization": "Bearer $token",
    "Content-Type": "application/json",
  },
);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      _allEnrollments =
          data.map((e) => StudentEnrollment.fromJson(e)).toList();

      _filteredEnrollments = _allEnrollments;
    } else {
      debugPrint("API ERROR: ${response.statusCode}");
    }
  } catch (e) {
    debugPrint("Error fetching students: $e");
  }

  _isLoading = false;
  notifyListeners();
}
}