import 'dart:convert';
import 'dart:io';
import 'api_client.dart';

class AdminFaceApi {
  static const String _basePath = '/api/accounts';

  // Train face recognition model
  static Future<Map<String, dynamic>> trainFaceModel() async {
    try {
      print('🧠 Starting face model training...');
      final response = await apiClient.post('$_basePath/train-face-model/', {});
      
      print('🧠 Training response status: ${response.statusCode}');
      print('🧠 Training response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🧠 Model training successful: $data');
        return data;
      } else {
        print('🧠 Model training failed with status: ${response.statusCode}');
        print('🧠 Error body: ${response.body}');
        throw Exception('Failed to train face model: ${response.statusCode}');
      }
    } catch (e) {
      print('🧠 Model training error: $e');
      throw Exception('Error training face model: $e');
    }
  }

  // Capture attendance using face recognition
  static Future<Map<String, dynamic>> captureFaceAttendance(String imagePath, {String? date}) async {
    try {
      print('📸 Starting face attendance capture for: $imagePath');
      
      // Prepare form data
      final formData = <String, dynamic>{};
      if (date != null) {
        formData['date'] = date;
      }
      
      final response = await apiClient.uploadFileWithData(
        '$_basePath/face-attendance/',
        imagePath,
        'captured_image',
        formData,
      );
      
      print('📸 Face attendance response status: ${response.statusCode}');
      print('📸 Face attendance response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📸 Face attendance successful: $data');
        return data;
      } else {
        print('📸 Face attendance failed with status: ${response.statusCode}');
        print('📸 Error body: ${response.body}');
        throw Exception('Failed to capture face attendance: ${response.statusCode}');
      }
    } catch (e) {
      print('📸 Face attendance error: $e');
      throw Exception('Error capturing face attendance: $e');
    }
  }

  // Get training status (if needed for progress tracking)
  static Future<Map<String, dynamic>> getTrainingStatus() async {
    try {
      print('🔍 Getting training status...');
      final response = await apiClient.get('$_basePath/train-status/');
      
      print('🔍 Training status response: ${response.statusCode}');
      print('🔍 Training status body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Failed to get training status: ${response.statusCode}');
      }
    } catch (e) {
      print('🔍 Training status error: $e');
      throw Exception('Error getting training status: $e');
    }
  }
}
