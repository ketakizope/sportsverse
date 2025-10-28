import 'package:flutter/foundation.dart';
import 'package:sportsverse_app/api/student_api.dart';
import 'package:sportsverse_app/models/student_models.dart';

class StudentProvider with ChangeNotifier {
  // State variables
  bool _isLoading = false;
  String? _error;
  
  // Dashboard data
  StudentDashboardData? _dashboardData;
  
  // Enrollments
  List<StudentEnrollment> _currentEnrollments = [];
  List<StudentEnrollment> _previousEnrollments = [];
  
  // Attendance
  List<StudentAttendance> _attendanceRecords = [];
  Map<int, List<StudentAttendance>> _attendanceByEnrollment = {};
  
  // Payments
  List<StudentPayment> _payments = [];
  Map<String, dynamic> _paymentSummary = {};
  Map<String, dynamic> _attendanceSummary = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  StudentDashboardData? get dashboardData => _dashboardData;
  List<StudentEnrollment> get currentEnrollments => _currentEnrollments;
  List<StudentEnrollment> get previousEnrollments => _previousEnrollments;
  List<StudentAttendance> get attendanceRecords => _attendanceRecords;
  Map<int, List<StudentAttendance>> get attendanceByEnrollment => _attendanceByEnrollment;
  List<StudentPayment> get payments => _payments;
  Map<String, dynamic> get paymentSummary => _paymentSummary;
  Map<String, dynamic> get attendanceSummary => _attendanceSummary;

  // Error handling
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Load dashboard data
  Future<void> loadDashboardData() async {
    _setLoading(true);
    _setError(null);
    
    try {
      _dashboardData = await StudentApi.getDashboardData();
      _currentEnrollments = _dashboardData!.currentEnrollments;
      _previousEnrollments = _dashboardData!.previousEnrollments;
      _attendanceRecords = _dashboardData!.recentAttendance;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load enrollments
  Future<void> loadEnrollments({String? status}) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final enrollments = await StudentApi.getEnrollments(status: status);
      
      if (status == 'active' || status == null) {
        _currentEnrollments = enrollments.where((e) => e.isActive).toList();
      } else if (status == 'completed') {
        _previousEnrollments = enrollments.where((e) => !e.isActive).toList();
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load attendance records
  Future<void> loadAttendance({
    int? enrollmentId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final attendance = await StudentApi.getAttendance(
        enrollmentId: enrollmentId,
        startDate: startDate,
        endDate: endDate,
      );
      
      _attendanceRecords = attendance;
      
      // Group by enrollment
      _attendanceByEnrollment.clear();
      for (var record in attendance) {
        if (!_attendanceByEnrollment.containsKey(record.enrollmentId)) {
          _attendanceByEnrollment[record.enrollmentId] = [];
        }
        _attendanceByEnrollment[record.enrollmentId]!.add(record);
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load payments
  Future<void> loadPayments({int? enrollmentId}) async {
    _setLoading(true);
    _setError(null);
    
    try {
      _payments = await StudentApi.getPayments(enrollmentId: enrollmentId);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load payment summary
  Future<void> loadPaymentSummary() async {
    _setLoading(true);
    _setError(null);
    
    try {
      _paymentSummary = await StudentApi.getPaymentSummary();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load attendance summary
  Future<void> loadAttendanceSummary() async {
    _setLoading(true);
    _setError(null);
    
    try {
      _attendanceSummary = await StudentApi.getAttendanceSummary();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Process payment
  Future<bool> processPayment({
    required int enrollmentId,
    required double amount,
    String? paymentMethod,
    String? transactionId,
  }) async {
    _setLoading(true);
    _setError(null);
    
    try {
      await StudentApi.processPayment(
        enrollmentId: enrollmentId,
        amount: amount,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
      );
      
      // Reload payments after successful payment
      await loadPayments();
      await loadPaymentSummary();
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get attendance for specific enrollment
  List<StudentAttendance> getAttendanceForEnrollment(int enrollmentId) {
    return _attendanceByEnrollment[enrollmentId] ?? [];
  }

  // Get payments for specific enrollment
  List<StudentPayment> getPaymentsForEnrollment(int enrollmentId) {
    return _payments.where((p) => p.enrollmentId == enrollmentId).toList();
  }

  // Check if enrollment has pending payments
  bool hasPendingPayments(int enrollmentId) {
    return _payments.any((p) => p.enrollmentId == enrollmentId && !p.isPaid);
  }

  // Calculate total amount for enrollment
  double calculateEnrollmentAmount(int enrollmentId) {
    return _payments
        .where((p) => p.enrollmentId == enrollmentId)
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  // Calculate paid amount for enrollment
  double calculatePaidAmount(int enrollmentId) {
    return _payments
        .where((p) => p.enrollmentId == enrollmentId && p.isPaid)
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  // Calculate pending amount for enrollment
  double calculatePendingAmount(int enrollmentId) {
    return calculateEnrollmentAmount(enrollmentId) - calculatePaidAmount(enrollmentId);
  }

  // Get attendance percentage for enrollment
  double getAttendancePercentage(int enrollmentId) {
    final attendance = getAttendanceForEnrollment(enrollmentId);
    if (attendance.isEmpty) return 0.0;
    
    final presentCount = attendance.where((a) => a.isPresent).length;
    return (presentCount / attendance.length) * 100;
  }

  // Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([
      loadDashboardData(),
      loadAttendanceSummary(),
      loadPaymentSummary(),
    ]);
  }

  // Clear all data
  void clearAll() {
    _dashboardData = null;
    _currentEnrollments.clear();
    _previousEnrollments.clear();
    _attendanceRecords.clear();
    _attendanceByEnrollment.clear();
    _payments.clear();
    _paymentSummary.clear();
    _attendanceSummary.clear();
    _error = null;
    notifyListeners();
  }
}
