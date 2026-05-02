// lib/screens/coach/coach_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportsverse_app/api/coach_api.dart';
import 'package:sportsverse_app/providers/auth_provider.dart';
import 'package:sportsverse_app/providers/chatbot_provider.dart';
import 'package:sportsverse_app/screens/coach/coach_attendance_screen.dart';
import 'package:sportsverse_app/screens/coach/coach_batches_screen.dart';
import 'package:sportsverse_app/screens/coach/coach_ratings_screen.dart';
import 'package:sportsverse_app/theme/elite_theme.dart';
import 'package:sportsverse_app/widgets/ai_bot_sheet.dart';
import 'package:sportsverse_app/widgets/elite_card.dart';
import 'package:sportsverse_app/widgets/glass_header.dart';

class CoachDashboardScreen extends StatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  State<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends State<CoachDashboardScreen> {
  late Future<CoachDashboardData> _future;
  Widget? _currentContent;

  @override
  void initState() {
    super.initState();
    _future = coachApi.getCoachDashboard();
  }

  void _refresh() => setState(() {
        _future = coachApi.getCoachDashboard();
      });

  void _go(Widget screen) {
    setState(() => _currentContent = screen);
    if (Scaffold.maybeOf(context)?.hasDrawer ?? false) {
      Navigator.pop(context);
    }
  }

  void _logout() async {
    await context.read<ChatbotProvider>().onLogout();
    if (!mounted) return;
    if (Scaffold.maybeOf(context)?.hasDrawer ?? false) Navigator.pop(context);
    Provider.of<AuthProvider>(context, listen: false).logout();
    if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final theme = EliteTheme.of(context);

    return Builder(
      builder: (innerContext) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isDesktop = constraints.maxWidth >= 900;

            return Scaffold(
              backgroundColor: theme.surface,
              drawer: isDesktop ? null : _buildDrawer(innerContext, user, theme),
              appBar: isDesktop ? null : AppBar(
                title: Text(
                  'Coach Dashboard',
                  style: theme.heading.copyWith(color: theme.primary),
                ),
                backgroundColor: theme.surfaceContainerLowest,
                elevation: 0.5,
                iconTheme: IconThemeData(color: theme.primary),
                actions: [
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _refresh,
                    icon: Icon(Icons.refresh, color: theme.primary),
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                backgroundColor: theme.primary,
                tooltip: 'AI Assistant',
                onPressed: () {
                  final auth = context.read<AuthProvider>();
                  context.read<ChatbotProvider>().initialize(auth);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    builder: (_) => const AIBotSheet(),
                  );
                },
                child: Icon(Icons.smart_toy_rounded, color: theme.accent),
              ),
              body: Row(
                children: [
                  if (isDesktop) _buildDrawer(innerContext, user, theme, isDesktop: true),
                  Expanded(
                    child: _currentContent ?? _buildDashboardBody(theme, user),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildDashboardBody(EliteTheme theme, dynamic user) {
    return FutureBuilder<CoachDashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: theme.primary));
        }
        if (snapshot.hasError) {
          return _ErrorRetry(
            message: snapshot.error.toString().replaceFirst('Exception: ', ''),
            onRetry: _refresh,
          );
        }
        final data = snapshot.data!;
        return RefreshIndicator(
          color: theme.primary,
          backgroundColor: theme.surfaceContainerLowest,
          onRefresh: () async => _refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                Text(
                  "Hello, ${data.coachProfile.fullName.isNotEmpty ? data.coachProfile.fullName : user?.username ?? 'Coach'} 👋",
                  style: theme.display2.copyWith(color: theme.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  data.coachProfile.specialization.isNotEmpty
                      ? data.coachProfile.specialization
                      : data.coachProfile.organizationName,
                  style: theme.body.copyWith(color: theme.secondaryText),
                ),
                const SizedBox(height: 32),

                // KPI cards
                LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isMobile = constraints.maxWidth < 600;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: isMobile ? constraints.maxWidth : (constraints.maxWidth - 16) / 2,
                          child: _KpiCard(
                            icon: Icons.calendar_today,
                            color: theme.accent, // Lime
                            label: 'Upcoming Sessions',
                            value: data.upcomingSessions.length.toString(),
                            theme: theme,
                          ),
                        ),
                        SizedBox(
                          width: isMobile ? constraints.maxWidth : (constraints.maxWidth - 16) / 2,
                          child: _KpiCard(
                            icon: Icons.how_to_reg,
                            color: theme.primary, // Navy
                            label: 'Attendance (30d)',
                            value: data.attendanceSummary.last30Days.toString(),
                            theme: theme,
                          ),
                        ),
                        SizedBox(
                          width: isMobile ? constraints.maxWidth : (constraints.maxWidth - 16) / 2,
                          child: _KpiCard(
                            icon: Icons.sports,
                            color: theme.primary,
                            label: 'My Batches',
                            value: data.assignments.length.toString(),
                            theme: theme,
                          ),
                        ),
                        SizedBox(
                          width: isMobile ? constraints.maxWidth : (constraints.maxWidth - 16) / 2,
                          child: _KpiCard(
                            icon: Icons.star,
                            color: theme.accent,
                            label: 'Quick Actions',
                            value: 'Tap Sidebar',
                            isAction: true,
                            theme: theme,
                          ),
                        ),
                      ],
                    );
                  }
                ),
                const SizedBox(height: 32),

                // Upcoming sessions list
                Text('Upcoming Sessions', style: theme.heading.copyWith(color: theme.primary)),
                const SizedBox(height: 16),
                if (data.upcomingSessions.isEmpty)
                  const _EmptyState(message: 'No upcoming sessions this week')
                else
                  ...data.upcomingSessions.take(5).map((s) => _SessionTile(session: s, theme: theme)),

                const SizedBox(height: 32),

                // Batch list
                Text('My Batches', style: theme.heading.copyWith(color: theme.primary)),
                const SizedBox(height: 16),
                if (data.assignments.isEmpty)
                  const _EmptyState(message: 'No batches assigned yet')
                else
                  ...data.assignments.map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _BatchCard(assignment: a, theme: theme),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Drawer ─────────────────────────────────────────────────────────────────

  Widget _buildDrawer(BuildContext context, dynamic user, EliteTheme theme, {bool isDesktop = false}) {
    final username = user?.username ?? 'Coach';
    final email    = user?.email    ?? '';

    final drawer = Container(
      width: 280,
      color: theme.primary,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20, right: 20),
            color: theme.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.accent,
                  child: Icon(Icons.sports_tennis, color: theme.primary, size: 32),
                ),
                const SizedBox(height: 16),
                Text(username, style: theme.heading.copyWith(color: theme.surfaceContainerLowest)),
                Text(email, style: theme.caption.copyWith(color: theme.surfaceContainerLowest.withValues(alpha: 0.7))),
              ],
            ),
          ),
          _tile(theme, Icons.dashboard, 'Dashboard', () => setState(() => _currentContent = null), isSelected: _currentContent == null),
          _tile(theme, Icons.fact_check, 'Attendance', () => _go(const CoachAttendanceScreen())),
          _tile(theme, Icons.sports, 'My Batches', () => _go(const CoachBatchesScreen())),
          _tile(theme, Icons.star, 'DUPR Ratings', () => _go(const CoachRatingsScreen())),
          const Divider(color: Colors.white24, height: 32),
          _tile(theme, Icons.logout, 'Logout', _logout, isLogout: true),
        ],
      ),
    );

    return isDesktop ? drawer : Drawer(child: drawer);
  }

  Widget _tile(EliteTheme theme, IconData icon, String title, VoidCallback onTap, {bool isLogout = false, bool isSelected = false}) {
    final color = isLogout ? theme.error : (isSelected ? theme.accent : theme.surfaceContainerLowest);
    return ListTile(
      leading: Icon(icon, color: color.withValues(alpha: isSelected || isLogout ? 1.0 : 0.7)),
      title: Text(title,
          style: theme.body.copyWith(
              color: color.withValues(alpha: isSelected || isLogout ? 1.0 : 0.7),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
      onTap: onTap,
    );
  }
}

// ─── KPI Card ─────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.theme,
    this.isAction = false,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool isAction;
  final EliteTheme theme;

  @override
  Widget build(BuildContext context) {
    return EliteCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: theme.heading.copyWith(
                        fontSize: 22,
                        color: isAction ? theme.secondaryText : theme.primary)),
                const SizedBox(height: 4),
                Text(label,
                    style: theme.caption.copyWith(color: theme.secondaryText),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Session Tile ─────────────────────────────────────────────────────────────

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.theme});
  final UpcomingSession session;
  final EliteTheme theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: EliteCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  session.day.length >= 2 ? session.day.substring(0, 2).toUpperCase() : session.day,
                  style: theme.subtitle.copyWith(color: theme.primary),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.batchName,
                      style: theme.body.copyWith(fontWeight: FontWeight.w600, color: theme.primary),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('${session.date}  ${session.time}',
                      style: theme.caption.copyWith(color: theme.secondaryText)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Batch Card ───────────────────────────────────────────────────────────────

class _BatchCard extends StatelessWidget {
  const _BatchCard({required this.assignment, required this.theme});
  final CoachAssignmentSummary assignment;
  final EliteTheme theme;

  @override
  Widget build(BuildContext context) {
    return EliteCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.sports_tennis, color: theme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(assignment.batchName,
                    style: theme.body.copyWith(fontWeight: FontWeight.w600, color: theme.primary)),
                const SizedBox(height: 4),
                Text('${assignment.sport} · ${assignment.branch}',
                    style: theme.caption.copyWith(color: theme.secondaryText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = EliteTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(message, style: theme.body.copyWith(color: theme.secondaryText)),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = EliteTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: theme.body.copyWith(color: theme.secondaryText)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: theme.surfaceContainerLowest,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
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
