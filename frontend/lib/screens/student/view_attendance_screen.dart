import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sportsverse_app/providers/student_provider.dart';
import 'package:sportsverse_app/models/student_models.dart';

class ViewAttendanceScreen extends StatefulWidget {
  const ViewAttendanceScreen({super.key});

  @override
  State<ViewAttendanceScreen> createState() => _ViewAttendanceScreenState();
}

class _ViewAttendanceScreenState extends State<ViewAttendanceScreen> {
  Map<int, bool> _expandedEnrollments = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentProvider>(context, listen: false).loadAttendance();
    });
  }

  void _toggleEnrollment(int enrollmentId) {
    setState(() {
      _expandedEnrollments[enrollmentId] = !(_expandedEnrollments[enrollmentId] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentProvider>(
      builder: (context, studentProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('View Attendance'),
            backgroundColor: const Color(0xFF006C62),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: studentProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF006C62), Color(0xFF004D47)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendance Records',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'View your attendance history by enrollment cycle',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Attendance Summary
                  _buildAttendanceSummary(),
                  
                  const SizedBox(height: 24),
                  
                  // Enrollments List
                  const Text(
                    'Enrollment Cycles',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (studentProvider.currentEnrollments.isEmpty && studentProvider.previousEnrollments.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 64,
                              color: Color(0xFF7F8C8D),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No enrollments found',
                              style: TextStyle(
                                color: Color(0xFF7F8C8D),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...[...studentProvider.currentEnrollments, ...studentProvider.previousEnrollments]
                        .map((enrollment) => _buildEnrollmentCard(enrollment)),
                ],
              ),
            ),
        );
      },
    );
  }

  Widget _buildAttendanceSummary() {
    int totalSessions = 0;
    int attendedSessions = 0;
    
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final allEnrollments = [...studentProvider.currentEnrollments, ...studentProvider.previousEnrollments];
    
    for (var enrollment in allEnrollments) {
      totalSessions += enrollment.totalSessions ?? 0;
      attendedSessions += enrollment.sessionsAttended;
    }

    final attendancePercentage = totalSessions > 0 ? (attendedSessions / totalSessions * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall Attendance Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Sessions',
                  totalSessions.toString(),
                  Icons.school,
                  const Color(0xFF3498DB),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  'Attended',
                  attendedSessions.toString(),
                  Icons.check_circle,
                  const Color(0xFF27AE60),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  'Attendance %',
                  '$attendancePercentage%',
                  Icons.trending_up,
                  const Color(0xFF9B59B6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7F8C8D),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentCard(StudentEnrollment enrollment) {
    final enrollmentId = enrollment.id;
    final batchName = enrollment.batchName;
    final enrollmentType = enrollment.enrollmentType;
    final sessionsAttended = enrollment.sessionsAttended;
    final totalSessions = enrollment.totalSessions ?? 0;
    final status = enrollment.enrollmentStatus;
    final startDate = enrollment.startDate;
    final endDate = enrollment.endDate;
    
    final isExpanded = _expandedEnrollments[enrollmentId] ?? false;
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final attendanceRecords = studentProvider.getAttendanceForEnrollment(enrollmentId);
    final isCurrent = status == 'Active' || status == 'Not Started';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Enrollment Header
          InkWell(
            onTap: () => _toggleEnrollment(enrollmentId),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isCurrent ? const Color(0xFFE8F5E8) : Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrent ? const Color(0xFF27AE60) : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isCurrent ? Icons.play_circle : Icons.history,
                    color: isCurrent ? const Color(0xFF27AE60) : const Color(0xFF7F8C8D),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          batchName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isCurrent ? const Color(0xFF27AE60) : const Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$enrollmentType • $sessionsAttended/$totalSessions sessions',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                        if (startDate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${DateFormat('MMM dd, yyyy').format(startDate)}${endDate != null ? ' - ${DateFormat('MMM dd, yyyy').format(endDate)}' : ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7F8C8D),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCurrent ? const Color(0xFF27AE60) : const Color(0xFF7F8C8D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF7F8C8D),
                  ),
                ],
              ),
            ),
          ),
          
          // Attendance Records (Expandable)
          if (isExpanded) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance Records (${attendanceRecords.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (attendanceRecords.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'No attendance records found',
                          style: TextStyle(
                            color: Color(0xFF7F8C8D),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else
                    ...attendanceRecords.map((record) => _buildAttendanceRecord(record)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceRecord(StudentAttendance record) {
    final date = record.date;
    final isPresent = record.isPresent;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPresent ? const Color(0xFF27AE60).withOpacity(0.3) : const Color(0xFFE74C3C).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPresent ? Icons.check_circle : Icons.cancel,
            color: isPresent ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
            size: 20,
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date != null ? DateFormat('EEEE, MMM dd, yyyy').format(date) : 'Unknown Date',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                Text(
                  isPresent ? 'Present' : 'Absent',
                  style: TextStyle(
                    fontSize: 12,
                    color: isPresent ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPresent ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isPresent ? 'Present' : 'Absent',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
