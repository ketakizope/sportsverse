// lib/screens/coach/coach_attendance_screen.dart
//
// Coach picks a batch, picks a date, sees the student roster, toggles
// present/absent, then submits. Session deduction happens automatically
// on the backend via Attendance.save().

import 'package:flutter/material.dart';
import 'package:sportsverse_app/api/coach_api.dart';

const Color _kGreen = Color(0xFF1B3D2F);

class CoachAttendanceScreen extends StatefulWidget {
  const CoachAttendanceScreen({super.key});

  @override
  State<CoachAttendanceScreen> createState() => _CoachAttendanceScreenState();
}

class _CoachAttendanceScreenState extends State<CoachAttendanceScreen> {
  // Step 1: load all students grouped by batch
  late Future<List<CoachStudent>> _studentFuture;

  // Selected batch
  int? _selectedBatchId;
  Map<int, List<CoachStudent>> _byBatch = {}; // batchId → students
  List<int> _batchIds = [];
  List<String> _batchNames = [];

  // Step 2: attendance state
  DateTime _selectedDate = DateTime.now();
  Map<int, bool> _presence = {}; // enrollmentId → present

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _studentFuture = coachApi.getCoachStudents();
  }

  void _onStudentsLoaded(List<CoachStudent> students) {
    final map = <int, List<CoachStudent>>{};
    for (final s in students) {
      map.putIfAbsent(s.batchId, () => []).add(s);
    }
    _byBatch = map;
    _batchIds = map.keys.toList();
    final first = students;
    _batchNames = _batchIds.map((id) => first.firstWhere((s) => s.batchId == id).batchName).toList();

    if (_batchIds.isNotEmpty && _selectedBatchId == null) {
      _selectedBatchId = _batchIds.first;
      _initPresence();
    }
  }

  void _initPresence() {
    final students = _byBatch[_selectedBatchId] ?? [];
    _presence = {for (final s in students) s.enrollmentId: true};
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (_selectedBatchId == null) return;

    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final records = _presence.entries
        .map((e) => {'enrollment_id': e.key, 'present': e.value})
        .toList();

    setState(() => _submitting = true);
    try {
      final result = await coachApi.markAttendance(
        batchId: _selectedBatchId!,
        date: dateStr,
        records: records,
      );
      if (!mounted) return;
      final created = result['created'] ?? 0;
      final skipped = result['skipped_duplicates'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Attendance saved: $created marked, $skipped duplicates skipped'),
          backgroundColor: _kGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: const Text('Take Attendance',
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
            return Center(
              child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
            );
          }
          final students = snapshot.data ?? [];
          if (students.isEmpty) {
            return const Center(child: Text('No students found in your batches.'));
          }
          if (_byBatch.isEmpty) {
            _onStudentsLoaded(students);
          }

          final batchStudents = _byBatch[_selectedBatchId] ?? [];

          return Column(
            children: [
              // ── Controls bar ─────────────────────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Batch picker
                    DropdownButtonFormField<int>(
                      value: _selectedBatchId,
                      decoration: InputDecoration(
                        labelText: 'Select Batch',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: _batchIds.asMap().entries.map((e) {
                        return DropdownMenuItem<int>(
                          value: e.value,
                          child: Text(_batchNames[e.key]),
                        );
                      }).toList(),
                      onChanged: (id) {
                        setState(() {
                          _selectedBatchId = id;
                          _initPresence();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    // Date picker
                    InkWell(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: _kGreen),
                            const SizedBox(width: 8),
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const Spacer(),
                            const Icon(Icons.edit, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Mark all row ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${batchStudents.length} students',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: _kGreen)),
                    TextButton(
                      onPressed: () => setState(() {
                        final allPresent = _presence.values.every((v) => v);
                        for (final key in _presence.keys) {
                          _presence[key] = !allPresent;
                        }
                      }),
                      child: const Text('Toggle All'),
                    ),
                  ],
                ),
              ),

              // ── Student list ─────────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: batchStudents.length,
                  itemBuilder: (context, index) {
                    final s = batchStudents[index];
                    final isPresent = _presence[s.enrollmentId] ?? true;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isPresent ? _kGreen.withOpacity(0.3) : Colors.red.shade100,
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: isPresent
                                  ? _kGreen.withOpacity(0.12)
                                  : Colors.red.shade50,
                              child: Text(
                                s.displayName.isNotEmpty
                                    ? s.displayName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isPresent ? _kGreen : Colors.red.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.displayName,
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text('@${s.username}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            // Present / Absent toggle
                            GestureDetector(
                              onTap: () => setState(() {
                                _presence[s.enrollmentId] = !isPresent;
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isPresent ? _kGreen : Colors.red.shade600,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isPresent ? 'Present' : 'Absent',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── Submit button ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
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
                        : const Text('Submit Attendance',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
