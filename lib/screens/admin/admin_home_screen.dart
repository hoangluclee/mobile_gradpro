import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:doancunhan/screens/notifications_page.dart';
import 'package:doancunhan/services/api_service.dart';
import 'package:doancunhan/screens/admin/group_screen.dart';
import 'package:doancunhan/screens/news_screen.dart';
import 'package:doancunhan/screens/admin/hoidong_screen.dart';
import 'package:intl/intl.dart';
import 'package:doancunhan/screens/change_password_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  String? userName;
  String? userEmail;
  String? userId;
  String? userPhone;
  String? userRole;
  String? userMajor;
  String? userBirthday;

  int _unreadCount = 0;
  bool _animateDot = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initFCM();
    _loadUnreadNotifications();
  }

  Future<void> _loadUserData() async {
  final prefs = await SharedPreferences.getInstance();
  final rawBirth = prefs.getString('user_birthday');

  String formattedBirth = "Chưa cập nhật";

  if (rawBirth != null && rawBirth.trim().isNotEmpty) {
    try {
      DateTime parsed;

      // ✔ ISO 8601 (1990-01-01T00:00:00.000000Z)
      if (RegExp(r'^\d{4}-\d{2}-\d{2}T').hasMatch(rawBirth)) {
        parsed = DateTime.parse(rawBirth);
      }
      // ✔ yyyy-MM-dd
      else if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(rawBirth)) {
        parsed = DateTime.parse(rawBirth);
      }
      // ✔ dd/MM/yyyy hoặc dd-MM-yyyy
      else if (RegExp(r'^\d{2}[\/\-]\d{2}[\/\-]\d{4}$').hasMatch(rawBirth)) {
        final parts = rawBirth.contains("/")
            ? rawBirth.split("/")
            : rawBirth.split("-");
        parsed = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
      // ✔ fallback general parser
      else {
        parsed = DateTime.parse(rawBirth);
      }

      formattedBirth = DateFormat("dd/MM/yyyy").format(parsed);
    } catch (e) {
      formattedBirth = "Chưa cập nhật";
    }
  }

  setState(() {
    userName = prefs.getString('user_name') ?? 'Quản trị viên';
    userEmail = prefs.getString('user_email') ?? 'admin@gradpro.test';
    userId = prefs.getString('user_id') ?? 'ADMIN001';
    userPhone = prefs.getString('user_phone') ?? 'Chưa cập nhật';
    userRole = prefs.getString('user_role') ?? 'Quản trị viên';
    userBirthday = formattedBirth; 
  });


  setState(() {
    userName = prefs.getString('user_name') ?? 'Quản trị viên';
    userEmail = prefs.getString('user_email') ?? 'admin@gradpro.test';
    userId = prefs.getString('user_id') ?? 'ADMIN001';
    userPhone = prefs.getString('user_phone') ?? 'Chưa cập nhật';
    userRole = prefs.getString('user_role') ?? 'Quản trị viên';
    userBirthday = formattedBirth; 
  });
}


  Future<void> _initFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    debugPrint("Admin FCM Token: $token");

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showSimpleNotification(
          Text(message.notification!.title ?? "Thông báo mới"),
          subtitle: Text(message.notification!.body ?? ""),
          background: Colors.deepPurple,
          duration: const Duration(seconds: 4),
          leading: const Icon(Icons.notifications_active, color: Colors.white),
        );

        setState(() {
          _unreadCount++;
          _animateDot = true;
        });

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _animateDot = false);
        });
      }
    });
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final response = await ApiService.dio.get('/notifications/unread-count');
      if (response.statusCode == 200 && response.data != null) {
        setState(() => _unreadCount = response.data['count'] ?? 0);
      }
    } catch (e) {
      debugPrint("Lỗi load unread admin: $e");
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(String title, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black12.withOpacity(0.07),
                blurRadius: 6,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 38),
            const SizedBox(height: 10),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F3F8),

        endDrawer: Drawer(
  child: SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Text("Thông tin tài khoản",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Divider(),

            _buildInfoRow(Icons.person, "Họ và tên", userName ?? 'Quản trị viên'),
            _buildInfoRow(Icons.email_rounded, "Email", userEmail ?? 'Chưa có'),
            _buildInfoRow(Icons.badge_rounded, "Mã định danh", userId ?? 'ADMIN001'),
            _buildInfoRow(Icons.cake_rounded, "Ngày sinh", userBirthday ?? 'Chưa cập nhật'),
            _buildInfoRow(Icons.work_outline_rounded, "Vai trò", userRole ?? 'Quản trị viên'),

            const SizedBox(height: 30),

            // NÚT ĐỔI MẬT KHẨU – NHỎ GỌN, ĐẸP, ĐẶT TRƯỚC ĐĂNG XUẤT
            SizedBox(
              child: OutlinedButton.icon(
              icon: const Icon(Icons.key_rounded, size: 20),
              label: const Text(
                "Đổi mật khẩu",
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.deepPurple,
                side: const BorderSide(color: Colors.deepPurple, width: 1.8),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.deepPurple.withOpacity(0.06),
              ),
              onPressed: () {
                Navigator.pop(context); // Đóng drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                );
              },
            ),

            ),

            const SizedBox(height: 12),

            // NÚT ĐĂNG XUẤT – GIỮ NGUYÊN ĐỎ NỔI BẬT
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                onPressed: _logout,
                label: const Text(
                  "Đăng xuất",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  ),
),

        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 236, 232, 243),
          elevation: 0,
          centerTitle: false,
          automaticallyImplyLeading: false, // ⚡ KHÔNG HIỆN MŨI TÊN BACK
          title: Row(
            children: [
              Image.asset('assets/images/huit_logo.png',
                  height: 40, fit: BoxFit.contain),
              const SizedBox(width: 12),
              const Text("FIT.HUIT",
                  style: TextStyle(
                      color: Color.fromARGB(255, 245, 4, 4),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5)),
            ],
          ),
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_outlined,
                      color: Colors.black, size: 28),
                  onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationsPage()))
                      .then((_) => _loadUnreadNotifications()),
                ),
                if (_unreadCount > 0)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: AnimatedScale(
                      scale: _animateDot ? 1.6 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.elasticOut,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.red,
                                blurRadius: 8,
                                spreadRadius: 2)
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.black),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),

        body: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [
                        Color.fromARGB(255, 49, 58, 226),
                        Colors.purpleAccent
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName ?? 'Quản trị viên',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text("Chào mừng quay lại! 🌟",
                        style: TextStyle(color: Colors.white, fontSize: 15)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 1.05,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildFeature("Tin tức", Icons.article_rounded,
                          Colors.deepPurple,
                          onTap: () => Navigator.push(
                              context,
                              PageRouteBuilder(
                                  pageBuilder: (_, __, ___) =>
                                      const NewsScreen(),
                                  transitionsBuilder: (_, anim, __, child) =>
                                      FadeTransition(
                                          opacity: anim, child: child)))),
                      _buildFeature("Hội đồng", Icons.groups_rounded,
                          Colors.pinkAccent,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const HoiDongScreen()))),
                      _buildFeature("Đề tài", Icons.book_rounded,
                          Colors.blueAccent),
                      _buildFeature(
                          "Kết quả", Icons.assessment_rounded, Colors.orangeAccent),
                      _buildFeature(
                          "Kế hoạch", Icons.calendar_month_rounded, Colors.teal),
                      _buildFeature("Nhóm", Icons.people_alt_rounded,
                          Colors.green,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const GroupScreen()))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
