// lib/screens/teacher/lecturer_topic_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class LecturerTopicScreen extends StatefulWidget {
  @override
  _LecturerTopicScreenState createState() => _LecturerTopicScreenState();
}

class _LecturerTopicScreenState extends State<LecturerTopicScreen> {
  int pendingCount = 0;
  int guidingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.getPendingRegistrations(),
        ApiService.getMyGuidingGroups(),
      ]);

      if (mounted) {
        setState(() {
          pendingCount = results[0].length;
          guidingCount = results[1].length;
        });
      }
    } catch (e) {
      debugPrint("Load data error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Đề tài của tôi", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData)],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
  _actionCard("Tạo đề tài mới", Icons.add_task, Colors.indigo, () => _showCreateDialog()),
                const SizedBox(width: 12),
                _actionCard("Duyệt đăng ký", Icons.how_to_reg, Colors.orange, () => _showPending(), badge: pendingCount),
              ],
            ),
            const SizedBox(height: 12),
            _actionCard("Nhóm đang hướng dẫn", Icons.groups_3, Colors.green[600]!, () => _showGuidingGroups(), badge: guidingCount),

            const SizedBox(height: 30),

            const Text("Đề tài đã đề xuất", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 10),

            FutureBuilder<List<dynamic>>(
              future: ApiService.getMyTopics(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(child: Text("Chưa có đề tài nào", style: TextStyle(color: Colors.grey[600], fontSize: 16))),
                    ),
                  );
                }

                return Column(
                  children: snapshot.data!.asMap().entries.map((e) {
                    final i = e.key;
                    final t = e.value;

                    final String title = t['TEN_DETAI']?.toString() ?? "Không tên";
                    final String status = t['TRANGTHAI']?.toString() ?? 'Nháp';
                    final int currentGroups = int.tryParse(t['SO_NHOM_HIENTAI']?.toString() ?? '0') ?? 0;
                    final int maxGroups = int.tryParse(t['SO_NHOM_TOIDA']?.toString() ?? '1') ?? 1;

                    final String lecturerName = t['ten_giang_vien']?.toString() ??
                        t['nguoi_dexuat']?['nguoidung']?['HODEM_VA_TEN']?.toString() ??
                        "Không rõ";

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(18),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: status.contains('duyệt') ? Colors.green : Colors.orange[700],
                          child: Text("${i + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                        title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text("Giảng viên: $lecturerName", style: TextStyle(fontSize: 14, color: Colors.blue[700], fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.group, size: 16, color: Colors.grey[700]),
                                const SizedBox(width: 6),
                                Text("$currentGroups/$maxGroups nhóm", style: const TextStyle(fontSize: 13)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: status.contains('duyệt') ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(status, style: TextStyle(fontSize: 12, color: status.contains('duyệt') ? Colors.green[800] : Colors.orange[800], fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _actionCard(String title, IconData icon, Color color, VoidCallback onTap, {int badge = 0}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 130,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.85)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Stack(
            children: [
              Icon(icon, size: 44, color: Colors.white),
              Positioned(bottom: 12, left: 0, right: 0, child: Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
              if (badge > 0)
                Positioned(top: 8, right: 8, child: CircleAvatar(radius: 14, backgroundColor: Colors.red, child: Text("$badge", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateDialog() { /* giữ nguyên */ }
  void _showPending() async { /* giữ nguyên */ }

  // NHÓM ĐANG HƯỚNG DẪN – CLICK VÀO XEM CHI TIẾT NHÓM + SINH VIÊN
  void _showGuidingGroups() async {
    final groups = await ApiService.getMyGuidingGroups();
    if (!mounted) return;

    setState(() => guidingCount = groups.length);
    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bạn chưa hướng dẫn nhóm nào")));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(
            children: [
              const Padding(padding: EdgeInsets.all(16), child: Text("Nhóm đang hướng dẫn", style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.green))),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: groups.length,
                  itemBuilder: (_, i) {
                    final g = groups[i];

                    // LẤY TÊN NHÓM & ĐỀ TÀI CHÍNH XÁC
                    String groupName = "Nhóm không tên";
                    try {
                      final nhomData = g['nhom'] ?? g;
                      groupName = nhomData['TEN_NHOM']?.toString().trim() ??
                          nhomData['ten_nhom']?.toString().trim() ??
                          nhomData['MA_NHOM']?.toString() ??
                          "Nhóm ${nhomData['ID_NHOM'] ?? i + 1}";
                    } catch (_) {}

                    String topicName = "Chưa có đề tài";
                    try {
                      topicName = g['detai']?['TEN_DETAI']?.toString().trim() ??
                          g['TEN_DETAI']?.toString().trim() ??
                          "Chưa có đề tài";
                    } catch (_) {}

                    final firstLetter = groupName.isNotEmpty ? groupName[0].toUpperCase() : "N";

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(20),
                        leading: CircleAvatar(
                          radius: 34,
                          backgroundColor: Colors.green.shade700,
                          child: Text(firstLetter, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(groupName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text("Đề tài: $topicName", style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500)),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.green, size: 22),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => GroupDetailScreen(groupData: g)));
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== CHI TIẾT NHÓM + HIỆN ĐẦY ĐỦ THÀNH VIÊN ====================
class GroupDetailScreen extends StatelessWidget {
  final Map<String, dynamic> groupData;
  const GroupDetailScreen({required this.groupData, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final nhomData = groupData['nhom'] ?? groupData;
    final groupName = nhomData['TEN_NHOM']?.toString().trim() ?? "Nhóm không tên";
    final topicName = groupData['detai']?['TEN_DETAI']?.toString().trim() ?? "Chưa có đề tài";

    // FIX 100%: LẤY CHÍNH XÁC KEY thanhvien_nhom TỪ BACKEND
    List<dynamic> members = [];
    try {
      members = nhomData['thanhvien_nhom'] ?? 
                groupData['nhom']?['thanhvien_nhom'] ?? 
                groupData['thanhvien_nhom'] ?? 
                [];
    } catch (e) {
      members = [];
    }

    final leaderId = nhomData['ID_NHOMTRUONG'];

    return Scaffold(
      appBar: AppBar(
        title: Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(radius: 40, backgroundColor: Colors.green.shade100, child: Icon(Icons.groups, size: 48, color: Colors.green.shade800)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(groupName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text("Đề tài: $topicName", style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Thành viên nhóm", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text("${members.length} thành viên", style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 12),

            if (members.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: Text("Chưa có thành viên nào", style: TextStyle(color: Colors.grey.shade600, fontSize: 16))),
                ),
              )
            else
              ...members.map((m) {
                final sv = m['nguoidung'] ?? m;
                final hoTen = sv['HODEM_VA_TEN']?.toString() ?? "Không rõ";
                final mssv = sv['MA_DINHDANH']?.toString() ?? "N/A";
                final isTruongNhom = m['ID_NGUOIDUNG'] == leaderId;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isTruongNhom ? Colors.orange.shade100 : Colors.grey.shade200,
                      child: Text(hoTen.isNotEmpty ? hoTen[0].toUpperCase() : "?", style: TextStyle(color: isTruongNhom ? Colors.orange.shade800 : Colors.grey.shade700, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(hoTen, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(mssv),
                    trailing: isTruongNhom
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                            child: const Text("Trưởng nhóm", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        : null,
                  ),
                );
              }).toList(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}