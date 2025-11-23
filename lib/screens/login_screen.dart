// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;
  bool isPasswordVisible = false;

  // Map chuyên ngành giảng viên (theo ID_KHOA_BOMON)
  static const Map<int, String> lecturerMajorMap = {
    1: 'Khoa học máy tính',
    2: 'Kỹ thuật phần mềm',
    3: 'Hệ thống thông tin',
    4: 'Mạng máy tính & Truyền thông',
    5: 'An toàn thông tin',
    6: 'Trí tuệ nhân tạo',
  };

  Future<void> login() async {
    final identifier = emailController.text.trim();
    final password = passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      setState(() => errorMessage = "Vui lòng nhập đầy đủ thông tin.");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await Dio().post(
        '${ApiService.baseUrl}/login',
        data: {'identifier': identifier, 'password': password},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['access_token'] ?? data['token'] ?? '';
        final userRaw = Map<String, dynamic>.from(data['user'] ?? {});

        if (token.isEmpty) {
          setState(() => errorMessage = 'Không nhận được token từ server.');
          return;
        }

        // XỬ LÝ CHUYÊN NGÀNH GIẢNG VIÊN
        final giangvien = userRaw['giangvien'];
        if (giangvien != null && giangvien is Map<String, dynamic>) {
          final deptId = giangvien['ID_KHOA_BOMON'] as int?;
          final currentMajor = giangvien['CHUYENMON']?.toString().trim();

          final resolvedMajor = (currentMajor != null && currentMajor.isNotEmpty)
              ? currentMajor
              : lecturerMajorMap[deptId] ?? "Chưa cập nhật";

          giangvien['CHUYENMON'] = resolvedMajor;
          debugPrint("GIẢNG VIÊN | Chuyên môn: $resolvedMajor");
        }

        // XỬ LÝ CHUYÊN NGÀNH SINH VIÊN
        final sinhvien = userRaw['sinhvien'];
        if (sinhvien != null && sinhvien is Map<String, dynamic>) {
          final majorName = sinhvien['TEN_CHUYENNGANH']?.toString().trim();
          userRaw['CHUYENNGANH'] = majorName?.isNotEmpty == true ? majorName : "Chưa cập nhật";
        }

        // Lấy tên và vai trò
        final hoTen = userRaw['HODEM_VA_TEN']?.toString() ?? 'Người dùng';
        final vaiTro = userRaw['vaitro']?['TEN_VAITRO']?.toString() ?? 'Sinh viên';
        // Lưu vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('user_name', hoTen);
        await prefs.setString('user_role', vaiTro);
        await prefs.setString('user_info', jsonEncode(userRaw));

        // Cập nhật token cho Dio ngay lập tức
        // (ApiService._ensureAuth không tồn tại) — loại bỏ cuộc gọi này; nếu cần, implement một phương thức ensureAuth trong ApiService sau
        ApiService.setCurrentUser(data); // Quan trọng: lưu vào ApiService
        ApiService.setCurrentUser(data); // Quan trọng: lưu vào ApiService

        debugPrint("ĐĂNG NHẬP THÀNH CÔNG | $vaiTro - $hoTen");

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home-redirect');
        }
      } else {
        final err = response.data is Map ? response.data : {};
        setState(() => errorMessage = err['message'] ?? 'Sai tài khoản hoặc mật khẩu.');
      }
    } on DioException catch (e) {
      String msg = 'Lỗi kết nối!';
      if (e.response?.data is Map) {
        msg = e.response!.data['message'] ?? msg;
      }
      setState(() => errorMessage = msg);
    } catch (e) {
      setState(() => errorMessage = 'Đã có lỗi xảy ra. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // LOGO + TIÊU ĐỀ
              Column(
                children: [
                  Image.asset('assets/images/huit_logo.png', height: 110),
                  const SizedBox(height: 16),
                  const Text(
                    'ĐẠI HỌC CÔNG THƯƠNG TP.HCM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF3B2ECF),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'KHOA CÔNG NGHỆ THÔNG TIN',
                    style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Color(0xFF6B63FF)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ỨNG DỤNG QUẢN LÝ ĐỒ ÁN - KHÓA LUẬN TỐT NGHIỆP',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w700,
                      color: Colors.red.shade700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 45),

              // CARD ĐĂNG NHẬP
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.14),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Đăng nhập hệ thống",
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF3B2ECF),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Email / MSSV
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Email hoặc Mã sinh viên',
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4C4A6D)),
                        prefixIcon: const Icon(Icons.person, color: Color(0xFF5A4FF3)),
                        filled: true,
                        fillColor: const Color(0xFFF6F5FF),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF6B63FF), width: 2.2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Mật khẩu
                    TextField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => login(),
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4C4A6D)),
                        prefixIcon: const Icon(Icons.lock, color: Color(0xFF5A4FF3)),
                        suffixIcon: IconButton(
                          icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.deepPurple),
                          onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF6F5FF),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF6B63FF), width: 2.2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Lỗi
                    if (errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                        child: Text(errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13.5)),
                      ),

                    const SizedBox(height: 20),

                    // NÚT ĐĂNG NHẬP
                    GestureDetector(
                      onTap: isLoading ? null : login,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: const LinearGradient(colors: [Color(0xFF6A5AE0), Color(0xFF8A7DFE)]),
                          boxShadow: [
                            BoxShadow(color: Colors.deepPurple.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 7)),
                          ],
                        ),
                        child: Center(
                          child: isLoading
                              ? const SizedBox(height: 26, width: 26, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                              : const Text(
                                  'ĐĂNG NHẬP',
                                  style: TextStyle(color: Colors.white, fontSize: 17.5, fontWeight: FontWeight.w900, letterSpacing: 1),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              Text(
                '© 2025 HUIT - Khoa Công nghệ Thông tin',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}