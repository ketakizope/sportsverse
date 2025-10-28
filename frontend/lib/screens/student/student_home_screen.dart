import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportsverse_app/providers/auth_provider.dart';
import 'student_dashboard_screen.dart';
import 'view_attendance_screen.dart';
import 'payment_screen.dart';
import 'student_profile_screen.dart';
import 'student_face_capture_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _selectedIndex = 0;
  bool _isDrawerOpen = false;

  final List<Widget> _screens = [
    const StudentDashboardScreen(),
    const ViewAttendanceScreen(),
    const PaymentScreen(),
  ];

  final List<Map<String, dynamic>> _menuItems = [
    {
      'title': 'Dashboard',
      'icon': Icons.dashboard,
      'description': 'Overview of your enrollments and progress',
    },
    {
      'title': 'View Attendance',
      'icon': Icons.calendar_today,
      'description': 'Track your attendance history',
    },
    {
      'title': 'Payment',
      'icon': Icons.payment,
      'description': 'Manage payments and billing',
    },
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _isDrawerOpen = false;
    });
    Navigator.of(context).pop(); // Close drawer
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _logout() {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.logout();
      
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_menuItems[_selectedIndex]['title']),
        backgroundColor: const Color(0xFF006C62),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              setState(() {
                _isDrawerOpen = !_isDrawerOpen;
              });
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implement notifications
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications feature coming soon!'),
                  backgroundColor: Color(0xFF006C62),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _screens[_selectedIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildDrawer() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        
        return Drawer(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF006C62), Color(0xFF004D47)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          backgroundImage: (user?.profilePhoto != null && user!.profilePhoto!.isNotEmpty)
                              ? NetworkImage(user.profilePhoto!)
                              : null,
                          child: user?.profilePhoto == null || (user?.profilePhoto != null && user!.profilePhoto!.isEmpty)
                              ? const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Color(0xFF006C62),
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${user?.firstName ?? 'Student'} ${user?.lastName ?? ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'student@example.com',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Menu Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    // Main navigation items
                    ...List.generate(_menuItems.length, (index) {
                      final item = _menuItems[index];
                      final isSelected = _selectedIndex == index;
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF006C62).withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: Icon(
                            item['icon'],
                            color: isSelected ? const Color(0xFF006C62) : const Color(0xFF7F8C8D),
                          ),
                          title: Text(
                            item['title'],
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF006C62) : const Color(0xFF2C3E50),
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            item['description'],
                            style: const TextStyle(
                              color: Color(0xFF7F8C8D),
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          onTap: () => _onItemTapped(index),
                        ),
                      );
                    }),
                    
                    // Divider
                    const Divider(height: 20),
                    
                    // Profile option
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: ListTile(
                        leading: const Icon(
                          Icons.person_outline,
                          color: Color(0xFF7F8C8D),
                        ),
                        title: const Text(
                          'Profile',
                          style: TextStyle(
                            color: Color(0xFF2C3E50),
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        subtitle: const Text(
                          'Manage your profile and settings',
                          style: TextStyle(
                            color: Color(0xFF7F8C8D),
                            fontSize: 12,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context); // Close drawer
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StudentProfileScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Face Attendance option
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: ListTile(
                        leading: const Icon(
                          Icons.face_retouching_natural,
                          color: Color(0xFF7F8C8D),
                        ),
                        title: const Text(
                          'Face Attendance',
                          style: TextStyle(
                            color: Color(0xFF2C3E50),
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        subtitle: const Text(
                          'Register your face for automated attendance',
                          style: TextStyle(
                            color: Color(0xFF7F8C8D),
                            fontSize: 12,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context); // Close drawer
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StudentFaceCaptureScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Logout option
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: ListTile(
                        leading: const Icon(
                          Icons.logout,
                          color: Colors.red,
                        ),
                        title: const Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        subtitle: const Text(
                          'Sign out of your account',
                          style: TextStyle(
                            color: Color(0xFF7F8C8D),
                            fontSize: 12,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context); // Close drawer
                          _showLogoutConfirmation();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.help_outline, color: Color(0xFF7F8C8D)),
                      title: const Text(
                        'Help & Support',
                        style: TextStyle(color: Color(0xFF2C3E50)),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Help & Support feature coming soon!'),
                            backgroundColor: Color(0xFF006C62),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF006C62),
        unselectedItemColor: const Color(0xFF7F8C8D),
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 12,
        ),
        items: _menuItems.map((item) {
          return BottomNavigationBarItem(
            icon: Icon(item['icon']),
            label: item['title'],
          );
        }).toList(),
      ),
    );
  }
}