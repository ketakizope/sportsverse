import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:sportsverse_app/api/api_client.dart';
import 'package:sportsverse_app/api/branch_api.dart';
import 'package:sportsverse_app/api/auth_api.dart';
import 'package:sportsverse_app/api/batch_api.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // State variables for dropdowns
  String? _selectedBranch;
  String? _selectedSport;
  String? _selectedBatch;
  String? _selectedBranchName;
  String? _selectedSportName;
  String? _selectedBatchName;
  
  // Lists for dropdown options
  List<dynamic> _branches = [];
  List<dynamic> _sports = [];
  List<dynamic> _batches = [];
  
  // Loading states
  bool _loadingBranches = true;
  bool _loadingSports = true;
  bool _loadingBatches = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _fetchBranches();
    _fetchSports();
  }
  
  // Fetch branches from API
  Future<void> _fetchBranches() async {
    setState(() {
      _loadingBranches = true;
      _error = null;
    });
    
    try {
      final response = await apiClient.get('/api/organizations/branches/');
      if (response.statusCode == 200) {
        setState(() {
          _branches = jsonDecode(response.body);
          _loadingBranches = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load branches';
          _loadingBranches = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingBranches = false;
      });
    }
  }
  
  // Fetch sports from API
  Future<void> _fetchSports() async {
    setState(() {
      _loadingSports = true;
      _error = null;
    });
    
    try {
      final sports = await authApi.getSports();
      setState(() {
        _sports = sports;
        _loadingSports = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingSports = false;
      });
    }
  }
  
  // Fetch batches based on selected branch and sport
  Future<void> _fetchBatches() async {
    if (_selectedBranch == null || _selectedSport == null) return;
    
    setState(() {
      _loadingBatches = true;
      _error = null;
    });
    
    try {
      final batches = await batchApi.getBatches();
      setState(() {
        _batches = batches
            .where((b) => 
                b.branchId.toString() == _selectedBranch && 
                b.sportId.toString() == _selectedSport)
            .toList();
        _loadingBatches = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingBatches = false;
      });
    }
  }
  
  // Navigate to Take Attendance screen
  void _navigateToTakeAttendance() {
    if (_validateSelections()) {
      Navigator.pushNamed(
        context, 
        '/attendance/take',
        arguments: {
          'branchId': _selectedBranch,
          'branchName': _selectedBranchName,
          'sportId': _selectedSport,
          'sportName': _selectedSportName,
          'batchId': _selectedBatch,
          'batchName': _selectedBatchName,
        },
      );
    }
  }
  
  // Navigate to View Attendance screen
  void _navigateToViewAttendance() {
    if (_validateSelections()) {
      Navigator.pushNamed(
        context, 
        '/attendance/view',
        arguments: {
          'branchId': _selectedBranch,
          'branchName': _selectedBranchName,
          'sportId': _selectedSport,
          'sportName': _selectedSportName,
          'batchId': _selectedBatch,
          'batchName': _selectedBatchName,
        },
      );
    }
  }
  
  // Validate selections before navigation
  bool _validateSelections() {
    if (_selectedBranch == null) {
      _showErrorSnackBar('Please select a branch');
      return false;
    }
    if (_selectedSport == null) {
      _showErrorSnackBar('Please select a sport');
      return false;
    }
    if (_selectedBatch == null) {
      _showErrorSnackBar('Please select a batch');
      return false;
    }
    return true;
  }
  
  // Show error message
  void _showErrorSnackBar(String message) {
    // Use Future.microtask to avoid showing SnackBar during build
    Future.microtask(() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoading = _loadingBranches || _loadingSports || _loadingBatches;
    final bool hasError = _error != null;
    final bool hasSelections = _selectedBranch != null && 
                              _selectedSport != null && 
                              _selectedBatch != null;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Management')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Error message
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            
            // Loading indicator
            if (isLoading)
              const Center(child: CircularProgressIndicator()),
            
            // Selection dropdowns
            if (!isLoading) ...[              
              // Branch dropdown
              _DropdownInput(
                label: 'Branch',
                hint: 'Select Branch',
                icon: Icons.apartment,
                items: _branches.map<DropdownMenuItem<String>>((branch) {
                  return DropdownMenuItem<String>(
                    value: branch['id'].toString(),
                    child: Text(branch['name']),
                    onTap: () {
                      setState(() {
                        _selectedBranchName = branch['name'];
                      });
                    },
                  );
                }).toList(),
                value: _selectedBranch,
                onChanged: (value) {
                  setState(() {
                    _selectedBranch = value;
                    _selectedBatch = null;
                    _batches = [];
                  });
                  if (_selectedSport != null) {
                    _fetchBatches();
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Sport dropdown
              _DropdownInput(
                label: 'Sport',
                hint: 'Select Sport',
                icon: Icons.sports,
                items: _sports.map<DropdownMenuItem<String>>((sport) {
                  return DropdownMenuItem<String>(
                    value: sport.id.toString(),
                    child: Text(sport.name),
                    onTap: () {
                      setState(() {
                        _selectedSportName = sport.name;
                      });
                    },
                  );
                }).toList(),
                value: _selectedSport,
                onChanged: (value) {
                  setState(() {
                    _selectedSport = value;
                    _selectedBatch = null;
                    _batches = [];
                  });
                  if (_selectedBranch != null) {
                    _fetchBatches();
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Batch dropdown
              _DropdownInput(
                label: 'Batch',
                hint: 'Select Batch',
                icon: Icons.group,
                items: _batches.map<DropdownMenuItem<String>>((batch) {
                  return DropdownMenuItem<String>(
                    value: batch.id.toString(),
                    child: Text(batch.name),
                    onTap: () {
                      setState(() {
                        _selectedBatchName = batch.name;
                      });
                    },
                  );
                }).toList(),
                value: _selectedBatch,
                onChanged: (value) {
                  setState(() {
                    _selectedBatch = value;
                  });
                },
              ),
              const SizedBox(height: 32),
              
              // Action cards
              if (hasSelections) ...[                
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0,
                    children: [
                      // Take Attendance Card
                      _ActionCard(
                        title: 'Take Attendance',
                        subtitle: 'Mark student attendance',
                        icon: Icons.fact_check,
                        color: const Color(0xFF06beb6),
                        onTap: _navigateToTakeAttendance,
                      ),
                      
                      // View Attendance Card
                      _ActionCard(
                        title: 'View Attendance',
                        subtitle: 'Check attendance records',
                        icon: Icons.insights,
                        color: const Color(0xFF43e97b),
                        onTap: _navigateToViewAttendance,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// Dropdown input widget
class _DropdownInput extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final List<DropdownMenuItem<String>> items;
  final String? value;
  final Function(String?) onChanged;

  const _DropdownInput({
    required this.label,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onChanged,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
        ),
      ],
    );
  }
}

// Action card widget
class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Set to min to prevent overflow
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color), // Reduced icon size
              const SizedBox(height: 12), // Reduced spacing
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // Reduced font size
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4), // Reduced spacing
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]), // Reduced font size
                textAlign: TextAlign.center,
                maxLines: 2, // Limit to 2 lines
                overflow: TextOverflow.ellipsis, // Handle overflow with ellipsis
              ),
            ],
          ),
        ),
      ),
    );
  }
}