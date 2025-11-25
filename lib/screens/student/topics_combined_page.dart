// lib/screens/student/topics_combined_page.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'topic_detail_page.dart';

class TopicRegisterScreen extends StatefulWidget {
  final int planId;
  const TopicRegisterScreen({super.key, required this.planId});

  @override
  State<TopicRegisterScreen> createState() => _TopicRegisterScreenState();
}

class _TopicRegisterScreenState extends State<TopicRegisterScreen> {
  bool loading = true;
  List topics = [];
  Map<String, dynamic>? myGroup;
  Map<String, dynamic>? myRegisteredTopic;
  Map<String, dynamic>? currentUser; // Lấy từ ApiService hoặc Provider

  // DÙNG CHÍNH XÁC HÀM CỦA BẠN
  bool get isLeader {
    if (myGroup == null || myGroup?['has_group'] != true) return false;
    final group = _safeMap(myGroup?['group_data']);
    final leaderId = _toInt(group['ID_NHOMTRUONG']);
    if (leaderId == null) return false;
    final currentUserId = _toInt(currentUser?['ID_NGUOIDUNG']) ?? _toInt(currentUser?['ID_SINHVIEN']);
    return leaderId == currentUserId;
  }

  // Helper functions (giống hệ thống bạn đang dùng)
  Map<String, dynamic> _safeMap(dynamic data) => data is Map<String, dynamic> ? data : {};
  int? _toInt(dynamic value) => value is int ? value : (value is String ? int.tryParse(value) : null);

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
  setState(() => loading = true);
  try {
    // Gọi riêng → không lỗi Object
    final rawTopics = await ApiService.getTopics(widget.planId);
    final groupResult = await ApiService.getMyGroup();
    final userResult = await ApiService.getCurrentUser();

    currentUser = userResult as Map<String, dynamic>?;

    Map<String, dynamic>? topic = null;
    Map<String, dynamic>? groupData = null;

    if (groupResult is Map<String, dynamic> && groupResult['has_group'] == true) {
      groupData = groupResult;
      final group = groupResult['group_data'] as Map<String, dynamic>?;
      if (group != null) {
        final phancong = group['phancong_detai_nhom'] as Map<String, dynamic>?;
        topic = phancong?['detai'] as Map<String, dynamic>?;
      }
    }

    if (mounted) {
      setState(() {
        topics = List<dynamic>.from(rawTopics is List ? rawTopics : []);
        myGroup = groupData;
        myRegisteredTopic = topic;
        loading = false;
      });
    }
  } catch (e) {
    debugPrint("Load error: $e");
    if (mounted) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
      );
    }
  }
}

  Future<void> registerTopic(int topicId) async {
    // DÙNG CHÍNH XÁC HÀM isLeader CỦA BẠN
    if (!isLeader) {
      _showMessage("Chỉ nhóm trưởng mới được phép đăng ký đề tài!", color: const Color(0xFFEF6C00));
      return;
    }

    if (myGroup == null) {
      _showMessage("Bạn chưa có nhóm để đăng ký!");
      return;
    }

    try {
      final res = await ApiService.registerTopic(topicId);
      final success = res["success"] == true || (res["message"]?.toString().contains("thành công") == true);

      _showMessage(
        res["message"] ?? (success ? "Đăng ký thành công!" : "Không thể đăng ký"),
        color: success ? Colors.green : const Color(0xFFC62828),
      );

      if (success) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => TopicDetailPage(topicId: topicId)));
          loadData();
        }
      }
    } catch (e) {
      _showMessage("Lỗi kết nối: $e");
    }
  }

  void _showMessage(String msg, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Danh sách đề tài", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF6A5AF9), Color(0xFF836FFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A5AF9)))
          : RefreshIndicator(
              onRefresh: loadData,
              color: const Color(0xFF6A5AF9),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ĐỀ TÀI CỦA NHÓM MÌNH
                  if (myRegisteredTopic != null) ...[
                    _buildMyTopicCard(),
                    const SizedBox(height: 16),
                  ],

                  // THÔNG BÁO NẾU KHÔNG PHẢI NHÓM TRƯỞNG
                  if (myGroup != null && !isLeader && myRegisteredTopic == null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEF6C00)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Color(0xFFEF6C00)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Chỉ nhóm trưởng mới được phép đăng ký đề tài.",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF6C00), fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // DANH SÁCH ĐỀ TÀI
                  ...topics.map((t) => _buildTopicCard(t)).toList(),

                  if (topics.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(60), child: Text("Không có đề tài nào", style: TextStyle(fontSize: 16, color: Colors.grey)))),
                ],
              ),
            ),
    );
  }

  Widget _buildMyTopicCard() {
    final topic = myRegisteredTopic!;
    final groupName = myGroup?['group_data']?['TEN_NHOM'] ?? 'Nhóm chưa đặt tên';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ĐỀ TÀI CỦA NHÓM:", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(topic['TEN_DETAI'] ?? 'Chưa có tên', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text("Nhóm: $groupName", style: const TextStyle(color: Colors.white70, fontSize: 15)),
          Text("Mã: ${topic['MA_DETAI'] ?? '—'}", style: const TextStyle(color: Colors.white70, fontSize: 15)),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.visibility, size: 20),
              label: const Text("Xem chi tiết", style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TopicDetailPage(topicId: topic['ID_DETAI']))),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.deepPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCard(Map<String, dynamic> t) {
    final bool isRegistered = t["IS_REGISTERED"] == true;
    final bool isFull = (t["SO_NHOM_HIENTAI"] ?? 0) >= (t["SO_NHOM_TOIDA"] ?? 1);
    final List<dynamic>? registeredGroups = t['nhom_dangky'] ?? t['nhom_da_dangky'];

    final String chuyenNganh = t['TEN_CHUYENNGANH'] ?? t['chuyennganh']?['TEN_CHUYENNGANH'] ?? "Không xác định";
    final String moTa = (t['MOTA']?.toString() ?? "").trim();
    final String shortDesc = moTa.isEmpty ? "Không có mô tả" : (moTa.length > 120 ? "${moTa.substring(0, 120)}..." : moTa);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => TopicDetailPage(topicId: t["ID_DETAI"])));
          loadData();
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t["TEN_DETAI"] ?? "Không có tên",
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (isFull) _statusChip("ĐÃ ĐỦ", const Color(0xFFC62828)),
                      if (isRegistered) _statusChip("ĐÃ ĐĂNG KÝ", Colors.deepPurple),
                      if (!isFull && !isRegistered)
                        _statusChip("${t["SO_NHOM_HIENTAI"] ?? 0}/${t["SO_NHOM_TOIDA"] ?? 1}", const Color(0xFFEF6C00)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(shortDesc, style: TextStyle(fontSize: 14.5, color: Colors.grey[700], height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(Icons.school, "Chuyên ngành", chuyenNganh),
                        const SizedBox(height: 6),
                        _infoRow(Icons.person, "GVHD", t["ten_giang_vien"] ?? "Chưa có"),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 140,
                    child: ElevatedButton(
                      onPressed: (isFull || isRegistered || !isLeader)
                          ? null
                          : () => registerTopic(t["ID_DETAI"]),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (isFull || isRegistered || !isLeader)
                            ? Colors.grey[400]
                            : const Color(0xFF6A5AF9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: (isFull || isRegistered || !isLeader) ? 0 : 8,
                      ),
                      child: Text(
                        isRegistered
                            ? "ĐÃ ĐĂNG KÝ"
                            : isFull
                                ? "ĐÃ ĐỦ"
                                : !isLeader
                                    ? "CHỈ NHÓM TRƯỞNG"
                                    : "ĐĂNG KÝ",
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),

              if ((registeredGroups?.isNotEmpty ?? false) || (isRegistered && myGroup != null))
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.deepPurple.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.group, color: Colors.deepPurple, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Đã đăng ký: ${(registeredGroups ?? []).map((g) => g['TEN_NHOM'] ?? 'Nhóm').join(', ')}${isRegistered && myGroup != null ? (registeredGroups?.isNotEmpty ?? false) ? ', ${myGroup!['group_data']?['TEN_NHOM']}' : myGroup!['group_data']?['TEN_NHOM'] : '' : ''}",
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.deepPurple),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 19, color: const Color(0xFF6A5AF9)),
        const SizedBox(width: 8),
        Text("$label: ", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
