// lib/screens/academy_admin/coach_dashboard_screen.dart
//
// Full coach dashboard with:
//   • KPI cards: upcoming sessions, 30-day attendance, pending salary
//   • Next-7-sessions list
//   • Per-batch attendance bar chart (pure Flutter, no extra dep)
//   • Responsive layout via LayoutBuilder (mobile single-col, tablet two-col)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportsverse_app/api/coach_api.dart';
import 'package:sportsverse_app/providers/auth_provider.dart';

// ─── break-point ──────────────────────────────────────────────────────────────
const double _kTabletBreak = 600.0;

class CoachDashboardScreen extends StatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  State<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends State<CoachDashboardScreen> {
  late Future<CoachDashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = coachApi.getCoachDashboard();
  }

  void _refresh() {
    setState(() {
      _dashboardFuture = coachApi.getCoachDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coach Dashboard',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (user != null)
              Text(
                '${user.firstName} ${user.lastName}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white70),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              auth.logout();
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: FutureBuilder<CoachDashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorView(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }
          final data = snapshot.data!;
          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= _kTabletBreak;
              return RefreshIndicator(
                onRefresh: () async => _refresh(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: wide
                      ? _WideLayout(data: data)
                      : _NarrowLayout(data: data),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Narrow layout (mobile): single column ────────────────────────────────────
class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({required this.data});
  final CoachDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _KpiRow(data: data),
        const SizedBox(height: 16),
        _SessionsCard(sessions: data.upcomingSessions),
        const SizedBox(height: 16),
        _AttendanceCard(summary: data.attendanceSummary),
        const SizedBox(height: 16),
        _AssignmentsCard(assignments: data.assignments),
      ],
    );
  }
}

// ─── Wide layout (tablet/desktop): two columns ────────────────────────────────
class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.data});
  final CoachDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _KpiRow(data: data),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _SessionsCard(sessions: data.upcomingSessions)),
            const SizedBox(width: 16),
            Expanded(child: _AttendanceCard(summary: data.attendanceSummary)),
          ],
        ),
        const SizedBox(height: 16),
        _AssignmentsCard(assignments: data.assignments),
      ],
    );
  }
}

// ─── KPI Row ──────────────────────────────────────────────────────────────────
class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.data});
  final CoachDashboardData data;

  @override
  Widget build(BuildContext context) {
    final currency = data.pendingSalary.currency;
    final salary = data.pendingSalary.amount;
    final salaryText =
        salary > 0 ? '$currency${salary.toStringAsFixed(0)}' : 'Up to date';

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _KpiCard(
          icon: Icons.calendar_today,
          color: const Color(0xFF4A90E2),
          label: 'Upcoming Sessions',
          value: data.upcomingSessions.length.toString(),
        ),
        _KpiCard(
          icon: Icons.how_to_reg,
          color: const Color(0xFF27AE60),
          label: 'Attendance (30d)',
          value: data.attendanceSummary.last30Days.toString(),
        ),
        _KpiCard(
          icon: Icons.account_balance_wallet,
          color: salary > 0 ? const Color(0xFFE67E22) : const Color(0xFF8E44AD),
          label: 'Pending Salary',
          value: salaryText,
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final width = MediaQuery.of(ctx).size.width;
      // On mobile fill 100%, on tablet ~30% each
      final cardWidth =
          width < _kTabletBreak ? width - 32 : (width - 80) / 3;

      return SizedBox(
        width: cardWidth,
        child: Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                      ),
                      Text(
                        label,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ─── Next 7 sessions ─────────────────────────────────────────────────────────
class _SessionsCard extends StatelessWidget {
  const _SessionsCard({required this.sessions});
  final List<UpcomingSession> sessions;

  @override
  Widget build(BuildContext context) {
    final next7 = sessions.take(7).toList();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
                icon: Icons.upcoming, title: 'Upcoming Sessions'),
            const SizedBox(height: 8),
            if (next7.isEmpty)
              const _EmptyState(message: 'No upcoming sessions')
            else
              ...next7.map((s) => _SessionTile(session: s)),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});
  final UpcomingSession session;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                session.day.isNotEmpty ? session.day.substring(0, 2) : '--',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A90E2),
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.batchName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${session.date}  ${session.time}',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Attendance chart (pure Flutter) ─────────────────────────────────────────
class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.summary});
  final AttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
                icon: Icons.bar_chart, title: 'Attendance – Last 30 Days'),
            const SizedBox(height: 4),
            Text(
              'Total: ${summary.last30Days} sessions',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (summary.byBatch.isEmpty)
              const _EmptyState(message: 'No attendance data')
            else
              _HorizontalBarChart(batches: summary.byBatch),
          ],
        ),
      ),
    );
  }
}

class _HorizontalBarChart extends StatelessWidget {
  const _HorizontalBarChart({required this.batches});
  final List<BatchAttendanceSummary> batches;

  @override
  Widget build(BuildContext context) {
    final max = batches
        .map((b) => b.count)
        .fold(0, (a, b) => a > b ? a : b)
        .toDouble();

    return Column(
      children: batches.map((b) {
        final fraction = max > 0 ? b.count / max : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      b.batchName,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${b.count}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LayoutBuilder(builder: (ctx, constraints) {
                return Container(
                  height: 10,
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: fraction,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF27AE60),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Assignments ──────────────────────────────────────────────────────────────
class _AssignmentsCard extends StatelessWidget {
  const _AssignmentsCard({required this.assignments});
  final List<CoachAssignmentSummary> assignments;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
                icon: Icons.assignment, title: 'My Batches'),
            const SizedBox(height: 8),
            if (assignments.isEmpty)
              const _EmptyState(message: 'No batches assigned yet')
            else
              ...assignments.map((a) => _AssignmentTile(assignment: a)),
          ],
        ),
      ),
    );
  }
}

class _AssignmentTile extends StatelessWidget {
  const _AssignmentTile({required this.assignment});
  final CoachAssignmentSummary assignment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.sports, color: Color(0xFF8E44AD), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.batchName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${assignment.sport} · ${assignment.branch}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.grey.shade500),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              message.replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}