import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportsverse_app/models/student_models.dart';
import 'package:sportsverse_app/providers/student_provider.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    final data = provider.dashboardData;

    int totalSessions = 0;
    int attendedSessions = 0;
    double totalDue = 0;
    double totalPaid = 0;

    if (data != null) {
      for (final e in data.currentEnrollments) {
        totalSessions += (e.totalSessions ?? 0);
        attendedSessions += e.sessionsAttended;
        // fee_summary is not in StudentEnrollment model – will come from PaymentsView in PR2
      }
    }

    final attendanceRate = totalSessions > 0 ? attendedSessions / totalSessions : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text("Reports",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1B3D2F), Color(0xFF2D5A46)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.description, color: Colors.white, size: 40),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text("My Reports", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            SizedBox(height: 4),
                            Text("Summary for current term", style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Attendance Report Card
                  _buildReportCard(
                    title: "Attendance Report",
                    icon: Icons.fact_check,
                    color: const Color(0xFF1B3D2F),
                    children: [
                      _reportRow("Sessions Attended", "$attendedSessions"),
                      _reportRow("Total Sessions", "$totalSessions"),
                      _reportRow("Attendance Rate", "${(attendanceRate * 100).toStringAsFixed(1)}%"),
                      _progressRow("Rate", attendanceRate, const Color(0xFF1B3D2F)),
                      const SizedBox(height: 4),
                      _statusChip(
                        attendanceRate >= 0.75 ? "On Track" : "Needs Improvement",
                        attendanceRate >= 0.75 ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Fee Report Card
                  _buildReportCard(
                    title: "Payment Summary",
                    icon: Icons.account_balance_wallet,
                    color: const Color(0xFF1565C0),
                    children: [
                      _reportRow("Total Paid", "₹${totalPaid.toStringAsFixed(0)}"),
                      _reportRow("Total Due", "₹${totalDue.toStringAsFixed(0)}"),
                      _reportRow("Total Fees", "₹${(totalPaid + totalDue).toStringAsFixed(0)}"),
                      const SizedBox(height: 8),
                      _statusChip(
                        totalDue > 0 ? "Payment Pending" : "Fully Paid",
                        totalDue > 0 ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Batch-wise breakdown
                  if (data != null && data.currentEnrollments.isNotEmpty) ...[
                    const Text("Batch-wise Breakdown",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    ...data.currentEnrollments.map((e) => _batchCard(e)),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _reportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _progressRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: value,
          backgroundColor: color.withOpacity(0.1),
          color: color,
          minHeight: 8,
        ),
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _batchCard(StudentEnrollment e) {
    final attended = e.sessionsAttended;
    final total = e.totalSessions ?? 0;
    final rate = total > 0 ? attended / total : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(e.batchName.isNotEmpty ? e.batchName : "—",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text("${e.branchName}",
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("$attended / $total sessions", style: const TextStyle(fontSize: 12)),
              Text("${(rate * 100).toInt()}%",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B3D2F))),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate,
              backgroundColor: const Color(0xFF1B3D2F).withOpacity(0.1),
              color: const Color(0xFF1B3D2F),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}
