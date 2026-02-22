// lib/screens/coach/coach_match_screen.dart
//
// Score a match: coach selects sport, format, importance, date and two players
// (or four for doubles), enters set scores, submits → backend recalculates
// DUPR ratings and returns the updated values.

import 'package:flutter/material.dart';
import 'package:sportsverse_app/api/coach_api.dart';

const Color _kGreen = Color(0xFF1B3D2F);

class CoachMatchScreen extends StatefulWidget {
  const CoachMatchScreen({super.key});

  @override
  State<CoachMatchScreen> createState() => _CoachMatchScreenState();
}

class _CoachMatchScreenState extends State<CoachMatchScreen> {
  // Students loaded for player selection
  late Future<List<CoachStudent>> _studentFuture;
  List<CoachStudent> _students = [];

  // Form state
  String _format = 'SINGLES';
  String _importance = 'CASUAL';
  DateTime _matchDate = DateTime.now();

  // Selected players (by user_id)
  int? _p1Id, _p2Id, _p3Id, _p4Id;
  String _p1Name = 'Player 1', _p2Name = 'Player 2';


  // Sets: list of [p1_games, p2_games]
  final List<List<int>> _sets = [[0, 0]];

  // Winner (only needed for singles)
  int? _winnerId;

  bool _submitting = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _studentFuture = coachApi.getCoachStudents();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _matchDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _matchDate = picked);
  }

  String get _dateStr =>
      '${_matchDate.year}-${_matchDate.month.toString().padLeft(2, '0')}-${_matchDate.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    // Basic validation
    if (_p1Id == null || _p2Id == null) {
      _snack('Please select both players.', isError: true);
      return;
    }
    if (_format == 'DOUBLES' && (_p3Id == null || _p4Id == null)) {
      _snack('Please select all four players for doubles.', isError: true);
      return;
    }
    if (_p1Id == _p2Id) {
      _snack('Players must be different.', isError: true);
      return;
    }

    // Determine winner from set scores
    final p1SetsWon = _sets.where((s) => s[0] > s[1]).length;
    final p2SetsWon = _sets.where((s) => s[1] > s[0]).length;
    if (p1SetsWon == p2SetsWon) {
      _snack('Match must have a clear winner (one side must win more sets).', isError: true);
      return;
    }

    _winnerId = p1SetsWon > p2SetsWon ? _p1Id : _p2Id;

    final sets = _sets.map((s) => [s[0], s[1]]).toList();
    final payload = <String, dynamic>{
      'sport_id': null, // backend will pick from org context — sent as null for now
      'date': _dateStr,
      'format': _format,
      'importance': _importance,
      'player1_id': _p1Id,
      'player2_id': _p2Id,
      'score': {'sets': sets, 'winner_id': _winnerId, 'p1_sets': p1SetsWon, 'p2_sets': p2SetsWon},
    };
    if (_format == 'DOUBLES') {
      payload['player3_id'] = _p3Id;
      payload['player4_id'] = _p4Id;
    }

    setState(() { _submitting = true; _result = null; });
    try {
      final res = await coachApi.submitMatch(payload);
      if (!mounted) return;
      setState(() => _result = res.raw);
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : _kGreen,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: const Text('Score a Match',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<List<CoachStudent>>(
        future: _studentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          if (_students.isEmpty && (snapshot.data ?? []).isNotEmpty) {
            _students = snapshot.data!;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Format ───────────────────────────────────────────────────
                _sectionTitle('Match Format'),
                const SizedBox(height: 8),
                Row(
                  children: ['SINGLES', 'DOUBLES'].map((f) {
                    final selected = _format == f;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _format = f),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: selected ? _kGreen : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: selected ? _kGreen : Colors.grey.shade300),
                            ),
                            child: Center(
                              child: Text(f,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: selected ? Colors.white : Colors.black87)),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // ── Importance ───────────────────────────────────────────────
                _sectionTitle('Importance'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['CASUAL', 'LEAGUE', 'TOURNAMENT'].map((imp) {
                    final selected = _importance == imp;
                    return GestureDetector(
                      onTap: () => setState(() => _importance = imp),
                      child: Chip(
                        label: Text(imp, style: TextStyle(color: selected ? Colors.white : Colors.black87)),
                        backgroundColor: selected ? _kGreen : Colors.grey.shade200,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // ── Date ─────────────────────────────────────────────────────
                _sectionTitle('Match Date'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18, color: _kGreen),
                        const SizedBox(width: 8),
                        Text(_dateStr, style: const TextStyle(fontSize: 14)),
                        const Spacer(),
                        const Icon(Icons.edit, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Player selection ─────────────────────────────────────────
                _sectionTitle(_format == 'SINGLES' ? 'Players' : 'Team A'),
                const SizedBox(height: 8),
                _playerPicker('Player 1', _p1Id, (id, name) => setState(() { _p1Id = id; _p1Name = name; })),
                const SizedBox(height: 10),
                _playerPicker('Player 2', _p2Id, (id, name) => setState(() { _p2Id = id; _p2Name = name; })),
                if (_format == 'DOUBLES') ...[
                  const SizedBox(height: 16),
                  _sectionTitle('Team B'),
                  const SizedBox(height: 8),
                  _playerPicker('Player 3', _p3Id, (id, name) => setState(() { _p3Id = id; })),

                  const SizedBox(height: 10),
                  _playerPicker('Player 4', _p4Id, (id, name) => setState(() { _p4Id = id; })),

                ],
                const SizedBox(height: 20),

                // ── Set scores ───────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionTitle('Set Scores'),
                    TextButton.icon(
                      onPressed: () => setState(() => _sets.add([0, 0])),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Set'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _p1Name,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('vs', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ),
                      Expanded(
                        child: Text(
                          _p2Name,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Align with the remove IconButton (36px)
                      const SizedBox(width: 36),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                ..._sets.asMap().entries.map((entry) {
                  final i = entry.key;
                  final s = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _scoreInput(s[0], (v) => setState(() => s[0] = v)),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('–', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                        Expanded(
                          child: _scoreInput(s[1], (v) => setState(() => s[1] = v)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                          onPressed: _sets.length > 1
                              ? () => setState(() => _sets.removeAt(i))
                              : null,
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 28),

                // ── Result ───────────────────────────────────────────────────
                if (_result != null) _buildResult(_result!),

                // ── Submit ───────────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _submitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Submit & Calculate DUPR',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _kGreen));

  Widget _playerPicker(String label, int? currentId, void Function(int, String) onSelect) {
    return DropdownButtonFormField<int>(
      value: currentId,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      hint: Text('Select $label'),
      items: _students.map((s) {
        return DropdownMenuItem<int>(
          value: s.userId,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              '${s.displayName} (@${s.username})',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        );
      }).toList(),
      onChanged: (id) {
        if (id == null) return;
        final s = _students.firstWhere((s) => s.userId == id);
        onSelect(id, s.displayName);
      },
    );
  }

  Widget _scoreInput(int value, void Function(int) onChange) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: value > 0 ? () => onChange(value - 1) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => onChange(value + 1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(Map<String, dynamic> result) {
    final format = result['format'] as String? ?? '';
    Widget content;

    if (format == 'SINGLES') {
      final p1 = result['player1'] as Map? ?? {};
      final p2 = result['player2'] as Map? ?? {};
      content = Column(
        children: [
          _playerResultTile(p1),
          const SizedBox(height: 8),
          _playerResultTile(p2),
        ],
      );
    } else {
      final players = (result['players'] as List? ?? []);
      content = Column(
        children: players.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _playerResultTile(p as Map),
        )).toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('⭐ DUPR Rating Update',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _kGreen)),
        const SizedBox(height: 10),
        content,
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _playerResultTile(Map p) {
    final delta = (p['delta'] as num? ?? 0).toDouble();
    final newRating = (p['new_rating'] as num? ?? 0).toDouble();
    final isWin = delta >= 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isWin ? Colors.green.shade200 : Colors.red.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isWin ? Colors.green.shade50 : Colors.red.shade50,
            child: Icon(isWin ? Icons.trending_up : Icons.trending_down,
                color: isWin ? Colors.green : Colors.red, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(p['username'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(newRating.toStringAsFixed(3),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${isWin ? '+' : ''}${delta.toStringAsFixed(3)}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isWin ? Colors.green.shade700 : Colors.red.shade700)),
            ],
          ),
        ],
      ),
    );
  }
}
