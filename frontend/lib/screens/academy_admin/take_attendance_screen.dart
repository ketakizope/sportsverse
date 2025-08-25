import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sportsverse_app/api/api_client.dart';   // <-- add this
import 'dart:convert';                                 // <-- add this


// A model class to represent a student with their attendance status.
class Student {
  final String name;
  bool isPresent;

  Student({required this.name, this.isPresent = false});
}

class TakeAttendanceScreen extends StatefulWidget {
  const TakeAttendanceScreen({super.key});

  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  // State variables for the screen
  List<Student> _students = [];
  bool _isLoading = false;
  bool _selectAll = false;

  // State variables to hold the selected dropdown values and date
  String? _selectedSport;
  String? _selectedBranch;
  String? _selectedBatch;
  DateTime? _selectedDate;

  // Controller for the date input field
  final TextEditingController _dateController = TextEditingController();

  // NEW: Lists for dropdowns
  List<dynamic> _sports = [];
  List<dynamic> _branches = [];
  List<dynamic> _batches = [];

  @override
  void initState() {
    super.initState();
    _fetchSports();
    _fetchBranches();
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _fetchSports() async {
    final response = await apiClient.get('/organizations/sports/');
    if (response.statusCode == 200) {
      setState(() {
        _sports = jsonDecode(response.body);
      });
    }
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
    final response = await apiClient.get('/organizations/batches/?branch=$branchId');
    if (response.statusCode == 200) {
      setState(() {
        _batches = jsonDecode(response.body);
      });
    }
  }

  // A simulated method to fetch students from a database
  Future<void> _fetchStudents() async {
  if (_selectedBatch == null) return;

  setState(() {
    _isLoading = true;
    _students = [];
  });

  // Fetch enrollments for the selected batch
  final response = await apiClient.get(
      '/enrollments/by-batch/$_selectedBatch/');

  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);

    // Convert each enrollment into a Student object
    final fetchedStudents = data.map<Student>((item) {
      final fullName =
          '${item['student_name']} ${item['student_last_name']}';
      return Student(name: fullName);
    }).toList();

    setState(() {
      _students = fetchedStudents;
      _isLoading = false;
      _selectAll = false;
    });
  } else {
    setState(() {
      _isLoading = false;
    });
  }
}


  // Method to handle form submission
  void _handleFormSubmission() {
    if (_selectedSport != null && _selectedBranch != null && _selectedBatch != null && _selectedDate != null) {
      _fetchStudents();
    }
  }

  // Method to toggle a single student's attendance
  void _toggleAttendance(bool? value, int index) {
    if (value == null) return;
    setState(() {
      _students[index].isPresent = value;
      // Update selectAll status
      _selectAll = _students.every((student) => student.isPresent);
    });
  }

  // Method to toggle attendance for all students
  void _toggleSelectAll(bool? value) {
    if (value == null) return;
    setState(() {
      _selectAll = value;
      for (var student in _students) {
        student.isPresent = value;
      }
    });
  }

  // Method to save attendance (placeholder)
  void _saveAttendance() {
    final presentStudents = _students.where((s) => s.isPresent).toList();
    final absentStudents = _students.where((s) => !s.isPresent).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attendance Saved'),
        content: Text(
          'Total Students: ${_students.length}\n'
          'Present: ${presentStudents.length}\n'
          'Absent: ${absentStudents.length}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Method to show the date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
        _students = []; // Clear students when the date changes
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isFormComplete =
    _selectedSport != null && _selectedBranch != null && _selectedBatch != null && _selectedDate != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Take or Update Attendance',
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
                  // Header section

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF006C62),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12.0),
                        topRight: Radius.circular(12.0),
                      ),
                    ),
                    child: const Text(
                      'Take or Update Attendance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Form content section
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sports Dropdown
                        _DropdownInput(
                          label: 'Sport',
                          hint: 'Select Sport',
                          icon: Icons.sports,
                          items: (_sports).map<String>((s) => s['name'] as String).toList(), // <-- modified
                          onChanged: (value) {
                            setState(() {
                              _selectedSport = value;
                              _students = [];
                            });
                          },
                        ),

                        // Branch, Batch, and Attendance Dates
                        _DropdownInput(
                          label: 'Branch',
                          hint: 'Select Branch',
                          icon: Icons.school,
                          items: (_branches).map<String>((b) => b['id'].toString()).toList(), // <-- modified
                          onChanged: (value) async {
                            setState(() {
                              _selectedBranch = value;
                              _selectedBatch = null;
                              _batches = [];
                              _students = [];
                            });
                            if (value != null) {
                              await _fetchBatches(value);
                            }
                          },
                        ),
                        const SizedBox(height: 20),

                        // Batch Dropdown  (dynamic)
                        _DropdownInput(
                          label: 'Batch',
                          hint: 'Select Batch',
                          icon: Icons.group_work,
                          items: (_batches).map<String>((b) => b['id'].toString()).toList(), // <-- modified
                          onChanged: (value) {
                            setState(() {
                              _selectedBatch = value;
                              _students = [];
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        // Date Picker
                        _DateInput(
                          label: 'Attendance Date',
                          hint: 'Select Date',
                          icon: Icons.calendar_today,
                          controller: _dateController,
                          onTap: () => _selectDate(context),
                        ),

                        // Fetch Students Button
                        GestureDetector(
                          onTap: isFormComplete ? _handleFormSubmission : null,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: isFormComplete ? const Color(0xFF006C62) : Colors.grey,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Fetch Students',
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

                        const SizedBox(height: 20),

                        // Display table if data is loaded
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (_students.isNotEmpty)
                          SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: _buildAttendanceTable(),
                          ),

                        // Adding some space at the bottom to prevent overflow
                        const SizedBox(height: 20),
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

  // Widget to build the attendance table and buttons
  Widget _buildAttendanceTable() {
    return Column(
      children: [
        // Select All Checkbox
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              'Select All',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Checkbox(
              value: _selectAll,
              onChanged: _toggleSelectAll,
            ),
          ],
        ),

        // Attendance Data Table
        SizedBox(
          width: double.infinity,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Sr. No.')),
              DataColumn(label: Text('Present')),
              DataColumn(label: Text('Student Name')),
            ],
            rows: _students.asMap().entries.map((entry) {
              final index = entry.key;
              final student = entry.value;
              return DataRow(
                cells: [
                  DataCell(Text('${index + 1}')),
                  DataCell(
                    Checkbox(
                      value: student.isPresent,
                      onChanged: (value) => _toggleAttendance(value, index),
                    ),
                  ),
                  DataCell(Text(student.name)),
                ],
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 20),

        // Save Attendance Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveAttendance,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006C62),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text(
              'Save Attendance',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Reusable widget for dropdown inputs
class _DropdownInput extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final List<String> items;
  final void Function(String?) onChanged;

  const _DropdownInput({
    required this.label,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onChanged,
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// Reusable widget for date input
class _DateInput extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final void Function() onTap;

  const _DateInput({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.onTap,
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
        TextFormField(
          controller: controller,
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          readOnly: true,
          onTap: onTap,
        ),
      ],
    );
  }
}
