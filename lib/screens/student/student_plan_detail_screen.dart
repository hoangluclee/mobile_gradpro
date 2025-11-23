import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ThesisPlanDetailScreen extends StatefulWidget {
  final int planId;
  const ThesisPlanDetailScreen({Key? key, required this.planId}) : super(key: key);

  @override
  State<ThesisPlanDetailScreen> createState() => _ThesisPlanDetailScreenState();
}

class _ThesisPlanDetailScreenState extends State<ThesisPlanDetailScreen> {
  Map<String, dynamic>? plan;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlanDetail();
  }

  Future<void> _fetchPlanDetail() async {
    try {
      final response = await http.get(
        Uri.parse("https://gradpro.test/api/thesis-plans/${widget.planId}"),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        setState(() {
          plan = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load plan");
      }
    } catch (e) {
      debugPrint("❌ Error loading plan detail: $e");
      setState(() => isLoading = false);
    }
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return "Chưa xác định";
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (plan == null) {
      return const Scaffold(
        body: Center(child: Text("Không tải được kế hoạch")),
      );
    }

    final mocThoigians = plan!['moc_thoigians'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FA),
      appBar: AppBar(
        title: Text(plan!['TEN_DOT'] ?? "Chi tiết kế hoạch"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              final url = "https://gradpro.test/api/thesis-plans/${widget.planId}/preview-document";
              debugPrint("PDF preview URL: $url");
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPlanDetail,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildInfoCard(),
            const SizedBox(height: 18),
            const Text(
              "📅 Các mốc thời gian",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            if (mocThoigians.isEmpty)
              const Text("Chưa có mốc thời gian nào.", style: TextStyle(color: Colors.black54))
            else
              ...mocThoigians.map<Widget>((moc) => _buildMilestoneTile(moc)).toList(),
          ],
        ),
      ),
    );
  }

  // ---------------------- INFO CARD ----------------------
  Widget _buildInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan!['TEN_DOT'] ?? '',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _infoRow("Trạng thái", plan!['TRANGTHAI']),
            _infoRow("Khóa học", plan!['KHOAHOC']),
            _infoRow("Hệ đào tạo", plan!['HEDAOTAO']),
            _infoRow("Số tuần thực hiện", plan!['SO_TUAN_THUCHIEN']),
            _infoRow("Ngày bắt đầu", _formatDate(plan!['NGAY_BATDAU'])),
            _infoRow("Ngày kết thúc", _formatDate(plan!['NGAY_KETHUC'])),
            _infoRow("Người tạo", plan!['nguoi_tao']?['HODEM_VA_TEN']),
            _infoRow("Người phê duyệt", plan!['nguoi_phe_duyet']?['HODEM_VA_TEN']),
          ],
        ),
      ),
    );
  }

  // ---------------------- TIMELINE UI ----------------------
Widget _buildMilestoneTile(Map<String, dynamic> moc) {
  final ten = moc['TEN_SUKIEN'] ?? 'Không rõ';
  final mota = moc['MOTA'] ?? '';
  final ngayBD = moc['NGAY_BATDAU'];
  final ngayKT = moc['NGAY_KETTHUC'];

  final now = DateTime.now();
  final start = DateTime.tryParse(ngayBD ?? "");
  final end = DateTime.tryParse(ngayKT ?? "");

  // Trạng thái mốc
  String status = "upcoming";
  if (start != null && end != null) {
    if (end.isBefore(now)) status = "done";
    else if (start.isBefore(now) && end.isAfter(now)) status = "active";
  }

  Color statusColor = status == "done"
      ? Colors.green
      : status == "active"
          ? Colors.blue
          : Colors.grey;

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      /// ICON + LINE
      Column(
        children: [
          _buildTimelineIcon(status),
          Container(
            width: 4,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withOpacity(0.6),
                  statusColor.withOpacity(0.1)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          )
        ],
      ),

      const SizedBox(width: 16),

      /// CONTENT BOX
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withOpacity(0.25), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 7,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.flag, size: 20, color: statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ten,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              /// THỜI GIAN
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: Colors.deepPurple),
                  const SizedBox(width: 6),
                  Text(
                    "${_formatDate(ngayBD)}  →  ${_formatDate(ngayKT)}",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              /// BADGE TRẠNG THÁI
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status == "done"
                      ? "Đã hoàn thành"
                      : status == "active"
                          ? "Đang diễn ra"
                          : "Sắp diễn ra",
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),

              if (mota.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  mota,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ]
            ],
          ),
        ),
      ),
    ],
  );
}


// ---------------------- ICON THEO TRẠNG THÁI ----------------------
Widget _buildTimelineIcon(String status) {
  if (status == "done") {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.green,
      ),
      child: const Icon(Icons.check, color: Colors.white, size: 22),
    );
  }

  if (status == "active") {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue,
      ),
      child: const Icon(Icons.play_arrow, color: Colors.white, size: 22),
    );
  }

  return Container(
    padding: const EdgeInsets.all(4),
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.grey,
    ),
    child: const Icon(Icons.more_horiz, color: Colors.white, size: 20),
  );
}

  // ---------------------- INFO ROW ----------------------
  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text("$label:")),
          Expanded(
            flex: 5,
            child: Text(
              value?.toString() ?? '—',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
