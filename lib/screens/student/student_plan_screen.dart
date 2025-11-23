import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class StudentPlanScreen extends StatefulWidget {
  const StudentPlanScreen({super.key});

  @override
  State<StudentPlanScreen> createState() => _StudentPlanScreenState();
}

class _StudentPlanScreenState extends State<StudentPlanScreen> {
  List<dynamic> plans = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final res = await ApiService.getKeHoachList();
      setState(() {
        plans = res;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Lỗi load kế hoạch: $e');
      setState(() => isLoading = false);
    }
  }

  // ---- Format ngày dd/MM/yyyy ----
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FA),
      appBar: AppBar(
        title: const Text('Kế hoạch khóa luận', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlans,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : plans.isEmpty
              ? const Center(
                  child: Text("Hiện chưa có kế hoạch nào.",
                      style: TextStyle(fontSize: 16, color: Colors.black54)),
                )
              : RefreshIndicator(
                  onRefresh: _loadPlans,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: plans.length,
                    itemBuilder: (context, index) =>
                        _buildPlanCard(context, plans[index]),
                  ),
                ),
    );
  }

  Widget _buildPlanCard(BuildContext context, Map<String, dynamic> plan) {
    final title = plan['TEN_DOT'] ?? 'Không rõ tên đợt';
    final start = _formatDate(plan['NGAY_BATDAU']);
    final end = _formatDate(plan['NGAY_KETHUC']);
    final status = plan['TRANGTHAI'] ?? 'Chưa xác định';
    final khoaHoc = plan['KHOAHOC'] ?? '—';

    Color statusColor = Colors.orange;
    if (status.toLowerCase().contains("thực hiện")) statusColor = Colors.green;
    if (status.toLowerCase().contains("kết thúc")) statusColor = Colors.blueGrey;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentPlanDetailScreen(plan: plan),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_today,
                        color: Colors.deepPurple),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.deepPurple, size: 18),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    "$start → $end",
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                "Trạng thái: $status",
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 6),

              Text("Khóa học: $khoaHoc",
                  style: const TextStyle(color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }
}

class StudentPlanDetailScreen extends StatelessWidget {
  final Map<String, dynamic> plan;
  const StudentPlanDetailScreen({super.key, required this.plan});

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
    final title = plan['TEN_DOT'] ?? 'Chi tiết kế hoạch';
    final start = _formatDate(plan['NGAY_BATDAU']);
    final end = _formatDate(plan['NGAY_KETHUC']);
    final status = plan['TRANGTHAI'] ?? 'Không rõ';
    final khoaHoc = plan['KHOAHOC'] ?? '';
    final heDaoTao = plan['HEDAOTAO'] ?? '';
    final soTuan = plan['SO_TUAN_THUCHIEN']?.toString() ?? '-';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FA),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailTile(Icons.access_time, "Thời gian", "$start → $end"),
            _buildDetailTile(Icons.timeline, "Số tuần thực hiện", soTuan),
            _buildDetailTile(Icons.school, "Khóa học", khoaHoc),
            _buildDetailTile(Icons.book, "Hệ đào tạo", heDaoTao),
            _buildDetailTile(Icons.info, "Trạng thái", status),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.08),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w400)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
