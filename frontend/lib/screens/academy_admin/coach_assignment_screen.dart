// sportsverse/frontend/sportsverse_app/lib/screens/academy_admin/coach_assignment_screen.dart

import 'package:flutter/material.dart';
import 'package:sportsverse_app/api/coach_api.dart';
import 'package:sportsverse_app/api/branch_api.dart';
import 'package:sportsverse_app/models/branch.dart';

class CoachAssignmentScreen extends StatefulWidget {
  const CoachAssignmentScreen({super.key});

  @override
  State<CoachAssignmentScreen> createState() => _CoachAssignmentScreenState();
}

class _CoachAssignmentScreenState extends State<CoachAssignmentScreen> {
  List<Coach> coaches = [];
  List<Branch> branches = [];
  bool isLoading = true;
  bool isSubmitting = false; // Prevents duplicate taps
  String? errorMessage;

  // Theme Colors
  static const Color sidebarDarkGreen = Color(0xFF1B3D2F);
  static const Color brandTeal = Color(0xFF00796B);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedCoaches = await coachApi.getCoaches();
      final loadedBranches = await branchApi.getBranches();

      setState(() {
        coaches = loadedCoaches;
        branches = loadedBranches;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _assignBranches(Coach coach) async {
    if (isSubmitting) return; // Guard clause

    final selectedBranches = List<int>.from(coach.assignedBranches);

    final result = await showDialog<List<int>>(
      context: context,
      builder: (context) => BranchAssignmentDialog(
        coachName: coach.coachName,
        branches: branches,
        selectedBranchIds: selectedBranches,
      ),
    );

    if (result != null) {
      try {
        setState(() {
          isSubmitting = true;
        });

        await coachApi.assignBranches(coachId: coach.id, branchIds: result);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Branches updated for ${coach.coachName}'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData(); // Refresh the list
        }
      } catch (e) {
        String errorMsg = e.toString();
        
        // Handle the Duplicate Entry error gracefully
        if (errorMsg.contains('1062') || errorMsg.contains('Duplicate')) {
          errorMsg = "This coach is already assigned to one of these branches.";
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach Branch Assignment'),
        backgroundColor: sidebarDarkGreen,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: brandTeal))
          : errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: $errorMessage', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    style: ElevatedButton.styleFrom(backgroundColor: brandTeal),
                    child: const Text('Retry', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            )
          : coaches.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No coaches found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: coaches.length,
                itemBuilder: (context, index) {
                  final coach = coaches[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: brandTeal,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(coach.coachName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: coach.assignedBranchNames.isEmpty
                            ? const Text('No branches assigned', style: TextStyle(fontStyle: FontStyle.italic))
                            : Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: coach.assignedBranchNames.map((name) {
                                  return Chip(
                                    label: Text(name, style: const TextStyle(fontSize: 11)),
                                    backgroundColor: Colors.teal.shade50,
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  );
                                }).toList(),
                              ),
                      ),
                      trailing: isSubmitting 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        : ElevatedButton(
                            onPressed: () => _assignBranches(coach),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brandTeal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text('Assign'),
                          ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class BranchAssignmentDialog extends StatefulWidget {
  final String coachName;
  final List<Branch> branches;
  final List<int> selectedBranchIds;

  const BranchAssignmentDialog({
    super.key,
    required this.coachName,
    required this.branches,
    required this.selectedBranchIds,
  });

  @override
  State<BranchAssignmentDialog> createState() => _BranchAssignmentDialogState();
}

class _BranchAssignmentDialogState extends State<BranchAssignmentDialog> {
  late Set<int> selectedBranches;

  @override
  void initState() {
    super.initState();
    selectedBranches = Set<int>.from(widget.selectedBranchIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Assign Branches to ${widget.coachName}'),
      content: SizedBox(
        width: double.maxFinite,
        child: widget.branches.isEmpty
            ? const Text('No branches available')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: widget.branches.length,
                itemBuilder: (context, index) {
                  final branch = widget.branches[index];
                  final isSelected = selectedBranches.contains(branch.id);

                  return CheckboxListTile(
                    activeColor: const Color(0xFF00796B),
                    title: Text(branch.name),
                    subtitle: Text(branch.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                    value: isSelected,
                    onChanged: branch.isActive
                        ? (value) {
                            setState(() {
                              if (value == true) {
                                selectedBranches.add(branch.id);
                              } else {
                                selectedBranches.remove(branch.id);
                              }
                            });
                          }
                        : null,
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, selectedBranches.toList()),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00796B)),
          child: const Text('Update Assignment', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}