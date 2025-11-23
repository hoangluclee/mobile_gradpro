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
  Map<String, dynamic>? myGroupData;
  Map<String, dynamic>? myRegisteredTopic;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);
    try {
      final results = await Future.wait([
        ApiService.getTopics(widget.planId),
        ApiService.getMyGroup(),
      ]);

      final rawTopics = results[0];
      final groupResult = results[1];

      Map<String, dynamic>? topic = null;
      Map<String, dynamic>? groupData = null;

      if (groupResult is Map<String, dynamic> && groupResult['has_group'] == true) {
        groupData = groupResult;
        final group = groupResult['group_data'];
        final phancong = group['phancong_detai_nhom'] as Map<String, dynamic>?;
        topic = phancong?['detai'] as Map<String, dynamic>?;
      }

      if (mounted) {
        setState(() {
          topics = (rawTopics is List) ? List<dynamic>.from(rawTopics) : <dynamic>[];
          myGroupData = groupData;
          myRegisteredTopic = topic;
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Load error: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> registerTopic(int topicId) async {
    if (myGroupData == null) {
      _showMessage("Bạn chưa có nhóm để đăng ký!");
      return;
    }

    try {
      final res = await ApiService.registerTopic(topicId);
      if (res["message"]?.toString().contains("thành công") == true) {
        _showMessage("Đăng ký thành công!", isSuccess: true);
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => TopicDetailPage(topicId: topicId)));
          loadData();
        }
      } else {
        _showMessage(res["message"] ?? "Không thể đăng ký");
      }
    } catch (e) {
      _showMessage("Lỗi: $e");
    }
  }

  void _showMessage(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isSuccess ? Colors.green : Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6fb),
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Danh sách đề tài", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xff6a5af9), Color(0xff836fff)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // CARD ĐỀ TÀI CỦA NHÓM TÔI – NHỎ GỌN, ĐẸP, KHÔNG ICON
                  if (myRegisteredTopic != null) ...[
                    _buildMyTopicCard(),
                    const SizedBox(height: 16),
                  ],

                  // Danh sách đề tài
                  ...topics.map((t) => _buildTopicCard(t)).toList(),

                  if (topics.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Không có đề tài nào"))),
                ],
              ),
            ),
    );
  }

  // CARD ĐỀ TÀI CỦA NHÓM MÌNH – NHỎ GỌN, SẠCH SẼ
  Widget _buildMyTopicCard() {
    final topic = myRegisteredTopic!;
    final groupName = myGroupData?['group_data']?['TEN_NHOM'] ?? 'Nhóm chưa đặt tên';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ĐỀ TÀI CỦA NHÓM ", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(topic['TEN_DETAI'] ?? 'Chưa có tên', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Text("Nhóm: $groupName", style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text("Mã: ${topic['MA_DETAI'] ?? '—'}", style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TopicDetailPage(topicId: topic['ID_DETAI']))),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.deepPurple, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              child: const Text("Xem chi tiết", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // CARD ĐỀ TÀI SIÊU ĐẸP – HIỂN THỊ ĐẦY ĐỦ THÔNG TIN
Widget _buildTopicCard(Map<String, dynamic> t) {
  final bool isRegistered = t["IS_REGISTERED"] == true;
  final bool isFull = (t["SO_NHOM_HIENTAI"] ?? 0) >= (t["SO_NHOM_TOIDA"] ?? 1);
  final List<dynamic>? registeredGroups = t['nhom_dangky'] ?? t['nhom_da_dangky'];


  // CHUYÊN NGÀNH
  final String chuyenNganh = t['TEN_CHUYENNGANH'] ??
      t['chuyennganh']?['TEN_CHUYENNGANH'] ??
      "Không xác định";

  // MÔ TẢ NGẮN
  final String moTa = (t['MOTA']?.toString() ?? "").trim();
  final String shortDesc = moTa.isEmpty
      ? "Không có mô tả"
      : (moTa.length > 100 ? "${moTa.substring(0, 100)}..." : moTa);

  return Card(
    margin: const EdgeInsets.only(bottom: 16),
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => TopicDetailPage(topicId: t["ID_DETAI"])));
        loadData();
      },
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TIÊU ĐỀ + BADGE TRẠNG THÁI
            Row(
              children: [
                Expanded(
                  child: Text(
                    t["TEN_DETAI"] ?? "Không có tên",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (isFull) _statusChip("ĐÃ ĐỦ", Colors.red),
                    if (isRegistered) _statusChip("ĐÃ ĐĂNG KÝ", Colors.deepPurple),
                    if (!isFull && !isRegistered) _statusChip("${t["SO_NHOM_HIENTAI"] ?? 0}/${t["SO_NHOM_TOIDA"] ?? 1}", Colors.orange),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // MÔ TẢ NGẮN
            Text(
              shortDesc,
              style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 16),

            // THÔNG TIN CHI TIẾT
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _infoRow(Icons.school, "Chuyên ngành", chuyenNganh),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // NÚT ĐĂNG KÝ
                SizedBox(
                  width: 130,
                  child: ElevatedButton(
                    onPressed: isFull || isRegistered ? null : () => registerTopic(t["ID_DETAI"]),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFull || isRegistered ? Colors.grey[400] : const Color(0xFF6A5AF9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: isFull || isRegistered ? 0 : 6,
                    ),
                    child: Text(
                      isRegistered ? "ĐÃ ĐĂNG KÝ" : isFull ? "ĐÃ ĐỦ" : "ĐĂNG KÝ",
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),

            // NHÓM ĐÃ ĐĂNG KÝ (NẾU CÓ)
            if ((registeredGroups?.isNotEmpty ?? false) || (isRegistered && myGroupData != null))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.group, color: Colors.deepPurple, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Đã đăng ký: ${(registeredGroups ?? []).map((g) => g['TEN_NHOM'] ?? 'Nhóm').join(', ')}${isRegistered && myGroupData != null ? (registeredGroups?.isNotEmpty ?? false) ? ', ${myGroupData!['group_data']?['TEN_NHOM']}' : myGroupData!['group_data']?['TEN_NHOM'] : '' : ''}",
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.deepPurple),
                        ),
                      ),
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

// HÀM HỖ TRỢ
Widget _infoRow(IconData icon, String label, String value) {
  return Row(
    children: [
      Icon(icon, size: 18, color: Colors.deepPurple),
      const SizedBox(width: 8),
      Text("$label: ", style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black87)),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13.5, color: Colors.black87), overflow: TextOverflow.ellipsis)),
    ],
  );
}

Widget _statusChip(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.5))),
    child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
  );
}
}