// lib/screens/student/student_ratings_screen.dart

import 'package:flutter/material.dart';
import 'package:sportsverse_app/api/student_api.dart';
import 'package:sportsverse_app/api/coach_api.dart';
import 'package:sportsverse_app/models/student_models.dart';
import 'package:sportsverse_app/screens/coach/coach_ratings_screen.dart';

class StudentRatingsScreen extends StatefulWidget {
  const StudentRatingsScreen({super.key});

  @override
  State<StudentRatingsScreen> createState() => _StudentRatingsScreenState();
}

class _StudentRatingsScreenState extends State<StudentRatingsScreen> {
  late Future<StudentDashboardData> _dashboardFuture;
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = StudentApi.getDashboardData();
    _historyFuture = coachApi.getMyRatingHistory();
  }

  @override
  Widget build(BuildContext context) {
    const Color kGreen = Color(0xFF1B3D2F);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: const Text('My DUPR Rating',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _dashboardFuture = StudentApi.getDashboardData();
            _historyFuture = coachApi.getMyRatingHistory();
          });
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Rating Cards ───────────────────────────────────────────────
              FutureBuilder<StudentDashboardData>(
                future: _dashboardFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _RatingLoadingCard();
                  }
                  if (snapshot.hasError) {
                    return _ErrorCard(error: snapshot.error.toString());
                  }
                  final data = snapshot.data!;
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _RatingCard(
                              label: 'Singles',
                              rating: data.duprSinglesRating,
                              matches: data.duprMatchesSingles,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _RatingCard(
                              label: 'Doubles',
                              rating: data.duprDoublesRating,
                              matches: data.duprMatchesDoubles,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ReliabilityCard(reliability: data.duprReliability),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // ── Leaderboard Button ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CoachRatingsScreen()),
                    );
                  },
                  icon: const Icon(Icons.leaderboard),
                  label: const Text('View Organization Leaderboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Rating History ──────────────────────────────────────────────
              const Text('Rating History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final history = snapshot.data ?? [];
                  if (history.isEmpty) {
                    return const _EmptyHistoryCard();
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final item = history[index];
                      return _HistoryTile(item: item);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  final String label;
  final double rating;
  final int matches;
  final Color color;

  const _RatingCard({
    required this.label,
    required this.rating,
    required this.matches,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(
            rating.toStringAsFixed(3),
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text('$matches Matches', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _ReliabilityCard extends StatelessWidget {
  final double reliability;

  const _ReliabilityCard({required this.reliability});

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(Colors.red, Colors.green, reliability / 100) ?? Colors.green;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Rating Reliability', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${reliability.toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: reliability / 100,
              minHeight: 12,
              backgroundColor: Colors.grey.shade100,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep playing verified matches to increase your rating accuracy.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Map<String, dynamic> item;

  const _HistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final delta = item['delta'] as double;
    final isPos = delta >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPos ? Colors.green.shade50 : Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPos ? Icons.trending_up : Icons.trending_down,
              color: isPos ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['format']} Match',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  item['date'],
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                (item['new_rating'] as double).toStringAsFixed(3),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '${isPos ? '+' : ''}${delta.toStringAsFixed(3)}',
                style: TextStyle(
                  color: isPos ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RatingLoadingCard extends StatelessWidget {
  const _RatingLoadingCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  const _ErrorCard({required this.error});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
      child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
    );
  }
}

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: const Center(child: Text('No rating history yet.', style: TextStyle(color: Colors.grey))),
    );
  }
}
