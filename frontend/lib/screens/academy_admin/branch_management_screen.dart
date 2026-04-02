// sportsverse/frontend/sportsverse_app/lib/screens/academy_admin/branch_management_screen.dart

import 'package:flutter/material.dart';
import 'package:sportsverse_app/api/branch_api.dart';
import 'package:sportsverse_app/models/branch.dart';

class BranchManagementScreen extends StatefulWidget {
  const BranchManagementScreen({super.key});

  @override
  State<BranchManagementScreen> createState() => _BranchManagementScreenState();
}

class _BranchManagementScreenState extends State<BranchManagementScreen> {
  List<Branch> branches = [];
  bool isLoading = true;
  String? errorMessage;

  // Theme Colors to match Dashboard
  static const Color sidebarDarkGreen = Color(0xFF1B3D2F);
  static const Color brandTeal = Color(0xFF00796B);

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      debugPrint("📡 Fetching branches...");
      final loadedBranches = await branchApi.getBranches();
      
      debugPrint("✅ Branches loaded: ${loadedBranches.length}");
      
      setState(() {
        branches = loadedBranches;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Branch Load Error: $e");
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _deleteBranch(Branch branch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Branch'),
        content: Text('Are you sure you want to delete "${branch.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await branchApi.deleteBranch(branch.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Branch deleted successfully')),
          );
          _loadBranches();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete branch: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateToAddEditBranch([Branch? branch]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditBranchScreen(branch: branch),
      ),
    );

    if (result == true) {
      _loadBranches();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Branches'),
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
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $errorMessage',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadBranches,
                    style: ElevatedButton.styleFrom(backgroundColor: brandTeal),
                    child: const Text('Retry', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            )
          : branches.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No branches found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add your first branch to get started',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadBranches,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: branches.length,
                itemBuilder: (context, index) {
                  final branch = branches[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: brandTeal,
                        child: Icon(Icons.business, color: Colors.white),
                      ),
                      title: Text(
                        branch.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Address: ${branch.address}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _navigateToAddEditBranch(branch);
                              break;
                            case 'delete':
                              _deleteBranch(branch);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _navigateToAddEditBranch(branch),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditBranch(),
        backgroundColor: brandTeal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class AddEditBranchScreen extends StatefulWidget {
  final Branch? branch;

  const AddEditBranchScreen({super.key, this.branch});

  @override
  State<AddEditBranchScreen> createState() => _AddEditBranchScreenState();
}

class _AddEditBranchScreenState extends State<AddEditBranchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = false;
  bool get isEditing => widget.branch != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.branch!.name;
      _addressController.text = widget.branch!.address;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveBranch() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (isEditing) {
        await branchApi.updateBranch(
          branchId: widget.branch!.id,
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          isActive: widget.branch!.isActive,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Branch updated successfully')),
          );
        }
      } else {
        await branchApi.createBranch(
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          isActive: true,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Branch created successfully')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Branch' : 'Add Branch'),
        backgroundColor: const Color(0xFF1B3D2F),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Branch Name *',
                  hintText: 'Enter branch/center name',
                  prefixIcon: Icon(Icons.store, color: Color(0xFF00796B)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00796B))),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Branch name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address *',
                  hintText: 'Enter full address',
                  prefixIcon: Icon(Icons.location_on, color: Color(0xFF00796B)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00796B))),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Address is required';
                  }
                  return null;
                },
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveBranch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00796B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isEditing ? 'Update Branch' : 'Create Branch'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}