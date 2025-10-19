// sportsverse/frontend/sportsverse_app/lib/screens/academy_admin/student_management_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sportsverse_app/api/auth_api.dart';
import 'package:sportsverse_app/api/api_client.dart';
import 'package:sportsverse_app/models/student.dart';
import 'package:sportsverse_app/models/financials.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  String? _selectedBranch;
  String? _selectedSport;
  String? _selectedBatch;

  List<dynamic> _branches = [];
  List<dynamic> _sports = [];
  List<dynamic> _batches = [];

  // Controller to manage fee input for selected batch and keep it in sync after save
  final TextEditingController _batchFeeController = TextEditingController();
  String? _feeControllerBatchId; // track which batch id the controller reflects

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // branches and sports
      final sports = await authApi.getSports();
      // For branches, reuse organizations endpoint
      final branchesResp = await apiClient.get('/api/organizations/branches/', includeAuth: true);
      if (branchesResp.statusCode == 200) {
        final List<dynamic> branchesJson = json.decode(branchesResp.body);
        _branches = branchesJson;
      }
      _sports = sports;
        _isLoading = false;
      setState(() {});
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchBatches() async {
    if (_selectedBranch == null || _selectedSport == null) return;
    final resp = await apiClient.get('/api/organizations/batches/?branch=$_selectedBranch&sport=$_selectedSport', includeAuth: true);
    if (resp.statusCode == 200) {
      _batches = (json.decode(resp.body) as List<dynamic>).map((e) => {
        'id': e['id'],
        'name': e['name'],
      }).toList();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _batchFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Financials'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Filters similar to attendance
                    if (!_isLoading) ...[
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Branch'),
                        value: _selectedBranch,
                        items: _branches.map<DropdownMenuItem<String>>((branch) {
                          return DropdownMenuItem<String>(
                            value: branch['id'].toString(),
                            child: Text(branch['name']),
                          );
                        }).toList(),
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
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Sport'),
                        value: _selectedSport,
                        items: _sports.map<DropdownMenuItem<String>>((sport) {
                          return DropdownMenuItem<String>(
                            value: sport.id.toString(),
                            child: Text(sport.name),
                          );
                        }).toList(),
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
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Batch'),
                        value: _selectedBatch,
                        items: _batches.map<DropdownMenuItem<String>>((batch) {
                          return DropdownMenuItem<String>(
                            value: batch['id'].toString(),
                            child: Text(batch['name']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedBatch = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    if (_selectedBatch != null) _buildBatchFinancialsCard(),
                  ],
                ),
    );
  }

  Widget _buildBatchFinancialsCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: authApi.getBatchFinancials(
        branchId: int.parse(_selectedBranch!),
        sportId: int.parse(_selectedSport!),
        batchId: int.parse(_selectedBatch!),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text(snapshot.error.toString());
        }
        final data = snapshot.data!;
        final batch = data['batch'];
        final students = data['students'] as List<dynamic>;

        // Initialize or update fee controller when batch changes or when backend value updates
        final String batchIdStr = batch['id'].toString();
        final String backendFeeStr = (batch['fee_per_session']?.toString() ?? '').trim();
        if (_feeControllerBatchId != batchIdStr) {
          _feeControllerBatchId = batchIdStr;
          _batchFeeController.text = backendFeeStr;
        } else if (_batchFeeController.text.trim().isEmpty && backendFeeStr.isNotEmpty) {
          // Ensure controller is not empty if backend has a value
          _batchFeeController.text = backendFeeStr;
        }

        Future<void> saveFee() async {
          final String raw = _batchFeeController.text.trim();
          final double? fee = double.tryParse(raw);
          if (fee == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Enter a valid fee amount'), backgroundColor: Colors.red),
            );
            return;
          }
          final resp = await apiClient.patch(
            '/api/organizations/batches/${batch['id']}/',
            {
              'fee_per_session': fee,
            },
            includeAuth: true,
          );
          if (resp.statusCode >= 200 && resp.statusCode < 300) {
            // Keep controller value as the new default and refresh card
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fee updated')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to update fee'), backgroundColor: Colors.red),
            );
          }
        }
                    return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _batchFeeController,
                        decoration: const InputDecoration(
                          labelText: 'Standard Fee per Session',
                          prefixText: '₹ ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onFieldSubmitted: (_) async { await saveFee(); },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async { await saveFee(); },
                      child: const Text('Save'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ToggleButtons(
                  isSelected: const [true, false],
                  onPressed: (index) {
                    // Placeholder toggle behavior; can wire to filter later
                    setState(() {});
                  },
                  children: const [
                    Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Weekly')),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Monthly')),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Students', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...students.map((s) {
                  final double fee = double.tryParse(_batchFeeController.text.trim()) ??
                      (double.tryParse(batch['fee_per_session']?.toString() ?? '') ?? 0.0);
                  final int unpaidSessions = int.tryParse((s['unpaid_sessions'] ?? 0).toString()) ?? 0;
                  final double totalUnpaidAmount = unpaidSessions * fee;
                  final history = (s['payment_history'] as List<dynamic>);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text('${s['first_name']} ${s['last_name']}'),
                        subtitle: Text(
                            'Sessions left: ${s['sessions_left_display'] ?? (s['sessions_left'] ?? '-')}'
                            '  •  Unpaid sessions: $unpaidSessions'
                            '  •  Total unpaid: ₹ ${totalUnpaidAmount.toStringAsFixed(2)}'),
                      ),
                      if (history.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, bottom: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: history
                                .map<Widget>((h) => Text('${h['transaction_date']}: ${h['amount']} ${h['is_paid'] ? '(Paid)' : '(Due)'}'))
                                .toList(),
                          ),
                        ),
                      const Divider(height: 1),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}
