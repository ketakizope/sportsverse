// lib/api/coach_api.dart
//
// Handles all coach-related API calls.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sportsverse_app/api/api_client.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Models
// ═══════════════════════════════════════════════════════════════════════════════

class Coach {
  final int id;
  final String coachName;
  final List<int> assignedBranches;
  final List<String> assignedBranchNames;

  const Coach({
    required this.id,
    required this.coachName,
    required this.assignedBranches,
    required this.assignedBranchNames,
  });

  factory Coach.fromJson(Map<String, dynamic> json) => Coach(
        id: json['id'] as int,
        coachName: json['coach_name'] as String? ?? '',
        assignedBranches:
            List<int>.from(json['branches'] as List? ?? const []),
        assignedBranchNames:
            List<String>.from(json['assigned_branch_names'] as List? ?? const []),
      );
}

// ─── Dashboard models ──────────────────────────────────────────────────────

class CoachProfileSummary {
  final int id;
  final String fullName;
  final String email;
  final String specialization;
  final int organizationId;
  final String organizationName;

  const CoachProfileSummary({
    required this.id,
    required this.fullName,
    required this.email,
    required this.specialization,
    required this.organizationId,
    required this.organizationName,
  });

  factory CoachProfileSummary.fromJson(Map<String, dynamic> j) =>
      CoachProfileSummary(
        id: j['id'] as int? ?? 0,
        fullName: j['full_name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        specialization: j['specialization'] as String? ?? '',
        organizationId: j['organization_id'] as int? ?? 0,
        organizationName: j['organization_name'] as String? ?? '',
      );
}

class CoachAssignmentSummary {
  final int id;
  final int batchId;
  final String batchName;
  final String branch;
  final String sport;
  final String? scheduleDetails;

  const CoachAssignmentSummary({
    required this.id,
    required this.batchId,
    required this.batchName,
    required this.branch,
    required this.sport,
    this.scheduleDetails,
  });

  factory CoachAssignmentSummary.fromJson(Map<String, dynamic> j) =>
      CoachAssignmentSummary(
        id: j['id'] as int? ?? 0,
        batchId: j['batch_id'] as int? ?? 0,
        batchName: j['batch_name'] as String? ?? '',
        branch: j['branch'] as String? ?? '',
        sport: j['sport'] as String? ?? '',
        scheduleDetails: j['schedule_details'] as String?,
      );
}

class UpcomingSession {
  final int batchId;
  final String batchName;
  final String date;   // ISO 8601 date string
  final String day;    // e.g. "Monday"
  final String time;   // e.g. "07:00"

  const UpcomingSession({
    required this.batchId,
    required this.batchName,
    required this.date,
    required this.day,
    required this.time,
  });

  factory UpcomingSession.fromJson(Map<String, dynamic> j) => UpcomingSession(
        batchId: j['batch_id'] as int? ?? 0,
        batchName: j['batch_name'] as String? ?? '',
        date: j['date'] as String? ?? '',
        day: j['day'] as String? ?? '',
        time: j['time'] as String? ?? '',
      );
}

class BatchAttendanceSummary {
  final int batchId;
  final String batchName;
  final int count;

  const BatchAttendanceSummary({
    required this.batchId,
    required this.batchName,
    required this.count,
  });

  factory BatchAttendanceSummary.fromJson(Map<String, dynamic> j) =>
      BatchAttendanceSummary(
        batchId: j['batch_id'] as int? ?? 0,
        batchName: j['batch_name'] as String? ?? '',
        count: j['count'] as int? ?? 0,
      );
}

class AttendanceSummary {
  final int last30Days;
  final List<BatchAttendanceSummary> byBatch;

  const AttendanceSummary({
    required this.last30Days,
    required this.byBatch,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> j) =>
      AttendanceSummary(
        last30Days: j['last_30_days'] as int? ?? 0,
        byBatch: (j['by_batch'] as List? ?? const [])
            .map((b) => BatchAttendanceSummary.fromJson(b as Map<String, dynamic>))
            .toList(),
      );
}

class PendingSalary {
  final double amount;
  final String currency;

  const PendingSalary({required this.amount, required this.currency});

  factory PendingSalary.fromJson(Map<String, dynamic> j) => PendingSalary(
        amount: (j['amount'] as num? ?? 0).toDouble(),
        currency: j['currency'] as String? ?? '₹',
      );
}

class CoachDashboardData {
  final CoachProfileSummary coachProfile;
  final List<CoachAssignmentSummary> assignments;
  final List<UpcomingSession> upcomingSessions;
  final AttendanceSummary attendanceSummary;
  final PendingSalary pendingSalary;

  const CoachDashboardData({
    required this.coachProfile,
    required this.assignments,
    required this.upcomingSessions,
    required this.attendanceSummary,
    required this.pendingSalary,
  });

  factory CoachDashboardData.fromJson(Map<String, dynamic> j) =>
      CoachDashboardData(
        coachProfile: CoachProfileSummary.fromJson(
          j['coach_profile'] as Map<String, dynamic>? ?? const {},
        ),
        assignments: (j['assignments'] as List? ?? const [])
            .map((a) => CoachAssignmentSummary.fromJson(a as Map<String, dynamic>))
            .toList(),
        upcomingSessions: (j['upcoming_sessions'] as List? ?? const [])
            .map((s) => UpcomingSession.fromJson(s as Map<String, dynamic>))
            .toList(),
        attendanceSummary: AttendanceSummary.fromJson(
          j['attendance_summary'] as Map<String, dynamic>? ?? const {},
        ),
        pendingSalary: PendingSalary.fromJson(
          j['pending_salary'] as Map<String, dynamic>? ?? const {},
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// API class
// ═══════════════════════════════════════════════════════════════════════════════

class CoachApi {
  final ApiClient apiClient;
  const CoachApi(this.apiClient);

  /// GET /api/organizations/coaches/ — all coaches in the authenticated org.
  Future<List<Coach>> getCoaches() async {
    final response = await apiClient.get(
      '/api/accounts/coaches/',
      includeAuth: true,
    );
    if (response.statusCode == 200) {
      return (json.decode(response.body) as List)
          .map((j) => Coach.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    final err = json.decode(response.body);
    throw Exception(err['detail'] ?? 'Failed to load coaches');
  }

  /// PUT /api/accounts/coaches/<id>/assign-branches/ — assign branches.
  Future<Coach> assignBranches({
    required int coachId,
    required List<int> branchIds,
  }) async {
    final response = await apiClient.put(
      '/api/accounts/coaches/$coachId/assign-branches/',
      {'branches': branchIds},
      includeAuth: true,
    );
    if (response.statusCode == 200) {
      return Coach.fromJson(
        (json.decode(response.body) as Map<String, dynamic>)['coach']
            as Map<String, dynamic>,
      );
    }
    final err = json.decode(response.body);
    if (err is Map && err.containsKey('branches')) {
      throw Exception('Branches: ${(err['branches'] as List).join(', ')}');
    }
    throw Exception(
      (err is Map ? err['detail'] : null) ?? 'Failed to assign branches',
    );
  }

  /// GET /api/accounts/coach-dashboard/ — full dashboard payload.
  Future<CoachDashboardData> getCoachDashboard() async {
    debugPrint('📡 CoachApi: GET /api/accounts/coach-dashboard/');
    final response = await apiClient.get(
      '/api/accounts/coach-dashboard/',
      includeAuth: true,
    );
    debugPrint('📥 CoachApi: status ${response.statusCode}');
    if (response.statusCode == 200) {
      return CoachDashboardData.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    final err = json.decode(response.body);
    throw Exception(
      (err is Map ? err['detail'] ?? err['error'] : null) ??
          'Failed to load coach dashboard (${response.statusCode})',
    );
  }
}

final coachApi = CoachApi(apiClient);
