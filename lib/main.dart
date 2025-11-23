// main.dart
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_redirect.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/student/student_home_screen.dart';
import 'screens/teacher/teacher_home_screen.dart';
import 'screens/student/group_screen.dart';

// THÊM DÒNG NÀY
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // QUAN TRỌNG NHẤT: GỌI INIT ĐỂ GÁN TOKEN VÀO DIO NGAY TỪ ĐẦU
  await ApiService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QUẢN LÍ ĐỒ ÁN - KHÓA LUẬN FIT.HUIT',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'Roboto', // Nếu bạn muốn font đẹp hơn
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/login': (context) => const LoginScreen(),
        '/home-redirect': (context) => const HomeRedirectScreen(),
        '/admin-home': (context) => const AdminHomeScreen(),
        '/student-home': (context) => const StudentHomeScreen(),
        '/teacher-home': (context) => const TeacherHomeScreen(),
        '/group': (context) => const GroupScreen(),
      },
    );
  }
}