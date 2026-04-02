import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportsverse_app/api/api_client.dart';
import 'package:sportsverse_app/providers/auth_provider.dart';
import 'package:sportsverse_app/providers/student_provider.dart';
import 'package:sportsverse_app/screens/coach/coach_dashboard_screen.dart';
import 'package:sportsverse_app/screens/student/student_dashboard_screen.dart';
import 'package:sportsverse_app/screens/auth/login_screen.dart';
import 'package:sportsverse_app/screens/auth/register_academy_screen.dart';
import 'package:sportsverse_app/screens/auth/forgot_password_screen.dart';
import 'package:sportsverse_app/screens/auth/password_reset_confirm_screen.dart';
import 'package:sportsverse_app/screens/auth/change_password_screen.dart';
import 'package:sportsverse_app/screens/academy_admin/admin_dashboard_screen.dart';
import 'package:sportsverse_app/screens/auth/register_user_screen.dart';
import 'package:sportsverse_app/screens/academy_admin/attendance_branch_select_screen.dart';
import 'package:sportsverse_app/screens/academy_admin/take_attendance_screen.dart';
import 'package:sportsverse_app/screens/academy_admin/view_attendance_screen.dart';
import 'package:sportsverse_app/screens/academy_admin/attendance_screen.dart';
import 'package:sportsverse_app/screens/student/student_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await apiClient.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
  create: (_) {
    final authProvider = AuthProvider();
    authProvider.initAuth(); // ✅ INIT HERE
    return authProvider;
  },
),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
      ],
      child: const SportsVerseApp(),
    ),
  );
}

class SportsVerseApp extends StatefulWidget {
  const SportsVerseApp({super.key});

  @override
  State<SportsVerseApp> createState() => _SportsVerseAppState();
}

class _SportsVerseAppState extends State<SportsVerseApp> {

  @override
  void initState() {
    super.initState();

    // ✅ SAFE AUTH INIT (AFTER BUILD)

  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SportsVerse',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter',
        useMaterial3: true,
      ),

      // ✅ NO FUTUREBUILDER — SIMPLIFIED FLOW
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          print('🏠 Main route builder called');
          print('🏠 Current user: ${authProvider.currentUser?.username}');
          print('🏠 User type: ${authProvider.currentUser?.userType}');
          print('🏠 Is loading: ${authProvider.isLoading}');

          // ⏳ LOADING STATE
// ⏳ WAIT UNTIL AUTH IS FULLY INITIALIZED
if (!authProvider.isInitialized) {
  return const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );
}

          // ❌ NOT LOGGED IN
         // ❌ NOT LOGGED IN
if (!authProvider.isAuthenticated) {
  return const LoginScreen();
}

          // ✅ ROUTING BASED ON ROLE
          switch (authProvider.currentUser!.userType) {
            case 'PLATFORM_ADMIN':
              return const Scaffold(
                body: Center(
                  child: Text('Platform Admin Dashboard - To be implemented'),
                ),
              );

            case 'ACADEMY_ADMIN':
              return const AdminDashboardScreen();

            case 'COACH':
              return const CoachDashboardScreen();

            case 'STUDENT':
              return const StudentDashboardScreen();

            case 'STAFF':
              return const Scaffold(
                body: Center(
                  child: Text('Staff Dashboard - To be implemented'),
                ),
              );

            default:
              return const LoginScreen();
          }
        },
      ),

      routes: {
        '/register-academy': (context) => const RegisterAcademyScreen(),
        '/register-user': (context) => const RegisterUserScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/attendance': (context) => const AttendanceScreen(),
        '/attendance/branches': (context) =>
            const AttendanceBranchSelectScreen(),
        '/attendance/take': (context) => const TakeAttendanceScreen(),
        '/attendance/view': (context) => const ViewAttendanceScreen(),
        '/profile': (context) => const StudentProfileScreen(),
        '/login': (context) => const LoginScreen(),
      },

      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            cardTheme: Theme.of(context).cardTheme.copyWith(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12.0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12.0)),
                borderSide: BorderSide(color: Colors.blueGrey, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12.0)),
                borderSide: BorderSide(color: Colors.blue, width: 2.0),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12.0)),
                borderSide: BorderSide(color: Colors.red, width: 2.0),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12.0)),
                borderSide: BorderSide(color: Colors.red, width: 2.0),
              ),
              contentPadding: EdgeInsets.symmetric(
                vertical: 16.0,
                horizontal: 16.0,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}