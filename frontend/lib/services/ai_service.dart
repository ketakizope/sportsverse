import 'dart:convert';
import 'package:sportsverse_app/api/api_client.dart';

class AIService {
  Future<String> getBotResponse(String userQuery) async {
    try {
      final response = await apiClient.post(
        'api/ai-assistant/',
        {"query": userQuery},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response']; // This matches the 'response' key in your Django view
      } else {
        return "Server error: ${response.statusCode}";
      }
    } catch (e) {
      return "Connection failed. Make sure Django is running!";
    }
  }
}