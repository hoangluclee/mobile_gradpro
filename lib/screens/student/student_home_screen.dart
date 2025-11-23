// lib/screens/student/student_home_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

import '../news_screen.dart';
import 'group_screen.dart';
import 'topics_combined_page.dart';
import 'student_plan_screen.dart';
import '../../services/api_service.dart';
import 'meetings_screen.dart';
import 'group_tasks_screen.dart';
import '../notifications_page.dart';
import '../change_password_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  // ======================= THÔNG TIN SINH VIÊN =======================
  String userName = 'Sinh viên';
  String userEmail = 'Chưa có email';
  String userId = 'Không rõ';
  String userClass = 'Chưa cập nhật';
  String userMajor = 'Chưa cập nhật';
  String userBirthday = 'Chưa cập nhật';
  String userRole = 'Sinh viên';
  Map<String, dynamic>? currentPlan;

  bool _isLoading = true;
  int _unreadCount = 0;
  bool _animateDot = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initFCM();
    _loadUnreadNotifications();
  }

  // ======================= LOAD USER INFO TỪ user_info (CHUẨN NHƯ GIẢNG VIÊN) =======================
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJsonString = prefs.getString('user_info');

    if (userJsonString == null || userJsonString.isEmpty) {
      debugPrint("Không tìm thấy user_info trong SharedPreferences");
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final Map<String, dynamic> user = jsonDecode(userJsonString);
      final sinhvien = user['sinhvien'] as Map<String, dynamic>? ?? {};
      final chuyennganh = sinhvien['chuyennganh'] as Map<String, dynamic>? ?? {};

      setState(() {
        userName = user['HODEM_VA_TEN']?.toString() ?? 'Sinh viên';
        userEmail = user['EMAIL']?.toString() ?? 'Chưa có email';
        userId = user['MA_DINHDANH']?.toString() ?? 'Không rõ';
        userClass = sinhvien['TEN_LOP']?.toString() ?? 'Chưa cập nhật';
        userMajor = chuyennganh['TEN_CHUYENNGANH']?.toString() ?? 'Chưa cập nhật';
        userRole = user['vaitro']?['TEN_VAITRO']?.toString() ?? 'Sinh viên';

        final rawBirthday = user['NGAYSINH'];
        if (rawBirthday != null && rawBirthday.toString().isNotEmpty) {
          try {
            final dt = DateTime.parse(rawBirthday.toString());
            userBirthday = DateFormat('dd/MM/yyyy').format(dt);
          } catch (e) {
            userBirthday = 'Chưa cập nhật';
          }
        }
      });
    } catch (e) {
      debugPrint("Lỗi parse user_info: $e");
    }

    // Lấy kế hoạch hiện tại (sau khi có user)
    try {
      await ApiService.setAuthHeader();
      final plan = await ApiService.getMyPlan();
      if (plan.isNotEmpty) {
        currentPlan = plan;
      }
    } catch (e) {
      debugPrint("Lỗi load kế hoạch: $e");
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // ======================= FCM + THÔNG BÁO =======================
  Future<void> _initFCM() async {
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint("FCM Token: $token");

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
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) setState(() => _animateDot = false);
        });
      }
    });
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      await ApiService.setAuthHeader();
      final res = await ApiService.dio.get('/notifications/unread-count');
      if (res.statusCode == 200) {
        setState(() => _unreadCount = res.data['count'] ?? 0);
      }
    } catch (e) {
      debugPrint("Lỗi load thông báo: $e");
    }
  }

  // ======================= ĐĂNG XUẤT =======================
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  // ======================= LỜI CHÀO =======================
  String getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Chúc bạn buổi sáng vui vẻ";
    if (hour < 18) return "Chúc bạn buổi chiều năng động";
    return "Chúc bạn buổi tối học tập hiệu quả";
  }

  // ======================= COMPONENT INFO =======================
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
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ======================= MENU GRID =======================
  Widget _buildFeature(String title, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black12.withOpacity(0.07), blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 38),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ======================= UI =======================
  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F3F8),

        // ======================= END DRAWER (HỒ SƠ) =======================
        endDrawer: Drawer(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Text("Thông tin tài khoản", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const Divider(height: 32, thickness: 1),

                    _buildInfoRow(Icons.person, "Họ và tên", userName),
                    _buildInfoRow(Icons.email_rounded, "Email", userEmail),
                    _buildInfoRow(Icons.badge_rounded, "MSSV", userId),
                    _buildInfoRow(Icons.class_rounded, "Lớp", userClass),
                    _buildInfoRow(Icons.school_rounded, "Chuyên ngành", userMajor),
                    _buildInfoRow(Icons.cake_rounded, "Ngày sinh", userBirthday),
                    _buildInfoRow(Icons.work_outline_rounded, "Vai trò", userRole),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.key, size: 20, color: Colors.deepPurple),
                        label: const Text("Đổi mật khẩu", style: TextStyle(fontSize: 15, color: Colors.deepPurple, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.deepPurple, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: Colors.deepPurple.withOpacity(0.05),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text("Đăng xuất", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        onPressed: _logout,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ======================= APPBAR =======================
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 236, 232, 243),
          elevation: 0,
          centerTitle: false,
          title: Row(
            children: [
              Image.asset('assets/images/huit_logo.png', height: 40),
              const SizedBox(width: 12),
              const Text("FIT.HUIT", style: TextStyle(color: Color.fromARGB(255, 245, 4, 4), fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ],
          ),
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_outlined, size: 28, color: Colors.black87),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()))
                        .then((_) => _loadUnreadNotifications());
                  },
                ),
                if (_unreadCount > 0)
                  Positioned(
                    right: 10, top: 10,
                    child: AnimatedScale(
                      scale: _animateDot ? 1.6 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                    ),
                  ),
              ],
            ),
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.black87),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),

        // ======================= BODY =======================
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color.fromARGB(255, 49, 58, 226), Colors.purpleAccent], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(25), bottomRight: Radius.circular(25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Xin chào,", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w400)),
                        const SizedBox(height: 6),
                        Text(userName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text(getGreetingMessage(), style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            currentPlan != null
                                ? "Kế hoạch hiện tại: ${currentPlan!['TEN_KEHOACH'] ?? currentPlan!['TEN_DOT'] ?? 'Đang tải...'}"
                                : "Chưa có kế hoạch",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Menu Grid
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 1.05,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        children: [
                          _buildFeature("Đề Tài", Icons.dashboard_rounded, Colors.deepPurple, onTap: () {
                            if (currentPlan == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bạn chưa có kế hoạch!")));
                              return;
                            }
                            Navigator.push(context, MaterialPageRoute(builder: (_) => TopicRegisterScreen(planId: currentPlan!['ID_KEHOACH'])));
                          }),
                          _buildFeature("Kế hoạch", Icons.calendar_today, Colors.indigo, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentPlanScreen()))),
                          _buildFeature("Nhóm", Icons.group, Colors.teal, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupScreen()))),
                          _buildFeature("Lịch họp", Icons.schedule, Colors.redAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MeetingsScreen()))),
                          _buildFeature("Tin tức", Icons.article, Colors.orange, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsScreen()))),
                          _buildFeature("Công việc", FluentIcons.task_list_ltr_24_filled, Colors.purple, onTap: () async {
                            final group = await ApiService.getMyGroup();
                            if (group['has_group'] == true && group['group_data']?['ID_NHOM'] != null) {
                              if (context.mounted) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => GroupKanbanScreen(groupId: group['group_data']['ID_NHOM'])));
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bạn chưa có nhóm để xem công việc!")));
                              }
                            }
                          }),
                          _buildFeature("Hồ sơ", Icons.person_outline_rounded, Colors.green, onTap: () => Scaffold.of(context).openEndDrawer()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}