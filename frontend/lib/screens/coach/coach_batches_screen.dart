// lib/screens/coach/coach_batches_screen.dart
//
// Detailed view of all batches assigned to this coach,
// showing schedule, sport, branch, and enrolled student count.

import 'package:flutter/material.dart';
import 'package:sportsverse_app/api/coach_api.dart';

const Color _kGreen = Color(0xFF1B3D2F);

class CoachBatchesScreen extends StatefulWidget {
  const CoachBatchesScreen({super.key});

  @override
  State<CoachBatchesScreen> createState() => _CoachBatchesScreenState();
}

class _CoachBatchesScreenState extends State<CoachBatchesScreen> {
  late Future<CoachDashboardData> _dashFuture;
  late Future<List<CoachStudent>> _studentFuture;

  @override
  void initState() {
    super.initState();
    _dashFuture = coachApi.getCoachDashboard();
    _studentFuture = coachApi.getCoachStudents();
  }

  String _formatSchedule(Map<String, dynamic>? schedule) {
    if (schedule == null || schedule.isEmpty) return 'Schedule not set';
    final days = (schedule['days'] as List?)?.join(', ') ?? '—';
    final start = schedule['start_time'] ?? '';
    final end = schedule['end_time'] ?? '';
    return '$days  $start–$end';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: const Text('My Batches',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => setState(() {
              _dashFuture = coachApi.getCoachDashboard();
              _studentFuture = coachApi.getCoachStudents();
            }),
            icon: const Icon(Icons.refresh, color: Colors.black),
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([_dashFuture, _studentFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          }

          final data = snapshot.data![0] as CoachDashboardData;
          final students = snapshot.data![1] as List<CoachStudent>;

          // Count students per batch
          final countByBatch = <int, int>{};
          for (final s in students) {
            countByBatch[s.batchId] = (countByBatch[s.batchId] ?? 0) + 1;
          }

          if (data.assignments.isEmpty) {
            return const Center(
              child: Text('No batches assigned yet.',
                  style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.assignments.length,
            itemBuilder: (context, index) {
              final a = data.assignments[index];
              final studentCount = countByBatch[a.batchId] ?? 0;
              final scheduleStr = _formatSchedule(a.schedule);

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header gradient bar
                      Container(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_kGreen, Color(0xFF2D5A46)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sports_tennis, color: Colors.white, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(a.batchName,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(a.sport,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      // Body
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _infoRow(Icons.location_on_outlined, 'Branch', a.branch),
                            const SizedBox(height: 10),
                            _infoRow(Icons.schedule_outlined, 'Schedule', scheduleStr),
                            const SizedBox(height: 10),
                            _infoRow(
                                Icons.group_outlined,
                                'Students',
                                '$studentCount enrolled'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
