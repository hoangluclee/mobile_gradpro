import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:doancunhan/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  DateTime currentWeek = DateTime.now();
  List<Map<String, dynamic>> meetings = [];
  final dateFormat = DateFormat("dd/MM/yyyy • HH:mm");
  final dateShort = DateFormat("dd/MM");
  

  DateTime get weekStart => currentWeek.subtract(Duration(days: currentWeek.weekday - 1));
  DateTime get weekEnd => weekStart.add(const Duration(days: 6));
  int currentTab = 0;

  @override
  void initState() {
    super.initState();
    loadMeetings();
  }

  Future<void> loadMeetings() async {
  try {
    // LẤY GROUP ID ĐÃ LƯU TRƯỚC ĐÓ (từ GroupScreen)
    final prefs = await SharedPreferences.getInstance();
    int? groupId = prefs.getInt('current_group_id');

    // === FALLBACK: Nếu chưa có prefs thì lấy trực tiếp từ API (đảm bảo 100% có nhóm) ===
    if (groupId == null) {
      debugPrint("Không có group_id trong prefs → lấy từ getMyGroup()");
      final myGroupData = await ApiService.getMyGroup();
      if (myGroupData != null && myGroupData['has_group'] == true) {
        final id = myGroupData['group_data']?['ID_NHOM'];
        groupId = int.tryParse(id.toString() ?? "");
        if (groupId != null) {
          await prefs.setInt('current_group_id', groupId);
          debugPrint("Đã lưu group_id = $groupId vào prefs");
        }
      }
    }

    if (groupId == null) {
      debugPrint("Không tìm thấy nhóm nào");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vui lòng vào màn hình Nhóm trước để tải lịch họp"), backgroundColor: Colors.orange),
        );
      }
      setState(() => meetings = []);
      return;
    }

    debugPrint("Đang tải lịch họp cho nhóm ID: $groupId");
    final data = await ApiService.getMeetingsForGroup(groupId);

    if (data == null || (data is List && data.isEmpty)) {
      debugPrint("Không có lịch họp nào");
      setState(() => meetings = []);
      return;
    }

    setState(() {
      meetings = (data as List).map<Map<String, dynamic>>((e) {
        // === SỬA CHÍNH TẠI ĐÂY: CHUYỂN TỪ UTC → GIỜ VIỆT NAM ===
        final startUtc = DateTime.tryParse(e["THOIGIAN_BATDAU"]?.toString() ?? "");
        final endUtc = DateTime.tryParse(e["THOIGIAN_KETTHUC"]?.toString() ?? "");

        final start = startUtc?.toLocal(); // ← QUAN TRỌNG NHẤT!
        final end = endUtc?.toLocal() ?? start?.add(const Duration(hours: 1));

        return {
          "id": e["ID_LICHHOP"],
          "title": e["TIEUDE_LICHHOP"] ?? "Cuộc họp nhóm",
          "start": start ?? DateTime.now(),
          "end": end ?? start?.add(const Duration(hours: 1)) ?? DateTime.now(),
          "location": e["DIADIEM"] ?? "Chưa xác định",
          "form": e["HINHTHUC_HOP"] ?? "Trực tiếp",
          "note": e["GHICHU"],
          "content": e["NOIDUNG_HOP"],
          "creator": e["nguoi_tao"]?["HODEM_VA_TEN"] ?? "Không rõ",
          "status": e["TRANGTHAI"] ?? "Đã lên lịch",
          "session": _detectSession(start),
          "day": start?.weekday ?? DateTime.now().weekday, // Đảm bảo đúng thứ
        };
      }).toList();

      // Sắp xếp theo thời gian
      meetings.sort((a, b) => (a['start'] as DateTime).compareTo(b['start'] as DateTime));
    });

    _notifyTodayMeetings();
  } catch (e) {
    debugPrint("Lỗi load lịch họp: $e");
    if (mounted) {
      setState(() => meetings = []);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi tải lịch: $e"), backgroundColor: Colors.red),
      );
    }
  }
}

  String _detectSession(DateTime? dt) {
    if (dt == null) return "";
    if (dt.hour < 12) return "Sáng";
    if (dt.hour < 18) return "Chiều";
    return "Tối";
  }

  // Dialog thông báo hôm nay - đẹp, căn giữa, icon chuẩn
  void _notifyTodayMeetings() {
    final today = DateTime.now().weekday;
    final todayMeetings = meetings.where((m) => m["day"] == today).toList();
    if (todayMeetings.isEmpty) return;

    Future.delayed(const Duration(milliseconds: 300), () {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(FluentIcons.alert_28_filled, color: Colors.red, size: 32),
              SizedBox(width: 12),
              Text("Lịch họp hôm nay", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: todayMeetings.map((m) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(FluentIcons.calendar_day_20_filled, color: Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m['title'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(dateFormat.format(m['start']), style: const TextStyle(fontSize: 13.5)),
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(FluentIcons.dismiss_20_filled),
              label: const Text("Đóng"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
      );
    });
  }

  void nextWeek() => setState(() => currentWeek = currentWeek.add(const Duration(days: 7)));
  void prevWeek() => setState(() => currentWeek = currentWeek.subtract(const Duration(days: 7)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FluentIcons.calendar_agenda_28_filled, color: Colors.blue, size: 32),
            SizedBox(width: 10),
            Text("Lịch họp nhóm", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                tabButton("Lịch tuần", currentTab == 0, () => setState(() => currentTab = 0)),
                const SizedBox(width: 12),
                tabButton("Danh sách", currentTab == 1, () => setState(() => currentTab = 1)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: currentTab == 0 ? buildWeeklyCalendar() : buildListView()),
        ],
      ),
    );
  }

  Widget buildWeeklyCalendar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(onPressed: prevWeek, icon: const Icon(FluentIcons.chevron_left_20_filled)),
            Text("${dateShort.format(weekStart)} - ${dateShort.format(weekEnd)}",
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            IconButton(onPressed: nextWeek, icon: const Icon(FluentIcons.chevron_right_20_filled)),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  Row(
                    children: [
                      headerCell("Buổi", width: 100),
                      ...List.generate(7, (i) {
                        final d = weekStart.add(Duration(days: i));
                        final label = ["Th 2", "Th 3", "Th 4", "Th 5", "Th 6", "Th 7", "CN"][i];
                        return headerCell("$label\n${d.day}/${d.month}", width: 130);
                      }),
                    ],
                  ),
                  buildSessionRow("Sáng"),
                  buildSessionRow("Chiều"),
                  buildSessionRow("Tối"),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildSessionRow(String session) => Row(
        children: [
          sessionCell(session),
          ...List.generate(7, (i) => eventCell(i + 1, session)),
        ],
      );

  // Ô lịch tuần - icon đẹp + thời gian + phòng (không emoji)
  Widget eventCell(int dayOfWeek, String session) {
    final list = meetings.where((m) => m["day"] == dayOfWeek && m["session"] == session).toList();

    return Container(
      width: 130,
      height: 130,
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: list.isEmpty
          ? const SizedBox()
          : Column(
              children: list.map((m) => GestureDetector(
                onTap: () => showMeetingDetail(m),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(FluentIcons.people_community_20_filled, size: 18, color: Colors.green),
                      const SizedBox(height: 6),
                      Text(m["title"], maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      Row(children: [const Icon(FluentIcons.clock_16_filled, size: 14, color: Colors.black87), const SizedBox(width: 4), Text(DateFormat("HH:mm").format(m['start']), style: const TextStyle(fontSize: 11.5))]),
                      Row(children: [const Icon(FluentIcons.location_16_filled, size: 14, color: Colors.black87), const SizedBox(width: 4), Text(m['location'] ?? "", style: const TextStyle(fontSize: 11.5))]),
                    ],
                  ),
                ),
              )).toList(),
            ),
    );
  }

  Widget headerCell(String text, {double width = 120}) => Container(
        width: width,
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue.shade200)),
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
      );

  Widget sessionCell(String text) => Container(
        width: 100,
        height: 130,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber.shade300)),
        child: Center(child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
      );

  // Chi tiết họp - icon chuẩn, không emoji, đẹp như app doanh nghiệp
  void showMeetingDetail(Map<String, dynamic> m) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(FluentIcons.calendar_info_20_filled, color: Colors.blue, size: 28),
            SizedBox(width: 12),
            Text("Chi tiết lịch họp", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(FluentIcons.clock_20_filled, "Bắt đầu", dateFormat.format(m['start'])),
              _detailRow(FluentIcons.clock_20_filled, "Kết thúc", dateFormat.format(m['end'])),
              _detailRow(FluentIcons.location_20_filled, "Địa điểm", m['location'] ?? "-"),
              _detailRow(FluentIcons.person_20_filled, "Người tạo", m['creator'] ?? "Không rõ"),
              _detailRow(FluentIcons.video_person_20_filled, "Hình thức", m['form'] ?? "-"),
              if (m['note'] != null && m['note'].toString().isNotEmpty) _detailRow(FluentIcons.note_20_filled, "Ghi chú", m['note']),
              if (m['content'] != null && m['content'].toString().isNotEmpty) _detailRow(FluentIcons.document_20_filled, "Nội dung", m['content']),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(FluentIcons.dismiss_20_filled),
            label: const Text("Đóng"),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: Colors.blueGrey[700]),
            const SizedBox(width: 14),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black87, fontSize: 14.5),
                  children: [
                    TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: value),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  // Danh sách - icon đẹp, không emoji
  Widget buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: meetings.length,
      itemBuilder: (_, i) {
        final m = meetings[i];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(FluentIcons.calendar_multiple_32_filled, color: Colors.indigo, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m["title"], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text("${dateFormat.format(m['start'])} - ${dateFormat.format(m['end'])}", style: const TextStyle(color: Colors.black87)),
                      const SizedBox(height: 10),
                      Row(children: [const Icon(FluentIcons.location_16_filled), const SizedBox(width: 6), Expanded(child: Text(m['location'] ?? ""))]),
                      Row(children: [const Icon(FluentIcons.person_16_filled), const SizedBox(width: 6), Text(m['creator'] ?? "")]),
                      Row(children: [const Icon(FluentIcons.video_person_16_filled), const SizedBox(width: 6), Text(m['form'] ?? "")]),
                      if (m["note"] != null && m["note"].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(children: [const Icon(FluentIcons.note_16_filled), const SizedBox(width: 6), Expanded(child: Text(m["note"]))]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget tabButton(String text, bool active, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 46,
            decoration: BoxDecoration(color: active ? Colors.blue : Colors.grey.shade300, borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: Text(text, style: TextStyle(fontSize: 15, color: active ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      );
}