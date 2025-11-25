// lib/screens/student/topic_detail_page.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class TopicDetailPage extends StatefulWidget {
  final int topicId;
  const TopicDetailPage({super.key, required this.topicId});

  @override
  State<TopicDetailPage> createState() => _TopicDetailPageState();
}

class _TopicDetailPageState extends State<TopicDetailPage> {
  Map<String, dynamic>? detail;
  Map<String, dynamic>? myGroup;
  Map<String, dynamic>? currentUser;
  bool loading = true;
  bool registering = false;

  // DÙNG CHÍNH XÁC HỆ THỐNG CỦA BẠN
  bool get isGroupLeader {
    if (myGroup == null || myGroup?['has_group'] != true) return false;
    final group = _safeMap(myGroup?['group_data']);
    final leaderId = _toInt(group['ID_NHOMTRUONG']);
    if (leaderId == null) return false;
    final currentUserId = _toInt(currentUser?['ID_NGUOIDUNG']) ?? _toInt(currentUser?['ID_SINHVIEN']);
    return leaderId == currentUserId;
  }

  // Helper giống hệ thống bạn đang dùng
  Map<String, dynamic> _safeMap(dynamic data) => data is Map<String, dynamic> ? data : {};
  int? _toInt(dynamic value) => value is int ? value : (value is String ? int.tryParse(value) : null);

  @override
  void initState() {
    super.initState();
    loadDetail();
  }

  Future<void> loadDetail() async {
    setState(() => loading = true);
    try {
      // GỌI RIÊNG → KHÔNG LỖI Object → Map<String, dynamic>
      final topicDetail = await ApiService.getTopicDetail(widget.topicId);
      final groupResult = await ApiService.getMyGroup();
      final userResult = await ApiService.getCurrentUser();

      currentUser = userResult as Map<String, dynamic>?;

      if (mounted) {
        setState(() {
          detail = topicDetail as Map<String, dynamic>?;
          myGroup = groupResult as Map<String, dynamic>?;
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("LOAD DETAIL ERROR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi tải dữ liệu: $e"), backgroundColor: Colors.red),
        );
        setState(() => loading = false);
      }
    }
  }

  Future<void> registerTopic() async {
    if (!isGroupLeader) {
      _showSnack("Chỉ nhóm trưởng mới được phép đăng ký đề tài!", const Color(0xFFEF6C00));
      return;
    }

    final isRegistered = detail?["phancong_detai_nhom"] != null && detail!["phancong_detai_nhom"].isNotEmpty;
    if (isRegistered) {
      _showSnack("Đề tài đã có nhóm đăng ký!", const Color(0xFFC62828));
      return;
    }

    setState(() => registering = true);
    try {
      final result = await ApiService.registerTopic(widget.topicId);
      final success = result["success"] == true || result["success"] == "true";

      _showSnack(
        result["message"] ?? (success ? "Đăng ký thành công!" : "Đăng ký thất bại"),
        success ? Colors.green : const Color(0xFFC62828),
      );

      if (success) await loadDetail();
    } catch (e) {
      _showSnack("Lỗi kết nối: $e", const Color(0xFFC62828));
    } finally {
      if (mounted) setState(() => registering = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isRegistered = detail?["phancong_detai_nhom"] != null && detail!["phancong_detai_nhom"].isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text("Chi tiết đề tài", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: loadDetail)],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : detail == null
              ? const Center(child: Text("Không tải được dữ liệu", style: TextStyle(fontSize: 16)))
              : RefreshIndicator(
                  onRefresh: loadDetail,
                  color: Colors.indigo,
                  child: ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Colors.indigo, Colors.deepPurple]),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 8))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(detail!["MA_DETAI"] ?? "Chưa có mã", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            const SizedBox(height: 8),
                            Text(
                              detail!["TEN_DETAI"] ?? "Không có tên",
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.3),
                            ),
                            const SizedBox(height: 12),
                            Row(children: [
                              Chip(
                                backgroundColor: Colors.white.withOpacity(0.3),
                                label: Text(detail!["TRANGTHAI"] ?? "Chưa duyệt", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              Text("Tối đa: ${detail!["SO_NHOM_TOIDA"]} nhóm", style: const TextStyle(color: Colors.white70)),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Thông tin chi tiết
                      _buildInfoSection("Mô tả đề tài", detail!["MOTA"] ?? "Không có mô tả", Icons.description_rounded),
                      _buildInfoSection(
                        "Giảng viên hướng dẫn",
                        detail!["ten_giang_vien"] ?? "Chưa có",
                        Icons.person_rounded,
                        subtitle: detail!["nguoi_dexuat"]?["nguoidung"]?["EMAIL"],
                      ),
                      _buildInfoSection(
                        "Chuyên ngành",
                        detail!["chuyennganh"]?["TEN_CHUYENNGANH"] ?? "Không xác định",
                        Icons.school_rounded,
                        subtitle: detail!["chuyennganh"]?["MA_CHUYENNGANH"],
                      ),
                      _buildInfoSection(
                        "Đợt khóa luận",
                        detail!["kehoach_khoaluan"]?["TEN_DOT"] ?? "Chưa xác định",
                        Icons.event_available_rounded,
                        subtitle: "${detail!["kehoach_khoaluan"]?["NAMHOC"]} • HK ${detail!["kehoach_khoaluan"]?["HOCKY"]}",
                      ),

                      const SizedBox(height: 20),

                      // Đã có nhóm đăng ký
                      if (isRegistered)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFC62828)),
                          ),
                          child: const Row(children: [
                            Icon(Icons.block, color: Color(0xFFC62828)),
                            SizedBox(width: 12),
                            Expanded(child: Text("Đề tài đã được nhóm khác đăng ký!", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC62828), fontSize: 16))),
                          ]),
                        ),

                      // Không phải nhóm trưởng
                      if (myGroup != null && !isGroupLeader && !isRegistered)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFEF6C00)),
                          ),
                          child: const Row(children: [
                            Icon(Icons.info_outline, color: Color(0xFFEF6C00)),
                            SizedBox(width: 12),
                            Expanded(child: Text("Chỉ nhóm trưởng mới được phép đăng ký đề tài.", style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFEF6C00)))),
                          ]),
                        ),

                      const SizedBox(height: 30),

                      // Nút đăng ký
                      if (!isRegistered && myGroup != null)
                        SizedBox(
                          height: 58,
                          child: ElevatedButton.icon(
                            onPressed: isGroupLeader ? (registering ? null : registerTopic) : null,
                            icon: registering
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : const Icon(Icons.how_to_reg_rounded),
                            label: Text(
                              registering
                                  ? "Đang xử lý..."
                                  : isGroupLeader
                                      ? "Đăng ký đề tài này"
                                      : "Chỉ nhóm trưởng được đăng ký",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isGroupLeader ? Colors.indigo : Colors.grey,
                              foregroundColor: Colors.white,
                              elevation: isGroupLeader ? 8 : 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),

                      if (!isRegistered && myGroup == null)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16)),
                          child: const Text(
                            "Bạn chưa tham gia nhóm nào. Vui lòng tạo hoặc tham gia nhóm trước khi đăng ký đề tài.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, color: Colors.blue),
                          ),
                        ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoSection(String title, String content, IconData icon, {String? subtitle}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.indigo, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(fontSize: 15.5, height: 1.5)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600], fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}
