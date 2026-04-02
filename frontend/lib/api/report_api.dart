import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:sportsverse_app/api/api_client.dart';

class ReportApi {
  final ApiClient apiClient;

  ReportApi(this.apiClient);

  /// Sends a report to a SPECIFIC student
  Future<bool> sendReport({
    required int studentId,
    required String title,
    required String comments,
    File? attachment,
  }) async {
    // FIXED: Use ApiClient.baseUrl (Capitalized) because it is a static member
    var uri = Uri.parse('${ApiClient.baseUrl}/api/reports/upload/');
    var request = http.MultipartRequest('POST', uri);

    // 1. ADD THE TOKEN
    final token = apiClient.getToken(); 
    if (token != null) {
      request.headers['Authorization'] = 'Token $token';
    }

    // 2. ADD DATA
    request.fields['student'] = studentId.toString(); 
    request.fields['title'] = title;
    request.fields['comments'] = comments;

    if (attachment != null) {
      // Note: This works for Mobile. For Web, you'd use fromBytes.
      request.files.add(await http.MultipartFile.fromPath(
        'report_file', // Ensure this matches your Django field name
        attachment.path
      ));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please log in again.');
    } else {
      print("Upload Error: ${response.body}");
      throw Exception('Failed to send report: ${response.statusCode}');
    }
  }
}

// Global instance
final reportApi = ReportApi(apiClient);