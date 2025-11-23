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
  bool loading = true;
  bool registering = false;
  int? groupId;

  @override
  void initState() {
    super.initState();
    loadDetail();
  }

  Future<void> loadDetail() async {
    setState(() => loading = true);

    try {
      detail = await ApiService.getTopicDetail(widget.topicId);
      final myGroup = await ApiService.getMyGroup();
      groupId = myGroup["ID_NHOM"];
    } catch (e) {
      debugPrint("❌ LOAD DETAIL ERROR: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> registerTopic() async {
    if (groupId == null) {
      _showSnack("Bạn chưa có nhóm để đăng ký!", Colors.red);
      return;
    }

    setState(() => registering = true);

    try {
      final result = await ApiService.registerTopic(widget.topicId);
      final success = result["success"] == true || result["success"] == "true";

      _showSnack(
        result["message"] ?? (success ? "Đăng ký thành công!" : "Đăng ký thất bại"),
        success ? Colors.green : Colors.red,
      );

      if (success) await loadDetail();
    } catch (e) {
      _showSnack("Lỗi đăng ký", Colors.red);
    } finally {
      setState(() => registering = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef2f5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        title: const Text(
          "Chi tiết đề tài",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : detail == null
              ? const Center(child: Text("Không tìm thấy dữ liệu"))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // TIÊU ĐỀ
                    Text(
                      detail!["TEN_DETAI"] ?? "Không có tên đề tài",
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // CARD THÔNG TIN
                    _infoCard(
                      icon: Icons.description,
                      title: "Mô tả đề tài",
                      value: detail!["MOTA"] ?? "Không có mô tả",
                    ),

                    _infoCard(
                      icon: Icons.school,
                      title: "Giảng viên hướng dẫn",
                      value: detail!["ten_giang_vien"] ??
                          detail!["GIANGVIEN"]?["TEN_GV"] ??
                          "Chưa có thông tin",
                    ),

                    _infoCard(
                      icon: Icons.person,
                      title: "Người đề xuất",
                      value: detail!["nguoi_dexuat"]?["nguoidung"]?["HODEM_VA_TEN"] ??
                          "Không có",
                    ),

                    if (detail!["nhom_dangky"] != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          "Đề tài đã được đăng ký bởi nhóm: ${detail!["nhom_dangky"]["TEN_NHOM"]}",
                          style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ),

                    const SizedBox(height: 10),

                    // NÚT ĐĂNG KÝ
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (detail!["nhom_dangky"] != null || registering)
                            ? null
                            : registerTopic,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: detail!["nhom_dangky"] != null
                              ? Colors.grey
                              : Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: registering
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                detail!["nhom_dangky"] != null
                                    ? "Đã được đăng ký"
                                    : "Đăng ký đề tài",
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _infoCard({required IconData icon, required String title, required String value}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.06),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blueAccent, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }
}
