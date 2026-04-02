import 'dart:convert'; // Required for jsonDecode
import 'package:flutter/foundation.dart'; // Required for debugPrint
import 'package:sportsverse_app/api/api_client.dart';

class PaymentApi {
  final ApiClient apiClient;

  PaymentApi(this.apiClient);

  /// Fetches financial summary for a specific batch.
  /// Hits Django View: BatchFinancialsSummaryView
  Future<Map<String, dynamic>?> getBatchFinancials({
    required String branchId,
    required String sportId,
    required String batchId,
  }) async {
    try {
      final String url = '/api/accounts/batch-financials/?branch=$branchId&sport=$sportId&batch=$batchId';
      
      print("📡 Requesting Financials: $url");

      final response = await apiClient.get(url);
      
      print("📥 Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final dynamic responseData = response.body;
        
        if (responseData is String) {
          return jsonDecode(responseData);
        } else {
          return responseData as Map<String, dynamic>;
        }
      } else {
        print("❌ Failed to load financials. Status: ${response.statusCode}, Body: ${response.body}");
        return null;
      }
    } catch (e) {
      print("⚠️ Error fetching financials: $e");
      return null;
    }
  }

  /// Optional: Process a session payment for a student
  Future<bool> recordPayment({
    required String studentId,
    required double amount,
    required String method,
  }) async {
    try {
      final response = await apiClient.post(
        '/api/accounts/payments/',
        {
          'student_id': studentId,
          'amount': amount,
          'method': method,
        },
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("⚠️ Error recording payment: $e");
      return false;
    }
  }

  /// EXISTING: Organization analytics (OLD - keep it, don't delete)
  Future<List<dynamic>?> getOrganizationAnalytics({required String period}) async {
    try {
      final String url = '/api/payments/analytics/financials/?period=$period';
      
      debugPrint("📡 Requesting Chart Data: $url");

      final response = await apiClient.get(url);

      if (response.statusCode == 200) {
        final dynamic responseData = response.body;
        
        if (responseData is String) {
          return jsonDecode(responseData);
        } else {
          return responseData as List<dynamic>;
        }
      } else {
        debugPrint("❌ Analytics Failed. Status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("⚠️ Analytics Error: $e");
      return null;
    }
  }

  /// 🆕 NEW CLEAN DASHBOARD ANALYTICS (THIS IS WHAT YOU USE NOW)
  Future<Map<String, dynamic>> getDashboardAnalytics() async {
    try {
      final String url = '/api/payments/dashboard/analytics/';
      
      debugPrint("📡 Requesting Dashboard Analytics: $url");

      final response = await apiClient.get(url);

      if (response.statusCode == 200) {
        final dynamic responseData = response.body;

        if (responseData is String) {
          return jsonDecode(responseData);
        } else {
          return responseData as Map<String, dynamic>;
        }
      } else {
        debugPrint("❌ Dashboard Analytics Failed. Status: ${response.statusCode}");
        throw Exception('Failed to load dashboard analytics');
      }
    } catch (e) {
      debugPrint("⚠️ Dashboard Analytics Error: $e");
      throw Exception(e);
    }
  }

  /// NEW: Adds a general expense (Rent, Electricity, etc.) to the database.
  Future<bool> addGeneralExpense({
    required String title,
    required double amount,
    required String category,
    required String date, // Format: YYYY-MM-DD
  }) async {
    try {
      final response = await apiClient.post(
        '/api/payments/expenses/', 
        {
          'title': title,
          'amount': amount,
          'category': category,
          'date': date,
        },
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint("⚠️ Error adding expense: $e");
      return false;
    }
  }
}