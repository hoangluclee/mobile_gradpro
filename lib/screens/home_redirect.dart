import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'student/student_home_screen.dart';
import 'teacher/teacher_home_screen.dart';
import 'admin/admin_home_screen.dart';
import 'login_screen.dart';

class HomeRedirectScreen extends StatefulWidget {
  const HomeRedirectScreen({super.key});

  @override
  State<HomeRedirectScreen> createState() => _HomeRedirectScreenState();
}

class _HomeRedirectScreenState extends State<HomeRedirectScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role');

    Widget page;
    switch (role?.toLowerCase()) {
      case 'sinh viên':
        page = const StudentHomeScreen();
        break;
      case 'giảng viên':
        page = const TeacherHomeScreen();
        break;
      // Giáo vụ và Trưởng khoa vào chung trang Admin
      case 'admin':
      case 'giáo vụ':
      case 'trưởng khoa':
        page = const AdminHomeScreen();
        break;
      default:
        page = const LoginScreen();
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
