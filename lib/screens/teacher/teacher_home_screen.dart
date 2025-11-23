// lib/screens/teacher/teacher_home_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../news_screen.dart';
import 'hoidong_screen_teacher.dart';
import 'lecturer_topic_screen.dart';

// Import các màn hình còn lại (nếu chưa có thì tạo tạm)
import 'cham_diem_screen.dart';
import 'lich_day_screen.dart';
import 'package:doancunhan/screens/notifications_page.dart';
import 'package:doancunhan/screens/change_password_screen.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  // ======================= THÔNG TIN GIẢNG VIÊN =======================
  String userName = 'Giảng viên';
  String userEmail = 'Chưa có email';
  String userId = 'Không rõ';
  String userHocVi = 'Chưa cập nhật';
  String userKhoaBoMon = 'Chưa cập nhật';
  String userBirthday = 'Chưa cập nhật';
  String userRole = 'Giảng viên';
  String userChuyenMon = 'Chưa cập nhật';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ======================= LOAD USER INFO =======================
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
      final giangvien = user['giangvien'] as Map<String, dynamic>? ?? {};

      setState(() {
        userName = user['HODEM_VA_TEN']?.toString() ?? 'Giảng viên';
        userEmail = user['EMAIL']?.toString() ?? 'Chưa có email';
        userId = user['MA_DINHDANH']?.toString() ?? 'Không rõ';
        userHocVi = giangvien['HOCVI']?.toString() ?? 'Chưa cập nhật';
        userChuyenMon = giangvien['CHUYENMON']?.toString() ?? 'Chưa cập nhật';
        userRole = user['vaitro']?['TEN_VAITRO']?.toString() ?? 'Giảng viên';

        userKhoaBoMon = giangvien['ID_KHOA_BOMON'] != null
            ? "Khoa/Bộ môn: ${giangvien['ID_KHOA_BOMON']}"
            : "Chưa cập nhật";

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

    if (mounted) setState(() => _isLoading = false);
  }

  // ======================= ĐĂNG XUẤT =======================
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
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
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // ======================= LỜI CHÀO =======================
  String getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Chúc Thầy/Cô buổi sáng vui vẻ";
    if (hour < 18) return "Chúc Thầy/Cô buổi chiều năng động";
    return "Chúc Thầy/Cô buổi tối giảng dạy hiệu quả";
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

  // ======================= UI =======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            _buildInfoRow(Icons.badge_rounded, "Mã giảng viên", userId),
            _buildInfoRow(Icons.school_rounded, "Học vị", userHocVi),
            _buildInfoRow(Icons.workspace_premium, "Chuyên môn", userChuyenMon),
            _buildInfoRow(Icons.cake_rounded, "Ngày sinh", userBirthday),
            _buildInfoRow(Icons.work_outline_rounded, "Vai trò", userRole),

            const SizedBox(height: 30),

            // NÚT ĐỔI MẬT KHẨU – NHỎ NHẮN, ĐẸP, ĐẶT TRÊN ĐĂNG XUẤT
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
                  elevation: 4,
                ),
                onPressed: _logout,
                label: const Text("Đăng xuất", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  ),
),
      // ======================= APPBAR =======================
      // THAY TOÀN BỘ APPBAR NÀY VÀO FILE teacher_home_screen.dart CỦA BẠN

appBar: AppBar(
  backgroundColor: const Color.fromARGB(255, 236, 232, 243),
  elevation: 0,
  centerTitle: false,
  title: Row(
    children: [
      Image.asset('assets/images/huit_logo.png', height: 40),
      const SizedBox(width: 12),
      const Text(
        "FIT.HUIT",
        style: TextStyle(
          color: Color.fromARGB(255, 245, 4, 4),
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    ],
  ),
  actions: [
    // ICON CHUÔNG THÔNG BÁO – BẤM VÀO QUA TRANG NOTIFICATION
    Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none_outlined, size: 28, color: Colors.black87),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            );
          },
        ),
        // Badge số thông báo (nếu cần sau này)
        // Positioned(
        //   right: 8,
        //   top: 8,
        //   child: Container(
        //     padding: EdgeInsets.all(4),
        //     decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
        //     child: Text("3", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        //   ),
        // ),
      ],
    ),

    // Nút cài đặt (giữ nguyên mở drawer)
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
              gradient: LinearGradient(
                colors: [Color.fromARGB(255, 49, 58, 226), Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // căn trái 100%
              children: [
                const Text(
                  "Xin chào giảng viên,",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 6),

                Text.rich(
                  TextSpan(
                    children: [
                      if (userHocVi != "Chưa cập nhật")
                        TextSpan(
                          text: "$userHocVi ",
                          style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                          ),
                        ),

                      TextSpan(
                        text: userName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 10),

                Text(
                  getGreetingMessage(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
    
                // Menu Grid – ĐỀ TÀI ĐÃ CÓ CHUYỂN TRANG
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 1.05,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildFeature(
                          "Tin tức",
                          Icons.article,
                          Colors.orangeAccent,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsScreen())),
                        ),

                        _buildFeature(
                          "Hội đồng",
                          Icons.groups,
                          Colors.deepPurple,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HoiDongGiangVienScreen())),
                        ),

                        // ĐỀ TÀI – CHUYỂN TRANG THÀNH CÔNG
                        _buildFeature(
                          "Đề tài",
                          Icons.dashboard_rounded,
                          Colors.indigo,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => LecturerTopicScreen()),
                            );
                          },
                        ),

                        _buildFeature(
                          "Chấm điểm",
                          Icons.edit_note_rounded,
                          Colors.green,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChamDiemScreen())),
                        ),

                        _buildFeature(
                          "Lịch dạy",
                          Icons.calendar_today_rounded,
                          Colors.blueAccent,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LichDayScreen())),
                        ),

                        _buildFeature(
                          "Hồ sơ",
                          Icons.person_outline_rounded,
                          Colors.purple,
                          onTap: () => Scaffold.of(context).openEndDrawer(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}