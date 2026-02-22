// lib/screens/coach/coach_ratings_screen.dart
//
// DUPR leaderboard for all students in the coach's organization.
// Shows singles & doubles ratings with tier badges, sortable by sport.

import 'package:flutter/material.dart';
import 'package:sportsverse_app/api/coach_api.dart';

const Color _kGreen = Color(0xFF1B3D2F);

String _tier(double rating) {
  if (rating >= 6.0) return 'Elite';
  if (rating >= 4.5) return 'Advanced';
  if (rating >= 3.0) return 'Intermediate';
  return 'Beginner';
}

Color _tierColor(double rating) {
  if (rating >= 6.0) return const Color(0xFFE65100);
  if (rating >= 4.5) return const Color(0xFF2E7D32);
  if (rating >= 3.0) return const Color(0xFF1565C0);
  return const Color(0xFF6A1B9A);
}

class CoachRatingsScreen extends StatefulWidget {
  const CoachRatingsScreen({super.key});

  @override
  State<CoachRatingsScreen> createState() => _CoachRatingsScreenState();
}

class _CoachRatingsScreenState extends State<CoachRatingsScreen> {
  late Future<List<StudentRatingItem>> _future;
  String _sortBy = 'singles'; // 'singles' | 'doubles'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _future = coachApi.getStudentRatings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: const Text('DUPR Ratings',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => setState(() => _future = coachApi.getStudentRatings()),
            icon: const Icon(Icons.refresh, color: Colors.black),
          ),
        ],
      ),
      body: FutureBuilder<List<StudentRatingItem>>(
        future: _future,
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
          var ratings = snapshot.data ?? [];

          // Filter by search
          if (_searchQuery.isNotEmpty) {
            ratings = ratings
                .where((r) =>
                    r.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    r.username.toLowerCase().contains(_searchQuery.toLowerCase()))
                .toList();
          }

          // Sort
          ratings.sort((a, b) => _sortBy == 'singles'
              ? b.duprRatingSingles.compareTo(a.duprRatingSingles)
              : b.duprRatingDoubles.compareTo(a.duprRatingDoubles));

          return Column(
            children: [
              // ── Search + sort controls ────────────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'Search student…',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Sort toggle
                    Column(
                      children: [
                        const Text('Sort by', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ToggleButtons(
                          isSelected: [_sortBy == 'singles', _sortBy == 'doubles'],
                          onPressed: (i) => setState(() => _sortBy = i == 0 ? 'singles' : 'doubles'),
                          borderRadius: BorderRadius.circular(8),
                          selectedColor: Colors.white,
                          fillColor: _kGreen,
                          constraints: const BoxConstraints(minWidth: 60, minHeight: 32),
                          children: const [
                            Text('Singles', style: TextStyle(fontSize: 11)),
                            Text('Doubles', style: TextStyle(fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Leaderboard header ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: Row(
                  children: [
                    const Text('#', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                    const SizedBox(width: 48 + 12),
                    const Expanded(child: Text('Student', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
                    SizedBox(width: 70, child: Text(_sortBy == 'singles' ? 'Singles' : 'Doubles',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
                    const SizedBox(width: 12),
                    const SizedBox(width: 70, child: Text('Reliab.', textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
                  ],
                ),
              ),

              // ── Ratings list ──────────────────────────────────────────────
              Expanded(
                child: ratings.isEmpty
                    ? const Center(child: Text('No students found.', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: ratings.length,
                        itemBuilder: (context, index) {
                          final r = ratings[index];
                          final rating = _sortBy == 'singles'
                              ? r.duprRatingSingles
                              : r.duprRatingDoubles;
                          final tc = _tierColor(rating);
                          final tl = _tier(rating);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Rank
                                  SizedBox(
                                    width: 28,
                                    child: Text(
                                      '#${index + 1}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: index == 0
                                              ? const Color(0xFFFFAB00)
                                              : index == 1
                                                  ? Colors.grey
                                                  : index == 2
                                                      ? const Color(0xFFBF7F29)
                                                      : Colors.black38),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Avatar
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: tc.withOpacity(0.12),
                                    child: Text(
                                      r.displayName.isNotEmpty ? r.displayName[0].toUpperCase() : '?',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: tc,
                                          fontSize: 15),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Name + sport
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(r.displayName,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600, fontSize: 13),
                                            overflow: TextOverflow.ellipsis),
                                        Text(r.sportName,
                                            style: const TextStyle(
                                                fontSize: 11, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                  // Rating + tier
                                  SizedBox(
                                    width: 70,
                                    child: Column(
                                      children: [
                                        Text(
                                          rating.toStringAsFixed(3),
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: tc),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: tc.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(tl,
                                              style: TextStyle(
                                                  fontSize: 9,
                                                  color: tc,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        if (r.isProvisional)
                                          const Text('PROV',
                                              style: TextStyle(
                                                  fontSize: 8,
                                                  color: Colors.orange,
                                                  fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Reliability bar
                                  SizedBox(
                                    width: 70,
                                    child: Column(
                                      children: [
                                        Text('${r.reliability}%',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: r.reliability / 100,
                                            minHeight: 6,
                                            backgroundColor: Colors.grey.shade200,
                                            color: _kGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
