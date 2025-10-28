import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sportsverse_app/providers/student_provider.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentProvider>(context, listen: false).loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentProvider>(
      builder: (context, studentProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Student Dashboard'),
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
                  // Welcome Section
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
                          'Welcome Back!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Track your progress and manage your enrollments',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Dashboard Overview - 4 Info Boxes
                  const Text(
                    'Dashboard Overview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildInfoBox(
                        'Current Enrollment',
                        studentProvider.dashboardData?.currentEnrollment ?? 'No Active Enrollment',
                        Icons.school,
                        const Color(0xFF3498DB),
                      ),
                      _buildInfoBox(
                        'Sessions Completed',
                        '${studentProvider.dashboardData?.sessionsCompleted ?? 0}',
                        Icons.check_circle,
                        const Color(0xFF27AE60),
                      ),
                      _buildInfoBox(
                        'Sessions Remaining',
                        '${studentProvider.dashboardData?.sessionsRemaining ?? 0}',
                        Icons.timer,
                        const Color(0xFFE67E22),
                      ),
                      _buildInfoBox(
                        'Enrollment Cycle',
                        studentProvider.dashboardData?.enrollmentCycle ?? 'N/A',
                        Icons.calendar_today,
                        const Color(0xFF9B59B6),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Enrollment Details Section
                  const Text(
                    'Enrollment Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Current Enrollment Box
                  _buildEnrollmentBox(
                    'Current Enrollment Sessions',
                    studentProvider.currentEnrollments,
                    isCurrent: true,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Previous Enrollments Box
                  _buildEnrollmentBox(
                    'Previous Enrollment Records',
                    studentProvider.previousEnrollments,
                    isCurrent: false,
                  ),
                ],
              ),
            ),
        );
      },
    );
  }

  Widget _buildInfoBox(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7F8C8D),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentBox(String title, List<dynamic> enrollments, {required bool isCurrent}) {
    return Container(
      width: double.infinity,
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
          Row(
            children: [
              Icon(
                isCurrent ? Icons.play_circle : Icons.history,
                color: isCurrent ? const Color(0xFF27AE60) : const Color(0xFF7F8C8D),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (enrollments.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'No enrollments found',
                  style: TextStyle(
                    color: Color(0xFF7F8C8D),
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            ...enrollments.map((enrollment) => _buildEnrollmentCard(enrollment, isCurrent)),
        ],
      ),
    );
  }

  Widget _buildEnrollmentCard(dynamic enrollment, bool isCurrent) {
    final batchName = enrollment.batchName;
    final enrollmentType = enrollment.enrollmentType;
    final sessionsAttended = enrollment.sessionsAttended;
    final totalSessions = enrollment.totalSessions ?? 0;
    final startDate = enrollment.startDate;
    final endDate = enrollment.endDate;
    final status = enrollment.enrollmentStatus;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFFE8F5E8) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent ? const Color(0xFF27AE60) : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  batchName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCurrent ? const Color(0xFF27AE60) : const Color(0xFF2C3E50),
                  ),
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
            ],
          ),
          const SizedBox(height: 8),
          
          Text(
            'Type: $enrollmentType',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF7F8C8D),
            ),
          ),
          
          if (enrollmentType == 'SESSION_BASED' && totalSessions > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Progress: ',
                  style: TextStyle(fontSize: 14, color: Color(0xFF7F8C8D)),
                ),
                Text(
                  '$sessionsAttended/$totalSessions sessions',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ],
          
          if (startDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Color(0xFF7F8C8D)),
                const SizedBox(width: 4),
                Text(
                  'Started: ${DateFormat('MMM dd, yyyy').format(startDate)}',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF7F8C8D)),
                ),
              ],
            ),
          ],
          
          if (endDate != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.event, size: 16, color: Color(0xFF7F8C8D)),
                const SizedBox(width: 4),
                Text(
                  'Ends: ${DateFormat('MMM dd, yyyy').format(endDate)}',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF7F8C8D)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
