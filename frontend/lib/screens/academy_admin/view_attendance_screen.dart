import 'package:flutter/material.dart';
import 'dart:convert';                                       // <--- added
import 'package:sportsverse_app/api/api_client.dart';       // <--- added

class ViewAttendanceScreen extends StatefulWidget {
  const ViewAttendanceScreen({super.key});

  @override
  State<ViewAttendanceScreen> createState() => _ViewAttendanceScreenState();
}

class _ViewAttendanceScreenState extends State<ViewAttendanceScreen> {
  bool _showReport = false;

  // NEW -- dropdown selections
  String? _selectedBranch;
  String? _selectedBatch;
  String? _selectedStudent;
  String? _selectedTimeline;

  // NEW -- dynamic lists to populate dropdowns
  List<dynamic> _branches = [];
  List<dynamic> _batches = [];
  List<dynamic> _students = [];

  // NEW -- attendance records
  List<dynamic> _attendanceRecords = [];

  @override
  void initState() {
    super.initState();
    _fetchBranches(); // initial load
  }

  Future<void> _fetchBranches() async {
    final response = await apiClient.get('/organizations/branches/');
    if (response.statusCode == 200) {
      setState(() {
        _branches = jsonDecode(response.body);
      });
    }
  }

  Future<void> _fetchBatches(String branchId) async {
    final response =
        await apiClient.get('/organizations/batches/?branch=$branchId');
    if (response.statusCode == 200) {
      setState(() {
        _batches = jsonDecode(response.body);
      });
    }
  }

  Future<void> _fetchStudents(String batchId) async {
    final response =
        await apiClient.get('/organizations/enrollments/?batch=$batchId');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // enrollment endpoint returns enrollment, so we extract student name
      setState(() {
        _students =
            data.map((e) => e['student']).toList(); // list of student objects
      });
    }
  }

  Future<void> _viewAttendance() async {
    // NOTE: normally you'd pass studentId and timeline to your backend
    final response = await apiClient.get(
        '/organizations/attendance/?student=$_selectedStudent&batch=$_selectedBatch');
    if (response.statusCode == 200) {
      setState(() {
        _attendanceRecords = jsonDecode(response.body);
        _showReport = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Student Attendance Report',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 4.0,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF006C62),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12.0),
                        topRight: Radius.circular(12.0),
                      ),
                    ),
                    child: const Text(
                      'Student Attendance Report',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ---- BRANCH DROPDOWN (dynamic)
                        _DropdownInput(
                          label: 'Branch',
                          hint: 'Select Branch',
                          icon: Icons.school,
                          items: _branches
                              .map<String>((b) => b['id'].toString())
                              .toList(),
                          onChanged: (value) async {
                            setState(() {
                              _selectedBranch = value;
                              _selectedBatch = null;
                              _selectedStudent = null;
                              _batches = [];
                              _students = [];
                              _showReport = false;
                              _attendanceRecords = [];
                            });
                            if (value != null) {
                              await _fetchBatches(value);
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        // ---- BATCH DROPDOWN (dynamic)
                        _DropdownInput(
                          label: 'Batch',
                          hint: 'Select Batch',
                          icon: Icons.group,
                          items: _batches
                              .map<String>((b) => b['id'].toString())
                              .toList(),
                          onChanged: (value) async {
                            setState(() {
                              _selectedBatch = value;
                              _selectedStudent = null;
                              _students = [];
                              _showReport = false;
                              _attendanceRecords = [];
                            });
                            if (value != null) {
                              await _fetchStudents(value);
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        // ---- STUDENT DROPDOWN (dynamic)
                        _DropdownInput(
                          label: 'Student',
                          hint: 'Select Student',
                          icon: Icons.person,
                          items: _students
                              .map<String>((s) =>
                                  '${s['first_name']} ${s['last_name']}')
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedStudent = value;
                              _showReport = false;
                              _attendanceRecords = [];
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        // ---- TIMELINE (static options)
                        _DropdownInput(
                          label: 'Timeline',
                          hint: 'Current Month',
                          icon: Icons.calendar_month,
                          items: [
                            'Current Month',
                            'Last 3 Months',
                            'Last 6 Months',
                            'Custom Date Range'
                          ],
                          onChanged: (v) {
                            setState(() => _selectedTimeline = v);
                          },
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: (_selectedBatch != null &&
                                  _selectedStudent != null)
                              ? _viewAttendance
                              : null,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: (_selectedBatch != null &&
                                      _selectedStudent != null)
                                  ? const Color(0xFF006C62)
                                  : Colors.grey,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'View Attendance',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        if (_showReport) _buildAttendanceReport(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFF006C62),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12.0),
              topRight: Radius.circular(12.0),
            ),
          ),
          child: Text(
            'Attendance Records for $_selectedStudent',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('No.')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Status')),
            ],
            rows: _attendanceRecords.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final record = entry.value;
              return DataRow(
                cells: [
                  DataCell(Text(idx.toString())),
                  DataCell(Text(record['date'].toString())),
                  DataCell(Text(record['is_present'] ? 'Present' : 'Absent')),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// reusable dropdown (unchanged except onChanged added)
class _DropdownInput extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final List<String> items;
  final void Function(String?) onChanged;                // <--- added

  const _DropdownInput({
    required this.label,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onChanged,                             // <--- added
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              borderSide: BorderSide(color: Colors.grey),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              borderSide: BorderSide(color: Colors.grey),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onChanged,                           // <--- added
        ),
      ],
    );
  }
}
